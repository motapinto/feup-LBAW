<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ContactController extends Controller
{
    public function show()
    {
        return view('pages.static.contact', ['breadcrumbs' => ['Contact Us' => route("contact")]]);
    }
}
