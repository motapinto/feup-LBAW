<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Genre extends Model
{
    // Don't add create and update timestamps in database.
    public $timestamps  = false;
}
