<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('fullname', 100);
            $table->string('phone', 20)->unique();
            $table->string('email', 100)->nullable()->unique();
            $table->string('password_hash', 255)->nullable();
            $table->string('role', 20)->default('customer');
            $table->string('avatar_url', 500)->nullable();
            $table->string('fcm_token', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->index('role');
            $table->index('is_active');
        });

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone', 20);
            $table->string('code', 6);
            $table->string('purpose', 30)->default('login');
            $table->boolean('is_used')->default(false);
            $table->timestamp('expires_at');
            $table->timestamp('created_at')->useCurrent();
            $table->index(['phone', 'purpose']);
            $table->index('expires_at');
        });

        Schema::create('drivers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->decimal('rating', 2, 1)->default(0.0);
            $table->unsignedInteger('total_reviews')->default(0);
            $table->unsignedInteger('total_orders')->default(0);
            $table->decimal('total_earnings', 15, 2)->default(0.00);
            $table->boolean('is_verified')->default(false);
            $table->string('verification_status', 20)->default('pending');
            $table->string('availability_status', 20)->default('offline');
            $table->boolean('is_premium')->default(false);
            $table->timestamp('premium_expires_at')->nullable();
            $table->text('bio')->nullable();
            $table->decimal('lat', 10, 8)->nullable();
            $table->decimal('lng', 11, 8)->nullable();
            $table->timestamp('last_location_updated')->nullable();
            $table->timestamps();
            $table->index('is_verified');
            $table->index('availability_status');
            $table->index('rating');
            $table->index(['lat', 'lng']);
            $table->index(['is_verified', 'availability_status', 'rating'], 'idx_search');
        });

        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->string('plate_number', 20)->unique();
            $table->string('brand', 50);
            $table->string('model', 100);
            $table->integer('year');
            $table->string('color', 30);
            $table->unsignedTinyInteger('capacity');
            $table->string('photo_url', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->index('driver_id');
            $table->index('is_active');
        });

        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->string('booking_code', 20)->unique();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('vehicle_id')->nullable()->constrained()->nullOnDelete();
            $table->text('pickup_location');
            $table->decimal('pickup_lat', 10, 8);
            $table->decimal('pickup_lng', 11, 8);
            $table->text('destination');
            $table->decimal('dest_lat', 10, 8);
            $table->decimal('dest_lng', 11, 8);
            $table->date('booking_date');
            $table->time('booking_time');
            $table->decimal('total_distance_km', 8, 2)->nullable();
            $table->unsignedInteger('estimated_duration_min')->nullable();
            $table->decimal('base_price', 15, 2)->default(0.00);
            $table->decimal('distance_price', 15, 2)->default(0.00);
            $table->decimal('service_fee', 10, 2)->default(0.00);
            $table->decimal('commission_amount', 10, 2)->default(0.00);
            $table->decimal('voucher_discount', 10, 2)->default(0.00);
            $table->decimal('total_price', 15, 2);
            $table->string('status', 30)->default('waiting_payment');
            $table->text('cancellation_reason')->nullable();
            $table->string('cancelled_by', 10)->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->unsignedTinyInteger('driver_rating')->nullable();
            $table->text('customer_review')->nullable();
            $table->timestamps();
            $table->index('customer_id');
            $table->index('driver_id');
            $table->index('status');
            $table->index('booking_date');
            $table->index(['driver_id', 'status']);
            $table->index(['booking_date', 'status'], 'idx_booking_date_status');
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('payment_method', 20);
            $table->decimal('amount', 15, 2);
            $table->string('status', 20)->default('pending');
            $table->string('external_id', 100)->nullable()->unique();
            $table->string('transaction_id', 100)->nullable()->unique();
            $table->string('payment_channel', 50)->nullable();
            $table->string('payer_email', 100)->nullable();
            $table->string('payer_phone', 20)->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('refunded_at')->nullable();
            $table->timestamps();
            $table->index(['external_id', 'transaction_id'], 'idx_callback');
        });

        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('driver_id');
            $table->index('rating');
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('receiver_id')->constrained('users')->cascadeOnDelete();
            $table->text('message');
            $table->string('message_type', 10)->default('text');
            $table->string('attachment_url', 500)->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('booking_id');
            $table->index(['sender_id', 'receiver_id']);
            $table->index('is_read');
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title', 200);
            $table->text('content');
            $table->string('notification_type', 20)->default('system');
            $table->string('reference_type', 50)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('user_id');
            $table->index('is_read');
            $table->index('notification_type');
        });

        Schema::create('vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('title', 200);
            $table->text('description')->nullable();
            $table->string('voucher_type', 20)->default('discount');
            $table->string('discount_type', 20)->default('percentage');
            $table->decimal('discount_value', 15, 2);
            $table->decimal('min_order', 15, 2)->default(0);
            $table->decimal('max_discount', 15, 2)->nullable();
            $table->unsignedInteger('quota')->default(0);
            $table->unsignedInteger('used_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->timestamps();
            $table->index('is_active');
            $table->index(['starts_at', 'ends_at']);
        });

        Schema::create('user_vouchers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('voucher_id')->constrained()->cascadeOnDelete();
            $table->boolean('is_used')->default(false);
            $table->timestamp('used_at')->nullable();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('assigned_at')->useCurrent();
            $table->unique(['user_id', 'voucher_id']);
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->unique()->constrained()->cascadeOnDelete();
            $table->decimal('balance', 15, 2)->default(0.00);
            $table->decimal('pending_balance', 15, 2)->default(0.00);
            $table->decimal('lifetime_earnings', 15, 2)->default(0.00);
            $table->timestamps();
        });

        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 20);
            $table->decimal('amount', 15, 2);
            $table->decimal('balance_before', 15, 2);
            $table->decimal('balance_after', 15, 2);
            $table->text('description')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('wallet_id');
            $table->index('type');
        });

        Schema::create('withdrawals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->string('bank_name', 100);
            $table->string('bank_account_number', 50);
            $table->string('bank_account_name', 100);
            $table->string('status', 20)->default('pending');
            $table->text('admin_note')->nullable();
            $table->foreignId('processed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            $table->index('wallet_id');
            $table->index('driver_id');
            $table->index('status');
        });

        Schema::create('driver_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->string('document_type', 20);
            $table->string('document_url', 500);
            $table->string('document_number', 100)->nullable();
            $table->string('status', 20)->default('pending');
            $table->text('rejection_reason')->nullable();
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
            $table->index('driver_id');
            $table->index('document_type');
            $table->index('status');
        });

        Schema::create('favorite_drivers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['customer_id', 'driver_id']);
        });

        Schema::create('trip_tracking', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->decimal('lat', 10, 8);
            $table->decimal('lng', 11, 8);
            $table->decimal('speed', 5, 2)->nullable();
            $table->decimal('heading', 5, 2)->nullable();
            $table->decimal('accuracy', 5, 2)->nullable();
            $table->timestamp('recorded_at')->useCurrent();
            $table->index('booking_id');
            $table->index('driver_id');
            $table->index('recorded_at');
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action', 100);
            $table->string('entity_type', 50);
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('user_id');
            $table->index('action');
            $table->index(['entity_type', 'entity_id']);
            $table->index('created_at');
        });

        Schema::create('emergency_sos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('lat', 10, 8);
            $table->decimal('lng', 11, 8);
            $table->string('status', 20)->default('active');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('user_id');
            $table->index('status');
        });

        Schema::create('driver_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->string('subscription_type', 20)->default('monthly');
            $table->decimal('amount', 10, 2);
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('payment_id')->nullable();
            $table->timestamps();
            $table->index('driver_id');
            $table->index('is_active');
        });

        Schema::create('enums', function (Blueprint $table) {
            $table->tinyIncrements('id');
            $table->string('category', 50);
            $table->string('value', 50);
            $table->string('label', 100);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->unique(['category', 'value']);
        });
    }

    public function down(): void
    {
        $tables = [
            'enums', 'driver_subscriptions', 'emergency_sos', 'audit_logs',
            'trip_tracking', 'favorite_drivers', 'driver_documents',
            'withdrawals', 'wallet_transactions', 'wallets', 'user_vouchers',
            'vouchers', 'notifications', 'messages', 'reviews', 'payments',
            'bookings', 'vehicles', 'drivers', 'otp_codes', 'users',
        ];
        foreach ($tables as $table) {
            Schema::dropIfExists($table);
        }
    }
};
