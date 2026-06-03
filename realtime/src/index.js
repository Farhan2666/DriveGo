require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const axios = require('axios');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingInterval: 10000,
  pingTimeout: 5000,
});

const JWT_SECRET = process.env.JWT_SECRET || 'drivego-secret-key';
const LARAVEL_API = process.env.LARAVEL_API_URL || 'http://localhost:8000/api';

// Store active connections
const onlineUsers = new Map(); // userId -> Set<socketId>
const driverLocations = new Map(); // driverId -> { lat, lng, heading, speed, updatedAt }
const driverBookings = new Map(); // driverId -> activeBookingId

// =============================================
// MIDDLEWARE - Auth
// =============================================
io.use((socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;

  if (!token) {
    return next(new Error('Authentication required'));
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    socket.userId = decoded.sub || decoded.id;
    socket.userRole = decoded.role || 'customer';
    socket.userName = decoded.fullname || 'User';
    next();
  } catch (err) {
    return next(new Error('Invalid token'));
  }
});

// =============================================
// SOCKET CONNECTION
// =============================================
io.on('connection', (socket) => {
  const userId = socket.userId;
  const role = socket.userRole;

  console.log(`[+] User connected: ${userId} (${role}) - ${socket.id}`);

  // Track online user
  if (!onlineUsers.has(userId)) {
    onlineUsers.set(userId, new Set());
  }
  onlineUsers.get(userId).add(socket.id);

  // Join personal room
  socket.join(`user:${userId}`);
  socket.join(`role:${role}`);

  // =============================================
  // DRIVER LOCATION TRACKING
  // =============================================
  socket.on('driver:location:update', (data) => {
    if (role !== 'driver') return;

    const driverId = data.driver_id || userId;
    const location = {
      lat: data.lat,
      lng: data.lng,
      heading: data.heading || 0,
      speed: data.speed || 0,
      updatedAt: new Date().toISOString(),
    };

    driverLocations.set(driverId, location);

    // Broadcast to customer watching this booking
    const bookingId = driverBookings.get(driverId);
    if (bookingId) {
      io.to(`booking:${bookingId}`).emit('driver:location', {
        driver_id: driverId,
        ...location,
      });
    }

    // Broadcast to admin monitoring
    io.to('role:admin').emit('driver:location', {
      driver_id: driverId,
      ...location,
    });
  });

  // =============================================
  // BOOKING TRACKING
  // =============================================
  socket.on('booking:watch', (bookingId) => {
    socket.join(`booking:${bookingId}`);
    console.log(`[+] User ${userId} watching booking ${bookingId}`);
  });

  socket.on('booking:unwatch', (bookingId) => {
    socket.leave(`booking:${bookingId}`);
  });

  socket.on('booking:accept', (data) => {
    const { booking_id, driver_id } = data;
    driverBookings.set(driver_id || userId, booking_id);
    io.to(`booking:${booking_id}`).emit('booking:driver_accepted', {
      booking_id,
      driver_id: driver_id || userId,
      message: 'Driver telah menerima pesanan',
    });
  });

  socket.on('booking:status:update', (data) => {
    const { booking_id, status, ...extra } = data;
    io.to(`booking:${booking_id}`).emit('booking:status:changed', {
      booking_id,
      status,
      ...extra,
    });
  });

  // =============================================
  // CHAT / MESSAGES
  // =============================================
  socket.on('chat:send', (data) => {
    const { receiver_id, message, booking_id, message_type } = data;

    const payload = {
      sender_id: userId,
      sender_name: socket.userName,
      message,
      booking_id,
      message_type: message_type || 'text',
      created_at: new Date().toISOString(),
    };

    // Send to receiver's room
    io.to(`user:${receiver_id}`).emit('chat:new_message', payload);

    // If booking-specific, send to booking room too
    if (booking_id) {
      io.to(`booking:${booking_id}`).emit('chat:new_message', payload);
    }
  });

  socket.on('chat:typing', (data) => {
    const { receiver_id, booking_id, is_typing } = data;
    io.to(`user:${receiver_id}`).emit('chat:typing', {
      sender_id: userId,
      sender_name: socket.userName,
      booking_id,
      is_typing,
    });
  });

  socket.on('chat:read', (data) => {
    const { sender_id, booking_id } = data;
    io.to(`user:${sender_id}`).emit('chat:read_receipt', {
      read_by: userId,
      booking_id,
      read_at: new Date().toISOString(),
    });
  });

  // =============================================
  // NOTIFICATIONS
  // =============================================
  socket.on('notification:send', (data) => {
    const { user_id, title, content, type, reference_type, reference_id } = data;
    io.to(`user:${user_id}`).emit('notification:new', {
      title,
      content,
      type: type || 'system',
      reference_type,
      reference_id,
      created_at: new Date().toISOString(),
    });
  });

  // =============================================
  // EMERGENCY SOS
  // =============================================
  socket.on('emergency:sos', (data) => {
    const { lat, lng, booking_id } = data;

    const sosPayload = {
      user_id: userId,
      user_name: socket.userName,
      lat,
      lng,
      booking_id,
      created_at: new Date().toISOString(),
    };

    // Notify all admins
    io.to('role:admin').emit('emergency:sos:new', sosPayload);

    // If booking active, notify driver
    if (booking_id) {
      io.to(`booking:${booking_id}`).emit('emergency:sos:new', sosPayload);
    }
  });

  // =============================================
  // DISCONNECT
  // =============================================
  socket.on('disconnect', () => {
    console.log(`[-] User disconnected: ${userId} - ${socket.id}`);

    const userSockets = onlineUsers.get(userId);
    if (userSockets) {
      userSockets.delete(socket.id);
      if (userSockets.size === 0) {
        onlineUsers.delete(userId);
        io.to('role:admin').emit('user:offline', { user_id: userId, role });
      }
    }
  });
});

// =============================================
// REST ENDPOINTS (internal Laravel calls)
// =============================================
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    connections: io.engine.clientsCount,
    online_users: onlineUsers.size,
  });
});

// Broadcast from Laravel
app.post('/broadcast', (req, res) => {
  const { user_id, event, room, data } = req.body;

  if (room) {
    io.to(room).emit(event, data);
  } else if (user_id) {
    io.to(`user:${user_id}`).emit(event, data);
  } else {
    io.emit(event, data);
  }

  res.json({ success: true });
});

// Send notification to user
app.post('/notify', (req, res) => {
  const { user_id, title, body, data } = req.body;

  io.to(`user:${user_id}`).emit('notification:new', {
    title,
    content: body,
    ...data,
    created_at: new Date().toISOString(),
  });

  res.json({ success: true });
});

// Get online status
app.get('/users/:id/status', (req, res) => {
  const isOnline = onlineUsers.has(parseInt(req.params.id));
  res.json({ user_id: parseInt(req.params.id), online: isOnline });
});

// Get driver location
app.get('/drivers/:id/location', (req, res) => {
  const location = driverLocations.get(parseInt(req.params.id));
  if (!location) {
    return res.json({ success: false, message: 'Driver offline atau lokasi tidak tersedia' });
  }
  res.json({ success: true, data: location });
});

// =============================================
// START SERVER
// =============================================
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`[DriveGo Realtime] Running on port ${PORT}`);
  console.log(`[DriveGo Realtime] WebSocket server ready`);
});
