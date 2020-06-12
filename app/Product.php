<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{

    // Don't add create and update timestamps in database.
    public $timestamps  = false;

    /**
     * The picture this product has
     */
    public function picture() {
        return $this->belongsTo('App\Picture');
    }

    /**
     * The category this product has
     */
    public function category() {
        return $this->belongsTo('App\Category');
    }

    /**
     * The platforms this product is associated with
     */
    public function platforms() {
        return $this->belongsToMany('App\Platform', 'product_has_platforms', 'product_id', 'platform_id');
    }

    /**
     * The genres this product is associated with
     */
    public function genres() {
        return $this->belongsToMany('App\Genre', 'product_has_genres', 'product_id', 'genre_id');
    }

    /**
     * The offers this product has
     */
    public function offers() {
        return $this->hasMany('App\Offer');
    }

    /**
     * The offers this product has
     */
    public function active_offers() {
        return $this->hasManyThrough('App\ActiveOffer', 'App\Offer');
    }
}