<tr>
    <td scope="row" class="border-0 text-center align-middle">
        <img src={{ asset('/pictures/games/'.$data->picture->url)}}
            class="img-fluid rounded shadow-sm adminTableImagePreview" alt="Game Picture">
    </td>
    <td class="text-center align-middle">{{$data->name}}</td>
    <td class="text-center align-middle">{{$data->category->name}}</td>
    <td class="text-center align-middle">
        @php
        $string="";
        foreach ($data->genres as $genre ) {
        $string=$string.$genre->name.",";
        }
        $string=rtrim($string, ",");
        echo $string
        @endphp
    </td>
    <td class="text-center align-middle">
        @php
        $string="";
        foreach ($data->platforms as $platform ) {
        $string=$string.$platform->name.",";
        }
        $string=rtrim($string, ",");
        echo $string

        @endphp
    </td>
    <td class="align-middle">
        <div class="btn-group-justified btn-group-md">
            <a href={{'/admin/product/'.$data->id}} class="btn btn-blue btn-block">
                <i class="fas fa-edit d-inline-block"></i> <span class="d-none d-lg-inline-block">
                    Edit Product </span>
            </a>
            <button type="button mt-5 mb-5 " class="btn btn-red btn-block" data-toggle="modal"
                data-target="#modal-delete">
                <i class="fas fa-trash-alt"></i> <span class="d-none d-lg-inline-block"> Delete
                    Product </span>
            </button>
            @include('admin.partials.modal.confirmProductDelete',['data'=>$data->id])
        </div>
    </td>
</tr>