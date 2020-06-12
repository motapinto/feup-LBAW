<div id="content" class="container mt-5">
    <div class="row">
        <div class="col-sm-12 usercontent-left">
            @if($user->isBanned()) @include('partials.user.ban_appeal') @endif
            <div class="row px-3">
                <div class="col-sm-9 " style=" display:flex; align-items: center;">
                    <h4 class="text-left">Current Offers<span id="current-offer-counter"
                            class="badge ml-1 badge-secondary"> {{$currOffers->count()}}</span></h4>
                </div>
                @if(!$user->isBanned())
                <div class="col-sm-3">
                    <a href={{url('/offer')}} class="btn p-2 btn-sm btn-orange btn-block text-white" role="button"> <i
                            class="mr-1 fas fa-plus"></i>
                        <span class="d-none d-md-inline-block"> Add offer </span>
                    </a>
                </div>
                @endif
            </div>
            <div class="container mt-3 mb-3">
                <div class="row ">
                    <div class="col-12">
                        <div class="table-responsive table-striped tableFixHead mt-3">
                            <table id="userCurrentOffersTable" class="table p-0">
                                <thead>
                                    <tr>
                                        <th scope="col" class="border-0 bg-light">
                                            <div class="p-2 px-3 text-uppercase">Product Details</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Start Date</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Current Price</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Options</div>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($currOffers as $currentOffer)
                                    <tr id="offer{{$currentOffer->id}}">
                                        <td scope="row" class="border-0 align-middle">
                                            <div class="p-2">
                                                <img src="{{ asset('/pictures/games/'.$currentOffer->product->picture->url) }}"
                                                    alt="Product Image" width="150"
                                                    class="img-fluid rounded shadow-sm d-none d-sm-inline userOffersTableEntryImage">
                                                <div class="ml-3 d-inline-block align-middle flex-nowrap">
                                                    <h5 class="mb-0 d-inline-block"><a
                                                            href="{{url('product/'.$currentOffer->product->name.'/'.$currentOffer->platform->name)}}"
                                                            class=" text-dark">{{$currentOffer->product->name}}</a>
                                                    </h5>
                                                    <span
                                                        class="text-muted font-weight-normal font-italic d-inline-block">
                                                        [{{$currentOffer->platform->name}}]
                                                    </span>
                                                    <h6>Stock: {{$currentOffer->stock}} keys</h6>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="text-center align-middle">{{$currentOffer->init_date}}</td>
                                        @if($currentOffer->price != $currentOffer->discount_price())
                                        <td class="text-center align-middle">
                                            <del><strong>${{$currentOffer->price}}</strong></del>
                                            <strong class="cl-green pl-2">${{$currentOffer->discount_price()}}</strong>
                                        </td>
                                        @else
                                        <td class="text-center align-middle"><strong>${{$currentOffer->price}}</strong>
                                        </td>
                                        @endif
                                        <td class="align-middle">
                                            <div class="btn-group-justified btn-group-md">
                                                <a href="{{ route('editOffer', ['id' => $currentOffer->id])}}"
                                                    class="btn btn-blue btn-block flex-nowrap" role="button">
                                                    <i class="fas fa-edit d-inline-block"> </i>
                                                    <span class="d-none d-md-inline-block"> Edit Offer </span>
                                                </a>
                                                <form action="{{route('deleteOffer', ['id' => $currentOffer->id])}}"
                                                    method="POST">
                                                    @csrf @method('DELETE')
                                                    <button type="submit"
                                                        class=" btn btn-red btn-block flex-nowrap mt-2"
                                                        id="delete-offer-btn">
                                                        <i class="fas fa-trash-alt"></i>
                                                        <span class="d-none d-md-inline-block"> Delete Offer </span>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-sm-12 usercontent-left mt-5">
            <div class="row px-3">
                <div class="col-sm-12">
                    <h4 class="text-left">Past Offers
                        <span id="past-offer-counter" class="badge ml-1 badge-secondary">{{$pastOffers->count()}}</span>
                    </h4>
                </div>
            </div>
            <div class="container mt-3 mb-3">
                <div class="row ">
                    <div class="col-12">
                        <div class="table-responsive table-striped tableFixHead mt-3 mt-3">
                            <table id="user-past-offer-table" class="table p-0">
                                <thead>
                                    <tr>
                                        <th scope="col" class="border-0 bg-light">
                                            <div class="p-2 px-3 text-uppercase">Product Details</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Start Date</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">End Date</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Last Price</div>
                                        </th>
                                        <th scope="col" class="border-0 bg-light text-center">
                                            <div class="py-2 text-uppercase">Profit</div>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($pastOffers as $pastOffer)
                                    @include('partials.user.tables.pastOfferEntry',['pastOffer'=>$pastOffer])
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>