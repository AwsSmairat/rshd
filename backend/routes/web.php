<?php

use App\Http\Controllers\HealthController;
use App\Http\Controllers\InstructorSetPasswordController;
use App\Http\Controllers\PublicLegalController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class)->name('health');

Route::view('/', 'welcome')->name('home');

Route::get('/privacy-policy', [PublicLegalController::class, 'privacy'])->name('legal.privacy');
Route::get('/terms', [PublicLegalController::class, 'terms'])->name('legal.terms');
Route::get('/account-deletion', [PublicLegalController::class, 'accountDeletion'])->name('legal.account-deletion');

Route::get('/set-password', [InstructorSetPasswordController::class, 'show'])->name('instructor.set-password.show');
Route::post('/set-password', [InstructorSetPasswordController::class, 'store'])->name('instructor.set-password.store');
