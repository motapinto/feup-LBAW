<!DOCTYPE html>

<html lang="{{ app()->getLocale() }}">

<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- CSRF Token -->
  <meta name="csrf-token" content="{{ csrf_token() }}">
  <title>{{ config('app.name', 'Laravel') }} - @yield('title')</title>
  <!-- Styles -->
  <link href="{{ asset('css/common.min.css') }}" rel="stylesheet">
  <link href="{{ asset('css/feedback.min.css') }}" rel="stylesheet">
  <link href="{{ asset('css/product.min.css') }}" rel="stylesheet">
  <link href="{{ asset('bootstrap/css/bootstrap.min.css') }}" rel="stylesheet">
  <link href="{{ asset('fontawesome/css/all.min.css') }}" rel="stylesheet">
  <!-- fonts -->
  <link href="{{asset('css/montserrat.min.css') }}" rel="stylesheet">
  <script src="{{ asset('jquery/jquery.slim.js') }}"></script>
  <script src="{{ asset('bootstrap/js/bootstrap.bundle.min.js') }}"></script>
  <script src="{{ asset('fontawesome/js/fontawesome.min.js') }}"></script>
  <script src="{{ asset('popper/popper.min.js') }}"></script>
  <script src="{{ asset('js/activate_popovers.js') }}" defer></script>
  @stack('head')
</head>

<body>
  @yield('header')
  <main id="wrapper">
    @yield('navbar')
    <section id="content" class="container">
      @yield('content')
    </section>
    @yield('footer')
  </main>
</body>

</html>