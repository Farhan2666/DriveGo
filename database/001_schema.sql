-- =============================================
-- DriveGo Database Schema v1.0
-- =============================================

CREATE DATABASE IF NOT EXISTS drivego CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE drivego;

-- =============================================
-- ENUMS
-- =============================================
CREATE TABLE enums (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    value VARCHAR(50) NOT NULL,
    label VARCHAR(100) NOT NULL,
    sort_order SMALLINT UNSIGNED DEFAULT 0,
    UNIQUE KEY uk_enum (category, value)
);

INSERT INTO enums (category, value, label, sort_order) VALUES
('user_role', 'customer', 'Customer', 1),
('user_role', 'driver', 'Driver', 2),
('user_role', 'admin', 'Admin', 3),
('booking_status', 'waiting_payment', 'Menunggu Pembayaran', 1),
('booking_status', 'paid', 'Dibayar', 2),
('booking_status', 'driver_confirmed', 'Driver Dikonfirmasi', 3),
('booking_status', 'driver_on_the_way', 'Driver Menuju Lokasi', 4),
('booking_status', 'customer_picked_up', 'Penumpang Dijemput', 5),
('booking_status', 'trip_started', 'Perjalanan Dimulai', 6),
('booking_status', 'trip_completed', 'Perjalanan Selesai', 7),
('booking_status', 'cancelled', 'Dibatalkan', 8),
('booking_status', 'refund', 'Refund', 9),
('payment_method', 'qris', 'QRIS', 1),
('payment_method', 'ovo', 'OVO', 2),
('payment_method', 'dana', 'DANA', 3),
('payment_method', 'gopay', 'GoPay', 4),
('payment_method', 'transfer_bank', 'Transfer Bank', 5),
('payment_status', 'pending', 'Pending', 1),
('payment_status', 'success', 'Sukses', 2),
('payment_status', 'failed', 'Gagal', 3),
('payment_status', 'refunded', 'Refund', 4),
('driver_availability', 'online', 'Online', 1),
('driver_availability', 'offline', 'Offline', 2),
('driver_availability', 'available', 'Available', 3),
('driver_availability', 'busy', 'Sibuk', 4),
('document_status', 'pending', 'Menunggu Verifikasi', 1),
('document_status', 'verified', 'Terverifikasi', 2),
('document_status', 'rejected', 'Ditolak', 3),
('wallet_transaction_type', 'topup', 'Top Up', 1),
('wallet_transaction_type', 'withdrawal', 'Penarikan', 2),
('wallet_transaction_type', 'commission', 'Komisi', 3),
('wallet_transaction_type', 'service_fee', 'Biaya Layanan', 4),
('withdrawal_status', 'pending', 'Pending', 1),
('withdrawal_status', 'processed', 'Diproses', 2),
('withdrawal_status', 'completed', 'Selesai', 3),
('withdrawal_status', 'rejected', 'Ditolak', 4),
('notification_type', 'booking', 'Booking', 1),
('notification_type', 'payment', 'Pembayaran', 2),
('notification_type', 'promo', 'Promo', 3),
('notification_type', 'system', 'Sistem', 4),
('notification_type', 'emergency', 'Darurat', 5),
('voucher_type', 'discount', 'Diskon', 1),
('voucher_type', 'seasonal', 'Musiman', 2);

-- =============================================
-- USERS
-- =============================================
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) DEFAULT NULL,
    password_hash VARCHAR(255) DEFAULT NULL,
    role ENUM('customer','driver','admin') NOT NULL DEFAULT 'customer',
    avatar_url VARCHAR(500) DEFAULT NULL,
    fcm_token VARCHAR(500) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    last_login_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uk_phone (phone),
    UNIQUE KEY uk_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- OTP CODES
-- =============================================
CREATE TABLE otp_codes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose ENUM('login','register','forgot_password','change_phone') NOT NULL DEFAULT 'login',
    is_used TINYINT(1) NOT NULL DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone_purpose (phone, purpose),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- DRIVERS
