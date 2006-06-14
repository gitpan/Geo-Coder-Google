package Geo::Coder::Google::Address;

use strict;
use warnings;

use Data::Dumper;
use base qw|Class::Accessor|;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw|
    address
    country administrativearea subadministrativearea
    locality thoroughfare postalcode
    latitude longitude
|);

my %FIELD_TO_ACCESSOR = (
    AdministrativeAreaName    => 'administrativearea',
    SubAdministrativeAreaName => 'subadministrativearea',
    LocalityName              => 'locality',
    ThoroughfareName          => 'thoroughfare',
    CountryNameCode           => 'country',
    PostalCodeNumber          => 'postalcode',
    address                   => 'address',
);

=head1 NAME

Geo::Coder::Google - Geocoder that utilizes the public Google Geocoder API

=head1 SYNOPSIS

This is really just used (for now) by L<Geo::Coder::Google>.  More work
coming down the pipe!

=cut

sub new {
    my ( $class ) = @_;
    bless {}, $class;
}

sub new_json {
    my ( $class ) = @_;
    bless {}, $class;
}

sub new_xml {
    my ( $class, $obj ) = @_;
    my $self = {};
    bless $self, $class;

    if ( $obj->{AddressDetails} and $obj->{Point} and $obj->{address} ) {
        my $coords = $obj->{Point}->[0]->{coordinates}->[0];
        $self->coordinates(split(/,/, $coords));
        my $root = $obj->{AddressDetails}->[0]->{Country}->[0];
        $self->parse($obj);
    }

    return $self;
}

sub coordinates {
    my ( $self, $lat, $long ) = @_;
    if ( $lat and $long ) {
        $self->latitude($lat);
        $self->longitude($long);
    }
    return wantarray ?
        ( $self->latitude, $self->longitude ) :
        { latitude => $self->latitude, longitude => $self->longitude };
}

sub parse {
    my ( $self, $obj, $key ) = @_;
    if ( ref $obj ) {
        if ( ref $obj eq 'ARRAY' ) {
            foreach my $child_obj ( @$obj ) {
                $self->parse($child_obj, $key);
            }
        }
        elsif ( ref $obj eq 'HASH' ) {
            foreach my $child_key ( keys %$obj ) {
                $self->parse($obj->{$child_key}, $child_key);
            }
        }
    } else {
        if ( $key and $FIELD_TO_ACCESSOR{$key} ) {
            warn "Setting $key => $FIELD_TO_ACCESSOR{$key} = $obj\n";
            my $fn = $FIELD_TO_ACCESSOR{$key};
            $self->$fn($obj);
        }
    }
}

sub __value_from_xml {
    my ( $input ) = @_;
    return ref $input eq 'ARRAY' ? $input->[0] : "";
}

=head1 AUTHORS

Copyright 2006 J. Shirley <jshirley@gmail.com>

This program is free software;  you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=head1 SEE ALSO

You probably just want the base L<Geo::Coder::Google> module.

=cut

1;

