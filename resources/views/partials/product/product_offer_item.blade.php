<tr id="entry-offer-{{$offer->id}}" class="offer {{  $display ? '' : 'offer_outside'}}">
    <td scope="row" class="border-0 align-middle">
        <div class="p-2 m-0">
            <h4><a data-toggle="modal" data-target="#user-{{$offer->seller->id}}" href="#" class="seller"
                    style="color:black">{{$offer->seller->username}}</a></h4>
            <span class="font-weight-bold cl-success">
                <i class="fas fa-thumbs-up"></i> {{ $offer->seller->rating }}
            </span>
            <span>
                {{'|'}} <i class="fas fa-shopping-cart"></i> {{$offer->seller->num_sells}} |
            </span>
            <span>
                Stock:<span id="offer-{{$offer->id}}-stock">{{$offer->stock}}</span>
            </span>
            @include('partials.feedback.feedback', ['seller' => $offer->seller])
        </div>
    </td>
    @if($offer->price != $offer->discount_price())
    <td class="text-center align-middle">
        <del class="">${{number_format((float)$offer->price, 2, '.', '')}}</del>
        <strong class="cl-success pl-2">${{number_format((float)$offer->discount_price(), 2, '.', '')}}</strong>
    </td>
    @else
    <td class="text-center align-middle"><strong>${{number_format((float)$offer->price, 2, '.', '')}}</strong></td>
    @endif
    <td class="text-center align-middle">
        <div class="btn-group-justified">
            @if(Auth::check())
            <button data-offer="{{$offer->id}}" class="btn btn-orange button-offer"
                {{Auth::user()->isBanned() ? 'disabled' : ''}}><i class="fas fa-cart-plus"></i>
            </button>
            @else
            <button data-offer="{{$offer->id}}" class="btn btn-orange button-offer"><i class="fas fa-cart-plus"></i>
            </button>
            @endif
        </div>
    </td>
</tr>