-- =============================================
CREATE TABLE drivers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    rating DECIMAL(2,1) NOT NULL DEFAULT 0.0,
    total_reviews INT UNSIGNED NOT NULL DEFAULT 0,
    total_orders INT UNSIGNED NOT NULL DEFAULT 0,
    total_earnings DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    verification_status ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
    availability_status ENUM('online','offline','available','busy') NOT NULL DEFAULT 'offline',
    is_premium TINYINT(1) NOT NULL DEFAULT 0,
    premium_expires_at TIMESTAMP NULL DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    lat DECIMAL(10,8) DEFAULT NULL,
    lng DECIMAL(11,8) DEFAULT NULL,
    last_location_updated TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_is_verified (is_verified),
    INDEX idx_availability (availability_status),
    INDEX idx_rating (rating),
    INDEX idx_location (lat, lng),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- VEHICLES
-- =============================================
CREATE TABLE vehicles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT UNSIGNED NOT NULL,
    plate_number VARCHAR(20) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year YEAR NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacity TINYINT UNSIGNED NOT NULL,
    photo_url VARCHAR(500) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uk_plate_number (plate_number),
    INDEX idx_driver_id (driver_id),
    INDEX idx_is_active (is_active),
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- BOOKINGS
-- =============================================
CREATE TABLE bookings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(20) NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED DEFAULT NULL,
    vehicle_id BIGINT UNSIGNED DEFAULT NULL,
    pickup_location TEXT NOT NULL,
    pickup_lat DECIMAL(10,8) NOT NULL,
    pickup_lng DECIMAL(11,8) NOT NULL,
    destination TEXT NOT NULL,
    dest_lat DECIMAL(10,8) NOT NULL,
    dest_lng DECIMAL(11,8) NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    total_distance_km DECIMAL(8,2) DEFAULT NULL,
    estimated_duration_min INT UNSIGNED DEFAULT NULL,
    base_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    distance_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    service_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    commission_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    voucher_discount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(15,2) NOT NULL,
    status ENUM('waiting_payment','paid','driver_confirmed','driver_on_the_way','customer_picked_up','trip_started','trip_completed','cancelled','refund') NOT NULL DEFAULT 'waiting_payment',
    cancellation_reason TEXT DEFAULT NULL,
    cancelled_by ENUM('customer','driver','system') DEFAULT NULL,
    cancelled_at TIMESTAMP NULL DEFAULT NULL,
    started_at TIMESTAMP NULL DEFAULT NULL,
    completed_at TIMESTAMP NULL DEFAULT NULL,
    driver_rating TINYINT UNSIGNED DEFAULT NULL,
    customer_review TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_booking_code (booking_code),
    INDEX idx_customer_id (customer_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_booking_date (booking_date),
    INDEX idx_driver_status (driver_id, status),
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE SET NULL,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- PAYMENTS
-- =============================================
CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    payment_method ENUM('qris','ovo','dana','gopay','transfer_bank') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    status ENUM('pending','success','failed','refunded') NOT NULL DEFAULT 'pending',
    external_id VARCHAR(100) DEFAULT NULL,
    transaction_id VARCHAR(100) DEFAULT NULL,
    payment_channel VARCHAR(50) DEFAULT NULL,
    payer_email VARCHAR(100) DEFAULT NULL,
    payer_phone VARCHAR(20) DEFAULT NULL,
    paid_at TIMESTAMP NULL DEFAULT NULL,
    refunded_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_booking_id (booking_id),
    UNIQUE KEY uk_external_id (external_id),
    UNIQUE KEY uk_transaction_id (transaction_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- REVIEWS
-- =============================================
CREATE TABLE reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_booking_review (booking_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_rating (rating),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- MESSAGES
-- =============================================
CREATE TABLE messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED DEFAULT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    receiver_id BIGINT UNSIGNED NOT NULL,
    message TEXT NOT NULL,
    message_type ENUM('text','image','location','system') NOT NULL DEFAULT 'text',
    attachment_url VARCHAR(500) DEFAULT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    read_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_booking_id (booking_id),
    INDEX idx_sender_receiver (sender_id, receiver_id),
    INDEX idx_is_read (is_read),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- NOTIFICATIONS
-- =============================================
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    notification_type ENUM('booking','payment','promo','system','emergency') NOT NULL DEFAULT 'system',
    reference_type VARCHAR(50) DEFAULT NULL,
    reference_id BIGINT UNSIGNED DEFAULT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    read_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_type (notification_type),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- VOUCHERS
-- =============================================
CREATE TABLE vouchers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT DEFAULT NULL,
    voucher_type ENUM('discount','seasonal') NOT NULL DEFAULT 'discount',
    discount_type ENUM('percentage','nominal') NOT NULL DEFAULT 'percentage',
    discount_value DECIMAL(15,2) NOT NULL,
    min_order DECIMAL(15,2) NOT NULL DEFAULT 0,
    max_discount DECIMAL(15,2) DEFAULT NULL,
    quota INT UNSIGNED NOT NULL DEFAULT 0,
    used_count INT UNSIGNED NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_valid_period (starts_at, ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- USER VOUCHERS
-- =============================================
CREATE TABLE user_vouchers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NOT NULL,
    is_used TINYINT(1) NOT NULL DEFAULT 0,
    used_at TIMESTAMP NULL DEFAULT NULL,
    booking_id BIGINT UNSIGNED DEFAULT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_voucher (user_id, voucher_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- WALLETS
-- =============================================
CREATE TABLE wallets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT UNSIGNED NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    pending_balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    lifetime_earnings DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_driver_id (driver_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- WALLET TRANSACTIONS
-- =============================================
CREATE TABLE wallet_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    wallet_id BIGINT UNSIGNED NOT NULL,
    booking_id BIGINT UNSIGNED DEFAULT NULL,
    type ENUM('topup','withdrawal','commission','service_fee','adjustment') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_type (type),
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- WITHDRAWALS
-- =============================================
CREATE TABLE withdrawals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    wallet_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_account_number VARCHAR(50) NOT NULL,
    bank_account_name VARCHAR(100) NOT NULL,
    status ENUM('pending','processed','completed','rejected') NOT NULL DEFAULT 'pending',
    admin_note TEXT DEFAULT NULL,
    processed_by BIGINT UNSIGNED DEFAULT NULL,
    processed_at TIMESTAMP NULL DEFAULT NULL,
    completed_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- DRIVER DOCUMENTS
-- =============================================
CREATE TABLE driver_documents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT UNSIGNED NOT NULL,
    document_type ENUM('ktp','sim','stnk','vehicle_photo','selfie_ktp') NOT NULL,
    document_url VARCHAR(500) NOT NULL,
    document_number VARCHAR(100) DEFAULT NULL,
    status ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT DEFAULT NULL,
    verified_by BIGINT UNSIGNED DEFAULT NULL,
    verified_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_driver_id (driver_id),
    INDEX idx_document_type (document_type),
    INDEX idx_status (status),
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- FAVORITE DRIVERS
-- =============================================
CREATE TABLE favorite_drivers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_favorite (customer_id, driver_id),
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TRIP TRACKING
-- =============================================
CREATE TABLE trip_tracking (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    lat DECIMAL(10,8) NOT NULL,
    lng DECIMAL(11,8) NOT NULL,
    speed DECIMAL(5,2) DEFAULT NULL,
    heading DECIMAL(5,2) DEFAULT NULL,
    accuracy DECIMAL(5,2) DEFAULT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_booking_id (booking_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_recorded_at (recorded_at),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- AUDIT LOGS
-- =============================================
CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED DEFAULT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT UNSIGNED DEFAULT NULL,
    old_values JSON DEFAULT NULL,
    new_values JSON DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent VARCHAR(500) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- EMERGENCY SOS
-- =============================================
CREATE TABLE emergency_sos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    booking_id BIGINT UNSIGNED DEFAULT NULL,
    lat DECIMAL(10,8) NOT NULL,
    lng DECIMAL(11,8) NOT NULL,
    status ENUM('active','resolved','cancelled') NOT NULL DEFAULT 'active',
    resolved_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- DRIVER SUBSCRIPTIONS (PREMIUM)
-- =============================================
CREATE TABLE driver_subscriptions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT UNSIGNED NOT NULL,
    subscription_type ENUM('monthly','yearly') NOT NULL DEFAULT 'monthly',
    amount DECIMAL(10,2) NOT NULL,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    payment_id BIGINT UNSIGNED DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_driver_id (driver_id),
    INDEX idx_is_active (is_active),
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- INDEXES FOR SEARCH PERFORMANCE
-- =============================================
-- Drivers search
ALTER TABLE drivers ADD INDEX idx_search (is_verified, availability_status, rating);
-- Bookings by date range
ALTER TABLE bookings ADD INDEX idx_booking_date_status (booking_date, status);
-- Payments callback
ALTER TABLE payments ADD INDEX idx_callback (external_id, transaction_id);
