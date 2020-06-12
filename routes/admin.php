<?php

use Illuminate\Support\Facades\Route;

// Admin
Route::get('/admin/login', 'Auth\LoginController@showLoginForm')->name('login_page_admin');
Route::post('/admin/login', 'Auth\LoginController@login')->name('loginAdmin');
Route::post('/admin/logout', 'Auth\LoginController@logout')->name('logoutAdmin');

Route::get('/admin', 'AdminController@show')->name('admin_homepage');

Route::get('/admin/products', 'AdminController@productShow');
Route::get('/admin/product', 'AdminController@productAddForm');
Route::put('/admin/product', 'AdminController@productAdd')->name('product_add');
Route::get('/admin/product/{id}', 'AdminController@productUpdateView')->where('id', '[0-9]+');
Route::delete('/admin/product/{id}', 'AdminController@productDelete')->where('id', '[0-9]+');
Route::post('/admin/product/{id}', 'AdminController@productUpdate')->where('id', '[0-9]+');

Route::get('/admin/category', 'AdminController@categoryShow');
Route::put('/admin/category', 'AdminController@categoryAdd');
Route::post('/admin/category/{id}', 'AdminController@categoryUpdate');
Route::delete('/admin/category/{id}', 'AdminController@categoryDelete');

Route::get('/admin/genre', 'AdminController@genreShow');
Route::put('/admin/genre', 'AdminController@genreAdd');
Route::post('/admin/genre/{id}', 'AdminController@genreUpdate');
Route::delete('/admin/genre/{id}', 'AdminController@genreDelete');

Route::get('/admin/platform', 'AdminController@platformShow');
Route::put('/admin/platform', 'AdminController@platformAdd');
Route::post('/admin/platform/{id}', 'AdminController@platformUpdate');
Route::delete('/admin/platform/{id}', 'AdminController@platformDelete');

Route::get('/admin/user', 'AdminController@userShow');
Route::post('/admin/user/{id}', 'AdminController@userUpdate')->name('userAdminUpdate');

Route::get('/admin/report', 'AdminController@allReports');
Route::get('/admin/report/{reportId}', 'AdminController@reportShow');
Route::post('/admin/report/{reportId}', 'AdminController@reportUpdate')->name('reportUpdate');
Route::put('/admin/report/{reportId}', 'AdminController@reportMessage');

Route::get('/admin/transaction', 'AdminController@transactionShow');

Route::get('/admin/feedback', 'AdminController@feedbackShow');
Route::delete('/admin/feedback/{feedbackId}', 'AdminController@feedbackDelete')->name('feedbackDelete');

Route::get('/admin/faq', 'AdminController@faqShow')->name('faqShow');
Route::put('/admin/faq', 'AdminController@faqAdd')->name('faqAdd');
Route::post('/admin/faq/{faqId}', 'AdminController@faqUpdate')->name('faqUpdate');
Route::delete('/admin/faq/{faqId}', 'AdminController@faqDelete')->name('faqDelete');

Route::get('/admin/appeal', 'AdminController@appealShow')->name('appealShow');
