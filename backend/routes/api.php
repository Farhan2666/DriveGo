<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| DriveGo API Routes
|--------------------------------------------------------------------------
*/

// =============================================
// PUBLIC ROUTES
// =============================================
Route::post('/auth/register', [App\Http\Controllers\Api\AuthController::class, 'register']);
Route::post('/auth/login', [App\Http\Controllers\Api\AuthController::class, 'loginPassword']);
Route::post('/auth/login/otp', [App\Http\Controllers\Api\AuthController::class, 'loginOtp']);
Route::post('/auth/otp/send', [App\Http\Controllers\Api\AuthController::class, 'sendOtp']);

Route::get('/drivers', [App\Http\Controllers\Api\DriverController::class, 'index']);
Route::get('/drivers/search', [App\Http\Controllers\Api\DriverController::class, 'search']);
Route::get('/drivers/{id}', [App\Http\Controllers\Api\DriverController::class, 'show']);

Route::get('/vehicles', [App\Http\Controllers\Api\VehicleController::class, 'index']);
Route::get('/vehicles/{id}', [App\Http\Controllers\Api\VehicleController::class, 'show']);

Route::get('/reviews', [App\Http\Controllers\Api\ReviewController::class, 'index']);

Route::get('/vouchers', [App\Http\Controllers\Api\VoucherController::class, 'index']);
Route::post('/vouchers/validate', [App\Http\Controllers\Api\VoucherController::class, 'validate']);

Route::post('/maps/geocode', [App\Http\Controllers\Api\MapController::class, 'geocode']);
Route::post('/maps/distance', [App\Http\Controllers\Api\MapController::class, 'distance']);
Route::get('/maps/autocomplete', [App\Http\Controllers\Api\MapController::class, 'autocomplete']);

// Payment callback (from Midtrans/Duitku)
Route::post('/payments/callback', [App\Http\Controllers\Api\PaymentController::class, 'callback']);

