@extends('layouts.app')
@section('title', 'Homepage')

@section('header')
    @include('partials.header.user_header')
@endsection

@section('navbar')
    @include('partials.navbar.commerce_navbar',['breadcrumbs' => $breadcrumbs])
@endsection

@section('content')
    @include('partials.homepage.carousel',['carousel' => $carousel])
    @include('partials.homepage.most_populars',['data' => $mostPopulars])
    @include('partials.homepage.most_recents',['data' => $mostRecents])
@endsection

@section('footer')
    @include('partials.footer.footer')
@endsection