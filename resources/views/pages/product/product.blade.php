@extends('layouts.app')
@section('title', $product->name.' ['. $platformName.']')

@push('head')
    <script src="{{ asset('js/products/product.min.js') }}" defer></script>
@endpush

@section('header')
    @include('partials.header.user_header')
@endsection

@section('navbar')
    @include('partials.navbar.breadcrumbs',['breadcrumbs'=> $breadcrumbs])
@endsection

@section('content')
    @include('partials.product.product', ['numberOffers' => $numberOffers, 'offers' => $offers])
@endsection

@section('footer')
    @include('partials.footer.footer')
@endsection