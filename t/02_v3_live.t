use strict;
use utf8;
use Test::Number::Delta within => 1e-4;
use Test::More;
use Encode ();
use Geo::Coder::Google;

if ($ENV{TEST_GEOCODER_GOOGLE_LIVE}) {
  plan tests => 12;
} else {
  plan skip_all => 'Not running live tests. Set $ENV{TEST_GEOCODER_GOOGLE_LIVE} = 1 to enable';
}

{
    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    my $location = $geocoder->geocode('548 4th Street, San Francisco, CA');
    delta_ok($location->{geometry}{location}{lat}, 37.778907);
    delta_ok($location->{geometry}{location}{lng}, -122.39732);
    is($geocoder->{"last_status"}, "OK", "last_staus");
    isa_ok($geocoder->_json, "JSON");
    isa_ok($geocoder->{"last_res"}, "HTTP::Response", "last_res");
    isa_ok($geocoder->{"last_data"}, "HASH", "last_data");
}

SKIP: {
    skip "google.co.jp suspended geocoding JP characters", 1;
    my $geocoder = Geo::Coder::Google->new(apikey => $ENV{GOOGLE_MAPS_APIKEY}, host => 'maps.google.co.jp');
    my $location = $geocoder->geocode("東京都港区赤坂2-14-5");
    delta_ok($location->{Point}->{coordinates}->[0], 139.737808);
}

# as per http://code.google.com/apis/maps/documentation/geocoding/#CountryCodes
{
    my $geocoder_es = Geo::Coder::Google->new(apiver => 3, gl => 'es');
    my $location_es = $geocoder_es->geocode('Toledo');
    delta_ok($location_es->{geometry}{location}{lng}, -4.0244759);
    my $geocoder_us = Geo::Coder::Google->new(apiver => 3);
    my $location_us = $geocoder_us->geocode('Toledo');
    delta_ok($location_us->{geometry}{location}{lng}, -83.555212);
}

# URL signing
{
    # sample clientID from http://code.google.com/apis/maps/documentation/webservices/index.html#URLSigning
    my $client = $ENV{GMAP_CLIENT};
    my $key    = $ENV{GMAP_KEY};
    my $geocoder = Geo::Coder::Google->new( apiver => 3, client => $client, key => $key );
    my $location = $geocoder->geocode(location => 'New York');
    delta_ok($location->{geometry}{location}{lat}, 40.7143528, 'Latitude for NYC');
    delta_ok($location->{geometry}{location}{lng}, -74.0059731, 'Longitude for NYC');
}

SKIP: {
    my $geocoder_utf8 = Geo::Coder::Google->new(apiver => 3, oe => 'utf8');
    my $location_utf8 = $geocoder_utf8->geocode('Bělohorská 80, 6, Czech Republic');
    is($location_utf8->{formatted_address}, 'Bělohorská 1685/80, 169 00 Prague-Prague 6, Czech Republic');
}
