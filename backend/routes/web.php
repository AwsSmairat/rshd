<?php

use App\Http\Controllers\HealthController;
use App\Http\Controllers\InstructorSetPasswordController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class)->name('health');

Route::view("/", "welcome")->name("home");

Route::get('/set-password', [InstructorSetPasswordController::class, 'show'])->name('instructor.set-password.show');
Route::post('/set-password', [InstructorSetPasswordController::class, 'store'])->name('instructor.set-password.store');
