<div id="content" class="container">
    <div class="row pt-4">
        <div class="col-11 col-md-4">
            <h4> Report Page </h4>
        </div>
    </div>
    <div class="row  justify-content-center justify-content-md-start">
        <div class="col-11 col-md-4 mt-4 border rounded-top">
            <div class="row border">
                <div class="col">
                    <h5 class="mt-1 mb-1 "> Report Details </h5>
                </div>
            </div>
            <div class="row">
                <div class="col">
                    <div class="row mt-4">
                        <div class="col">
                            <h6><u>Report Status</u></h6>
                            <h6 class="pl-2 pt-2">In Process </h6>
                        </div>
                    </div>
                    <div class="row mt-4">
                        <div class="col">
                            <h6><u> Product in question</u></h6>
                            <div class="pl-2 pt-2">
                                <a
                                    href="{{route('product', ['productName' => $report->key->offer->product->name, 'platformName' => $report->key->offer->platform->name])}}">
                                    <img src="{{asset('pictures/games/'.$report->key->offer->product->picture->url)}}"
                                        alt="Game Image" width="150"
                                        class="img-fluid rounded shadow-sm userOffersTableEntryImage">
                                </a>
                                <div class="ml-1 align-middle flex-nowrap">
                                    <h6 class="mb-0 d-inline">
                                        <a href="{{route('product', ['productName' => $report->key->offer->product->name, 'platformName' => $report->key->offer->platform->name])}}"
                                            class="text-dark">{{$report->key->offer->product->name}}</a>
                                    </h6>
                                    <span class="text-muted font-italic d-inline">
                                        [{{$report->key->offer->platform->name}}] </span>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="row mt-4 mb-4">
                        <div class="col">
                            <h6><u>Intervening parties</u></h6>
                        </div>
                    </div>
                    <div class="row mt-2  pl-2 pt-2">
                        <div class="col">
                            <div class="incoming_msg_img_inter"> <img
                                    src="{{ asset('pictures/profile/'.$report->reported->picture->url) }}" alt="sunil">
                            </div>
                            <a href="{{route('profile', ['username' => $report->reported->username ])}}">
                                <span class="d-inline.block"> {{$report->reported->username}} (seller) </span>
                            </a>
                        </div>
                    </div>
                    <div class="row mt-2  pl-2 pt-2">
                        <div class="col">
                            <div class="incoming_msg_img_inter"> <img
                                    src="{{ asset('pictures/profile/'.$report->reporter->picture->url) }}" alt="sunil ">
                            </div>
                            <a href="{{route('profile', ['username' => $report->reporter->username ])}}">
                                <span class="d-inline.block">{{$report->reporter->username}} (buyer) </span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-11 col-md-8  mt-4 border rounded-top">
            <div class="row border">
                <div class="col">
                    <h5 class="mt-1 mb-1"> The Conversation </h5>
                </div>
            </div>
            <div class="msg_history ">
                <div class="incoming_msg">
                    <div class="incoming_msg_img"> <img
                            src="{{ asset('pictures/profile/'.$report->reporter->picture->url) }}" alt="profile picture"
                            class="mt-2"> </div>
                    <div class="received_msg mt-2">
                        <div class="received_withd_msg">
                            <p>{{$report->description}}</p>
                            <span class="time_date"> {{$report->date}}</span>
                        </div>
                    </div>
                </div>
                <div class="outgoing_msg">
                    <div class="sent_msg">
                        <p>Awaiting for admin response ...</p>
                        <span class="time_date"> - </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>