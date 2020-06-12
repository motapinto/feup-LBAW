<?php

namespace App\Http\Controllers;

use App\ActiveOffer;
use App\ActiveProduct;
use App\Category;
use App\Genre;
use App\Http\Requests\ProductOffersRequest;
use App\Http\Requests\SearchRequest;
use App\Offer;
use App\Platform;
use App\Product;
use App\Cart;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Input;
use Image;

use Illuminate\Support\Facades\Auth;
use function foo\func;
use function Sodium\add;

class ProductController extends Controller
{
    private function getProductPlatformPair()
    {
        $products = $this->getActiveProducts();

        $productsPlatform = [];
        foreach ($products as $product) {
            foreach ($product->platforms as $platform){
                array_push($productsPlatform, (object)[
                    'product' => $product,
                    'platform' => $platform
                ]);
            }
        }

        return collect($productsPlatform);
    }

    private function getActiveProducts() {
        return Product::all()->filter(function (Product $product) {
            return ActiveProduct::find($product->id) !== null;
        });
    }

    /* Homepage */
    public function home()
    {
        $numberResults = 20;
        $productsCollection = $this->getProductPlatformPair();

        $purchableOffers = $productsCollection->filter(function ($entry) {
            $plat_id = $entry->platform->id;
            $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                return $offer->platform_id == $plat_id && $offer->final_date == null && $offer->stock != 0;
            });

            return $offers->isNotEmpty();
        });

        $homepageData = collect([
            'mostPopulars' => $purchableOffers->sortByDesc(function ($entry) {
                return $entry->product->num_sells;
            })->slice(0, $numberResults),

            'mostRecents' => $purchableOffers->sortByDesc(function ($entry) {
                return $entry->product->launch_date;
            })->slice(0, $numberResults),

            'carousel' => [
                asset('pictures/carousel/1.png'),
                asset('pictures/carousel/2.jpg'),
                asset('pictures/carousel/3.jpg'),
                asset('pictures/carousel/4.jpg'),
                asset('pictures/carousel/4.png'),
                asset('pictures/carousel/5.jpg'),
                asset('pictures/carousel/7.jpg'),
                asset('pictures/carousel/8.jpg'),
                asset('pictures/carousel/9.jpg'),
                asset('pictures/carousel/10.jpg'),
            ]
        ]);


        $offersMostPopular = collect();
        $offersMostRecents = collect();


        foreach ($homepageData['mostPopulars'] as $entry) {
            if ($entry->product->active_offers != null) {
                $plat_id = $entry->platform->id;
                $active_offers = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                    return $active_offer->offer->platform_id == $plat_id;
                });



                $minPrice = $active_offers->min(function (ActiveOffer $activeOffer) {
                     return $activeOffer->offer->discount_price();
                 });

                $offersMostPopular->add($active_offers->filter(function (ActiveOffer $activeOffer) use($minPrice){
                   return $activeOffer->offer->discount_price() ==  $minPrice;
                })->first());
            }
        }

        foreach ($homepageData['mostRecents'] as $entry) {
            if ($entry->product->active_offers != null) {
                $plat_id = $entry->platform->id;
                $active_offers = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                    return $active_offer->offer->platform_id == $plat_id;
                });



                $minPrice = $active_offers->min(function (ActiveOffer $activeOffer) {
                    return $activeOffer->offer->discount_price();
                });

                $offersMostRecents->add($active_offers->filter(function (ActiveOffer $activeOffer) use($minPrice){
                    return $activeOffer->offer->discount_price() ==  $minPrice;
                })->first());
            }
        }

        return view('pages.homepage.homepage', ['carousel' => $homepageData['carousel'], 'mostPopulars' => $offersMostPopular, 'mostRecents' => $offersMostRecents,  'genres' => Genre::all(),
            'platforms' => Platform::all(), 'categories' => Category::all(),'breadcrumbs' => []]);
    }

    /* Products list functions */
    public function search(SearchRequest $request)
    {
        $productsCollection = $this->getProductPlatformPair();

        $prices = [];
        foreach ($productsCollection as $entry) {
            if ($entry->product->active_offers != null) {
                $plat_id = $entry->platform->id;
                $active_offers = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                    return $active_offer->offer->platform_id == $plat_id;
                });

                array_push($prices, $active_offers->min(function (ActiveOffer $activeOffer) {
                    return $activeOffer->offer->price;
                }));
            }
        }

        $min_price = 0;
        $max_price = 0;
        if (count($prices) !== 0) {
            $min_price = min($prices);
            $max_price = max($prices);
        }

        $filtered = $this->filterProducts($request, $productsCollection);

        $genres = Genre::all();
        $platforms = Platform::all();
        $categories = Category::all();

        $filtered = $filtered->forPage($request->has('page') ? $request->input('page') : 0, 9);

        $filtered = $filtered->map(function ($entry) {
            $plat_id = $entry->platform->id;
            $min_price = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                return $active_offer->offer->platform_id == $plat_id;
            })->min(function (ActiveOffer $active_offer) {
                return $active_offer->offer->discount_price();
            });

            return (object)[
                'id' => $entry->product->id,
                'name' => $entry->product->name,
                'description' => $entry->product->description,
                'launch_date' => $entry->product->launch_date,
                'category' => $entry->product->category->name,
                'platform' => $entry->platform->name,
                'genres' => $entry->product->genres,
                'picture' => asset('/pictures/games/' . $entry->product->picture->url),
                'price' => $min_price
            ];
        });

        return view('pages.products.products', [
            'genres' => $genres, 'platforms' => $platforms, 'categories' => $categories,
            'min_price' => $min_price, 'max_price' => $max_price, 'products' => $filtered, 'breadcrumbs' => [
                'Products' => route('search')]
        ]);
    }

    public function get(SearchRequest $request)
    {
        $productsCollection = $this->getProductPlatformPair();
        $filtered = $this->filterProducts($request, $productsCollection);
        $prices = $this->returnPrices($filtered);

        if (count($prices) === 0) {
            $prices = [0, 100];
        }

        $min_price = min($prices);
        $max_price = max($prices);

        $request->has('page') ? $filtered = $filtered->forPage($request->input('page'), 9) :
            $filtered = $filtered->forPage(0, 9);

        $filtered = $filtered->map(function ($entry) {
            $plat_id = $entry->platform->id;
            $min_price = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                return $active_offer->offer->platform_id == $plat_id;
            })->min(function (ActiveOffer $active_offer) {
                return $active_offer->offer->discount_price();
            });

            return [
                'name' => $entry->product->name . ' ['.$entry->platform->name.']',
                'url' => route('product', ['productName' => $entry->product->name, 'platformName' => $entry->platform->name]),
                'image' => asset('/pictures/games/' . $entry->product->picture->url),
                'price' => $min_price,
            ];
        });

        return response()->json(['products' => array_values($filtered->toArray()), 'max_price' => $max_price, 'min_price' => $min_price]);
    }

    private function filterProducts(SearchRequest $request, \Illuminate\Support\Collection $products)
    {
        $filter = $products;

        $filter = $filter->filter(function ($entry) {
            $plat_id = $entry->platform->id;
            $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                return $offer->platform_id == $plat_id && $offer->final_date == null && $offer->stock != 0;
            });

            return $offers->isNotEmpty();
        });

        if($request->has('query')) {
            $query = htmlentities($request->input('query'));
            $queryExploded = explode(' ', $query);
            $querySql = implode(':* &', $queryExploded);

            $queried = Product::whereRaw("name_tsvector @@ to_tsquery('". $querySql.":*')")->get();
            $filter = $filter->filter(function ($entry) use ($queried) {
                return $queried->search(function (Product $product) use($entry) {
                        return $product->id === $entry->product->id;
                    }) !== false;
            });
        }

        if ($request->has('genres')) {
            $filter = $filter->filter(function ($entry) use ($request) {
                $decoded = explode(",", $request->input('genres'));
                $genres = $entry->product->genres->map(function ($genre) {
                    return $genre->name;
                });
                return count(array_intersect($decoded, $genres->toArray())) == count($decoded);
            });
        }

        if ($request->has('platform')) {
            $filter = $filter->filter(function ($entry) use ($request) {
                return $entry->platform->name == $request->input('platform');
            });
        }

        if ($request->has('category')) {
            $filter = $filter->filter(function ($entry) use ($request) {
                return $entry->product->category->name == $request->input('category');
            });
        }

        if ($request->has('min_price')) {
            $filter = $filter->filter(function ($entry) use ($request) {
                $plat_id = $entry->platform->id;
                $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                    return $offer->platform_id == $plat_id;
                });

                $min_price = $offers->min(function ($offer) {
                  return $offer->discount_price();
                });

                return $min_price >= $request->input('min_price');
            });
        }

        if ($request->has('max_price')) {
            $filter = $filter->filter(function ($entry) use ($request) {
                $plat_id = $entry->platform->id;
                $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                    return $offer->platform_id == $plat_id;
                });

                $min_price = $offers->min(function ($offer) {
                    return $offer->discount_price();
                });

                return $min_price <= $request->input('max_price');
            });
        }

        if ($request->has('sort_by')) {
            if ($request->input('sort_by') == 1) {
                $filter = $filter->sortByDesc(function ($entry) {
                    $plat_id = $entry->platform->id;
                    $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                        return $offer->stock > 0 && $offer->platform_id == $plat_id;
                    });

                    return $offers->min('price');
                });
            } else if ($request->input('sort_by') == 2) {
                $filter = $filter->sortBy(function ($entry) {
                    $plat_id = $entry->platform->id;
                    $offers = $entry->product->offers->filter(function (Offer $offer) use ($plat_id) {
                        return $offer->stock > 0 && $offer->platform_id == $plat_id;
                    });

                    return $offers->min('price');
                });
            } else if ($request->input('sort_by') == 3) {
                $filter = $filter->sortByDesc(function ($entry) {
                    return $entry->product->num_sells;
                });
            } else if ($request->input('sort_by') == 4) {
                $filter = $filter->sortByDesc(function ($entry) {
                    return $entry->product->launch_date;
                });
            }
        }

        return $filter;
    }

    private function returnPrices($filtered)
    {
        $prices = [];

        foreach ($filtered as $entry) {
            if ($entry->product->active_offers != null) {
                $plat_id = $entry->platform->id;
                $active_offers = $entry->product->active_offers->filter(function (ActiveOffer $active_offer) use ($plat_id) {
                    return $active_offer->offer->platform_id == $plat_id;
                });

                array_push($prices, $active_offers->min(function (ActiveOffer $activeOffer) {
                    return $activeOffer->offer->price;
                }));
            }
        }

        return $prices;
    }

    /* Individual Product functions */
    public function getProduct($productName) {
        $product = Product::where('name', '=', $productName)->first();
        return ($product === null) ? abort(404, 'Product doesn\'t exist') : $product;
    }

    public function getPlatform($platformName) {
        $platform = Platform::where('name', '=', $platformName)->first();
        return ($platform === null) ? abort(404, 'Platform doesn\'t exist') : $platform;
    }

    public function show(Request $request, $productName, $platformName)
    {
        $product = $this->getProduct($productName);
        $platform = $this->getPlatform($platformName);
        $offers = Offer::where('product_id', '=', $product->id)->where('platform_id', '=', $platform->id)->where('stock', '>', 0)->get();
        $offers = $this->filterOffersAlreadyInCart($request,$offers);
        $offersSortPrice = $this->sortOffersByPrice($offers);
        $platformName = $platform->name;

        return view('pages.product.product', ['user' => Auth::user(), 'product' => $product, 'platformName' => $platformName,
            'offers'  => $offersSortPrice, 'numberOffers' => $offers->count(),
            'breadcrumbs' => [ $product->name.' ['.$platformName.']' => route('product', ['productName' => $product->name, 'platformName' => $platformName])]]);
    }

    private function filterOffersAlreadyInCart(Request $request, $offers)
    {
        //Get cart table content
        if (Auth::check()) {

            $user = Auth::user();
            $cart = $user->cart;

            return (object) $this->getFilteredOffer($offers, $cart);
        }
        //Get session Info
        else {
            if($request->session()->has('cart')){
                $cart=$request->session()->get('cart');
                return (object) $this->getFilteredOffer($offers, $cart);
            }else{
                return $offers;
            }
        }
    }

    private function getFilteredOffer($offers, $cart)
    {
        $offersFiltered = new Collection();

        foreach ($offers as $offer) {
            foreach ($cart as $cartEntry) {
                if ($cartEntry->offer_id == $offer->id) {
                    $offer->stock--;
                }
            }
            if ($offer->stock > 0) {
                $offersFiltered->push($offer);
            }
        }

        return $offersFiltered;
    }

    public function sortOffersByPrice($offers)
    {
        return $offers->sortByDesc(function (Offer $offer) {
            return $offer->seller->rating;
        })->sortByDesc(function (Offer $offer) {
            return $offer->seller->num_sells;
        })->sortBy(function (Offer $offer) {
            return $offer->discount_price();
        });
    }

    public function sortOffersByRating($offers)
    {
        return $offers->sortBy(function (Offer $offer) {
            return $offer->discount_price();
        })->sortByDesc(function (Offer $offer) {
            return $offer->seller->num_sells;
        })->sortByDesc(function (Offer $offer) {
            return $offer->seller->rating;
        });
    }

    public function sort($productName, $platformName, ProductOffersRequest $request) {
        $sortBy = Offer::all()->filter(function (Offer $offer) use ($productName, $platformName) {
            return $offer->product->name == $productName && $offer->platform->name == $platformName && $offer->stock > 0;
        });

        $sortBy = $this->filterOffersAlreadyInCart($request, $sortBy);

        if ($request->input('sort_by') == 2) {

            $sortBy = $sortBy->sortBy('discountPriceColumn')->sortByDesc(function (Offer $offer) {
                return $offer->seller->num_sells;
            })->sortByDesc(function (Offer $offer) {
                return $offer->seller->rating;
            });

        } else {

            $sortBy = $sortBy->sortByDesc(function (Offer $offer) {
                return $offer->seller()->getResults()->rating;
            })->sortByDesc(function (Offer $offer) {
                return $offer->seller()->getResults()->num_sells;
            })->sortBy('discountPriceColumn');
        }

        return view('partials.product.product_offers', [
            'offers' => $sortBy,
            'number' => $request->has('all_offers') && $request->input('all_offers') ? $sortBy->count() : 10,
            'display' => true
        ]);
    }
}