// =============================================
// AUTHENTICATED ROUTES
// =============================================
Route::middleware(['auth:api', 'throttle:60,1'])->group(function () {

    // Auth
    Route::post('/auth/logout', [App\Http\Controllers\Api\AuthController::class, 'logout']);
    Route::get('/auth/me', [App\Http\Controllers\Api\AuthController::class, 'me']);
    Route::post('/auth/refresh', [App\Http\Controllers\Api\AuthController::class, 'refreshToken']);
    Route::post('/auth/fcm-token', [App\Http\Controllers\Api\AuthController::class, 'updateFcmToken']);
    Route::put('/auth/profile', [App\Http\Controllers\Api\AuthController::class, 'updateProfile']);

    // Bookings
    Route::post('/bookings', [App\Http\Controllers\Api\BookingController::class, 'store']);
    Route::get('/bookings', [App\Http\Controllers\Api\BookingController::class, 'index']);
    Route::get('/bookings/{id}', [App\Http\Controllers\Api\BookingController::class, 'show']);
    Route::put('/bookings/{id}', [App\Http\Controllers\Api\BookingController::class, 'update']);
    Route::post('/bookings/calculate-price', [App\Http\Controllers\Api\BookingController::class, 'calculatePrice']);
    Route::get('/bookings/history', [App\Http\Controllers\Api\BookingController::class, 'history']);

    // Payments
    Route::post('/payments/{bookingId}/pay', [App\Http\Controllers\Api\PaymentController::class, 'pay']);
    Route::get('/payments/history', [App\Http\Controllers\Api\PaymentController::class, 'history']);

    // Reviews
    Route::post('/reviews', [App\Http\Controllers\Api\ReviewController::class, 'store']);
    Route::get('/reviews/{id}', [App\Http\Controllers\Api\ReviewController::class, 'show']);

    // Messages
    Route::get('/messages', [App\Http\Controllers\Api\MessageController::class, 'index']);
    Route::post('/messages', [App\Http\Controllers\Api\MessageController::class, 'store']);
    Route::get('/messages/conversations', [App\Http\Controllers\Api\MessageController::class, 'conversations']);

    // Notifications
    Route::get('/notifications', [App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    Route::get('/notifications/unread-count', [App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);

    // Favorites
    Route::post('/drivers/{id}/favorite', [App\Http\Controllers\Api\DriverController::class, 'toggleFavorite']);
    Route::get('/favorites', [App\Http\Controllers\Api\DriverController::class, 'favorites']);

    // Emergency
    Route::post('/emergency/sos', [App\Http\Controllers\Api\EmergencyController::class, 'sos']);

    // =============================================
    // DRIVER ONLY ROUTES
    // =============================================
    Route::middleware(['role:driver', 'driver'])->prefix('driver')->group(function () {
        Route::put('/availability', [App\Http\Controllers\Api\DriverController::class, 'updateAvailability']);
        Route::post('/location', [App\Http\Controllers\Api\DriverController::class, 'updateLocation']);
        Route::get('/statistics', [App\Http\Controllers\Api\DriverController::class, 'statistics']);

        Route::get('/vehicles', [App\Http\Controllers\Api\VehicleController::class, 'index']);
        Route::post('/vehicles', [App\Http\Controllers\Api\VehicleController::class, 'store']);
        Route::put('/vehicles/{id}', [App\Http\Controllers\Api\VehicleController::class, 'update']);
        Route::delete('/vehicles/{id}', [App\Http\Controllers\Api\VehicleController::class, 'destroy']);

        Route::get('/documents', [App\Http\Controllers\Api\DriverDocumentController::class, 'index']);
        Route::post('/documents', [App\Http\Controllers\Api\DriverDocumentController::class, 'store']);
        Route::delete('/documents/{id}', [App\Http\Controllers\Api\DriverDocumentController::class, 'destroy']);

        Route::get('/wallet', [App\Http\Controllers\Api\WalletController::class, 'show']);
        Route::post('/wallet/withdraw', [App\Http\Controllers\Api\WalletController::class, 'withdraw']);
        Route::get('/wallet/withdrawals', [App\Http\Controllers\Api\WalletController::class, 'withdrawalHistory']);
        Route::get('/wallet/earnings', [App\Http\Controllers\Api\WalletController::class, 'earningsHistory']);
    });

    // =============================================
    // ADMIN ONLY ROUTES
    // =============================================
    Route::middleware(['role:admin'])->prefix('admin')->group(function () {
        Route::get('/dashboard', [App\Http\Controllers\Api\Admin\AdminDashboardController::class, 'index']);

        Route::get('/users/customers', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'customers']);
        Route::get('/users/drivers', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'drivers']);
        Route::get('/users/drivers/{id}', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'showDriver']);
        Route::post('/users/drivers/{id}/approve', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'approveDriver']);
        Route::post('/users/drivers/{id}/reject', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'rejectDriver']);
        Route::post('/users/drivers/{id}/ban', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'banDriver']);
        Route::post('/users/drivers/{id}/unban', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'unbanDriver']);
        Route::post('/users/{id}/suspend', [App\Http\Controllers\Api\Admin\AdminUserController::class, 'suspendUser']);

        Route::get('/finance/transactions', [App\Http\Controllers\Api\Admin\AdminFinanceController::class, 'transactions']);
        Route::get('/finance/withdrawals', [App\Http\Controllers\Api\Admin\AdminFinanceController::class, 'withdrawals']);
        Route::post('/finance/withdrawals/{id}/approve', [App\Http\Controllers\Api\Admin\AdminFinanceController::class, 'approveWithdrawal']);
        Route::post('/finance/withdrawals/{id}/reject', [App\Http\Controllers\Api\Admin\AdminFinanceController::class, 'rejectWithdrawal']);
        Route::get('/finance/reports', [App\Http\Controllers\Api\Admin\AdminFinanceController::class, 'reports']);

        Route::get('/emergency', [App\Http\Controllers\Api\EmergencyController::class, 'active']);
        Route::post('/emergency/{id}/resolve', [App\Http\Controllers\Api\EmergencyController::class, 'resolve']);
    });

    // SOS resolve (user)
    Route::post('/emergency/{id}/resolve', [App\Http\Controllers\Api\EmergencyController::class, 'resolve']);
});
