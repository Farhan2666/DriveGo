-- =============================================
-- DriveGo PostgreSQL Schema (Supabase)
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- ENUMS
-- =============================================
CREATE TABLE enums (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    value VARCHAR(50) NOT NULL,
    label VARCHAR(100) NOT NULL,
    sort_order SMALLINT DEFAULT 0,
    UNIQUE (category, value)
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
    id BIGSERIAL PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255),
    role VARCHAR(20) NOT NULL DEFAULT 'customer',
    avatar_url VARCHAR(500),
    fcm_token VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);

-- =============================================
-- OTP CODES
-- =============================================
CREATE TABLE otp_codes (
    id BIGSERIAL PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(30) NOT NULL DEFAULT 'login',
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_otp_phone_purpose ON otp_codes(phone, purpose);
CREATE INDEX idx_otp_expires ON otp_codes(expires_at);

-- =============================================
-- DRIVERS
-- =============================================
CREATE TABLE drivers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    rating DECIMAL(2,1) NOT NULL DEFAULT 0.0,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    total_orders INTEGER NOT NULL DEFAULT 0,
    total_earnings DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    availability_status VARCHAR(20) NOT NULL DEFAULT 'offline',
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    premium_expires_at TIMESTAMPTZ,
    bio TEXT,
    lat DECIMAL(10,8),
    lng DECIMAL(11,8),
    last_location_updated TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_drivers_verified ON drivers(is_verified);
CREATE INDEX idx_drivers_availability ON drivers(availability_status);
CREATE INDEX idx_drivers_rating ON drivers(rating);
CREATE INDEX idx_drivers_location ON drivers(lat, lng);
CREATE INDEX idx_drivers_search ON drivers(is_verified, availability_status, rating);

-- =============================================
-- VEHICLES
-- =============================================
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    plate_number VARCHAR(20) NOT NULL UNIQUE,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacity SMALLINT NOT NULL,
    photo_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_vehicles_driver ON vehicles(driver_id);
CREATE INDEX idx_vehicles_active ON vehicles(is_active);

-- =============================================
-- BOOKINGS
-- =============================================
CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    booking_code VARCHAR(20) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id BIGINT REFERENCES drivers(id) ON DELETE SET NULL,
    vehicle_id BIGINT REFERENCES vehicles(id) ON DELETE SET NULL,
    pickup_location TEXT NOT NULL,
    pickup_lat DECIMAL(10,8) NOT NULL,
    pickup_lng DECIMAL(11,8) NOT NULL,
    destination TEXT NOT NULL,
    dest_lat DECIMAL(10,8) NOT NULL,
    dest_lng DECIMAL(11,8) NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    total_distance_km DECIMAL(8,2),
    estimated_duration_min INTEGER,
    base_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    distance_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    service_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    commission_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    voucher_discount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(15,2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'waiting_payment',
    cancellation_reason TEXT,
    cancelled_by VARCHAR(10),
    cancelled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    driver_rating SMALLINT,
    customer_review TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_driver ON bookings(driver_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_date ON bookings(booking_date);
CREATE INDEX idx_bookings_driver_status ON bookings(driver_id, status);
CREATE INDEX idx_bookings_date_status ON bookings(booking_date, status);

-- =============================================
-- PAYMENTS
-- =============================================
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    external_id VARCHAR(100) UNIQUE,
    transaction_id VARCHAR(100) UNIQUE,
    payment_channel VARCHAR(50),
    payer_email VARCHAR(100),
    payer_phone VARCHAR(20),
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_payments_callback ON payments(external_id, transaction_id);

-- =============================================
-- REVIEWS
-- =============================================
CREATE TABLE reviews (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_reviews_driver ON reviews(driver_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- =============================================
-- MESSAGES
-- =============================================
CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT REFERENCES bookings(id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(10) NOT NULL DEFAULT 'text',
    attachment_url VARCHAR(500),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_messages_booking ON messages(booking_id);
CREATE INDEX idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX idx_messages_read ON messages(is_read);

-- =============================================
-- NOTIFICATIONS
-- =============================================
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    notification_type VARCHAR(20) NOT NULL DEFAULT 'system',
    reference_type VARCHAR(50),
    reference_id BIGINT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(notification_type);

-- =============================================
-- VOUCHERS
-- =============================================
CREATE TABLE vouchers (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    voucher_type VARCHAR(20) NOT NULL DEFAULT 'discount',
    discount_type VARCHAR(20) NOT NULL DEFAULT 'percentage',
    discount_value DECIMAL(15,2) NOT NULL,
    min_order DECIMAL(15,2) NOT NULL DEFAULT 0,
    max_discount DECIMAL(15,2),
    quota INTEGER NOT NULL DEFAULT 0,
    used_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vouchers_active ON vouchers(is_active);
CREATE INDEX idx_vouchers_period ON vouchers(starts_at, ends_at);

-- =============================================
-- USER VOUCHERS
-- =============================================
CREATE TABLE user_vouchers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    voucher_id BIGINT NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    booking_id BIGINT REFERENCES bookings(id) ON DELETE SET NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, voucher_id)
);

-- =============================================
-- WALLETS
-- =============================================
CREATE TABLE wallets (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL UNIQUE REFERENCES drivers(id) ON DELETE CASCADE,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    pending_balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    lifetime_earnings DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- WALLET TRANSACTIONS
-- =============================================
CREATE TABLE wallet_transactions (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    booking_id BIGINT REFERENCES bookings(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_wallet_tx_wallet ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_tx_type ON wallet_transactions(type);

-- =============================================
-- WITHDRAWALS
-- =============================================
CREATE TABLE withdrawals (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    amount DECIMAL(15,2) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_account_number VARCHAR(50) NOT NULL,
    bank_account_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    admin_note TEXT,
    processed_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_withdrawals_wallet ON withdrawals(wallet_id);
CREATE INDEX idx_withdrawals_driver ON withdrawals(driver_id);
CREATE INDEX idx_withdrawals_status ON withdrawals(status);

-- =============================================
-- DRIVER DOCUMENTS
-- =============================================
CREATE TABLE driver_documents (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    document_type VARCHAR(20) NOT NULL,
    document_url VARCHAR(500) NOT NULL,
    document_number VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_doc_driver ON driver_documents(driver_id);
CREATE INDEX idx_doc_type ON driver_documents(document_type);
CREATE INDEX idx_doc_status ON driver_documents(status);

-- =============================================
-- FAVORITE DRIVERS
-- =============================================
CREATE TABLE favorite_drivers (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (customer_id, driver_id)
);

-- =============================================
-- TRIP TRACKING
-- =============================================
CREATE TABLE trip_tracking (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    lat DECIMAL(10,8) NOT NULL,
    lng DECIMAL(11,8) NOT NULL,
    speed DECIMAL(5,2),
    heading DECIMAL(5,2),
    accuracy DECIMAL(5,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_tracking_booking ON trip_tracking(booking_id);
CREATE INDEX idx_tracking_driver ON trip_tracking(driver_id);
CREATE INDEX idx_tracking_time ON trip_tracking(recorded_at);

-- =============================================
-- AUDIT LOGS
-- =============================================
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_time ON audit_logs(created_at);

-- =============================================
-- EMERGENCY SOS
-- =============================================
CREATE TABLE emergency_sos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_id BIGINT REFERENCES bookings(id) ON DELETE SET NULL,
    lat DECIMAL(10,8) NOT NULL,
    lng DECIMAL(11,8) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sos_user ON emergency_sos(user_id);
CREATE INDEX idx_sos_status ON emergency_sos(status);

-- =============================================
-- DRIVER SUBSCRIPTIONS
-- =============================================
CREATE TABLE driver_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    subscription_type VARCHAR(20) NOT NULL DEFAULT 'monthly',
    amount DECIMAL(10,2) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    payment_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_driver ON driver_subscriptions(driver_id);
CREATE INDEX idx_subscriptions_active ON driver_subscriptions(is_active);

-- =============================================
-- AUTO UPDATE TRIGGER
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_drivers_updated_at BEFORE UPDATE ON drivers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_vouchers_updated_at BEFORE UPDATE ON vouchers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_wallets_updated_at BEFORE UPDATE ON wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_withdrawals_updated_at BEFORE UPDATE ON withdrawals FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_driver_documents_updated_at BEFORE UPDATE ON driver_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_driver_subscriptions_updated_at BEFORE UPDATE ON driver_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
