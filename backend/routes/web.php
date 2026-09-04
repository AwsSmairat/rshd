<?php

use App\Http\Controllers\FilamentLocaleController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\InstructorSetPasswordController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class)->name('health');

Route::get('/', function () {
    return redirect('/admin');
});

Route::get('/locale/{locale}', FilamentLocaleController::class)
    ->where('locale', 'ar|en')
    ->name('auth.locale');

Route::get('/set-password', [InstructorSetPasswordController::class, 'show'])->name('instructor.set-password.show');
Route::post('/set-password', [InstructorSetPasswordController::class, 'store'])->name('instructor.set-password.store');
