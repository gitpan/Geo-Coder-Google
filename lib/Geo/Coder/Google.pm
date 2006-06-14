package Geo::Coder::Google;

use strict;
use warnings;

use Geo::Coder::Google::Address;
use LWP::UserAgent;
use XML::Simple;
#use JSON;
use URI;
use Data::Dumper;

our $VERSION = '0.01';
use constant DEBUG => 0;
use constant GEO_HOST => qq|http://maps.google.com/maps/geo|;

my %ERROR_CODES = (
    601 => "G_GEO_MISSING_ADDRESS: No address specified",
    602 => "G_GEO_UNKNOWN_ADDRESS: The address entered cannot be identified",
    603 => "G_GEO_UNAVAILABLE_ADDRESS: There is no geocoding information for this address",
    610 => "G_GEO_BAD_KEY: The API KEY supplied is invalid",
    620 => "G_GEO_TOO_MANY_QUERIES: This client has exceeded the query count.  Try later.",
    500 => "G_GEO_SERVER_ERROR: Internal Geocode Service Error, Try later.",
);

=head1 NAME

Geo::Coder::Google - Geocoder that utilizes the public Google Geocoder API

=head1 SYNOPSIS

    use Geo::Coder::Google;
    use Data::Dumper;

    my $geocoder = Geo::Coder::Google->new({ key => "$API_KEY" });

    my $address  = '1600 Pennsylvania Ave Washington DC';
    
    # Returns an array of matching records.  Geocoding is often not precise
    # enough to guarantee one record, so this is always an array
    my @response = $geocoder->geocode($address);

    foreach my $addr ( @response ) {
        print $addr->address, "\n"; # Formatted address (looks pretty)
        print "This address is at: ",
            $addr->latitude, " x ", $addr->longitude, "\n";
        # Now for the other fields.  Because Geocoding isn't *just* in the
        # US, the format is loosely based upon xAL.  You can readup on it
        # here: http://www.oasis-open.org/committees/ciq/ciq.html#6
        print $addr->administrativearea, "\n";    # State/Province (e.g., "CA")
        print $addr->subadministrativearea, "\n"; # County (e.g., "Santa Clara")
        print $addr->locality, "\n";     # The City
        print $addr->postalcode, "\n";   # Postal Code
        print $addr->thoroughfare, "\n"; # Just the number and street info
    }

=head1 DESCRIPTION

This module utilizes LWP::UserAgent to request geocode results from the Google
Geocode Service.  This requires that you register for an API key at:

http://www.google.com/apis/maps/signup.html

Once you have your key, you can begin using this module for geocoding.  If
your key is invalid, or misentered, you will receive an "Error 610".  

=head2 ERROR CASES

=over

=item G_GEO_SUCCESS (200)

Successful geocode

=item G_GEO_MISSING_ADDRESS (601)

You have to supply at least some form of an address.

=item G_GEO_UNKNOWN_ADDRESS (602)

You probably supplied gibberish, didn't you?  Didn't you!?

=item G_GEO_UNAVAILABLE_ADDRESS (603)

Google knows your address.  But it is a secret.  Sshh.

=item G_GEO_BAD_KEY (610)

Your key is not valid.  Check it again.

=item G_GEO_TOO_MANY_QUERIES (620)

You have used up too many queries.  There is a 50,000 limit that is likely to
change (who knows which direction).

=item G_GEO_SERVER_ERROR (500)

Server Error.  Oops!

=back

=head1 METHODS

=head2 new

This simple constructor gets you started.
    
    my $geocoder = Geo::Coder::Google->new({ key => $YOURKEY });

Parameters:

=over

=item key

Required.  Set this to your Google API Key

=item timeout

Optional timeout to use before giving up and reporting failure.

=item agent

Optional parameter to set the User Agent.  Defaults to Geo::Coder::Google/$VERSION

=back

=cut

sub new {
    my $class  = shift;
    my $attr   = ( $_[0] and ref $_[0] eq 'HASH' ) ? $_[0] : undef;
    my %config = map { uc($_) => $attr->{$_} } keys %$attr;
    unless ( $config{KEY} ) {
        if ( $ENV{GMAP_KEY} ) {
            $config{KEY} = $ENV{GMAP_KEY};
        } else {
            warn "Unable to use Geo::Coder::Google without an API key.\n";
            return undef;
        }
    }
    my $self = {
        _ua => LWP::UserAgent->new(
            agent => $config{AGENT} || "Geo::Coder::Google/$VERSION"
        ),
        key => $config{KEY}
    };

    if ( $config{TIMEOUT} and int($config{TIMEOUT}) > 0 ) {
        $self->{_ua}->timeout(int($config{TIMEOUT}));
    }
    bless $self, $class;
}

=head2 geocode

This method returns an array of the results for the address specified.

=cut

sub geocode {
    my ( $self, $address, $format ) = @_;
    return () unless $address;

    my $uri = URI->new(+GEO_HOST, 'http');
    $format = lc($format);
    $format = 'xml' unless ( $format =~ /^(xml|kml|json)$/ );
    $uri->query_form(
        key    => $self->{key},
        output => $format,
        q      => $address
    );
    #warn "Fetching: " . $uri->as_string . "\n";
    my $res     = $self->{_ua}->get( $uri->as_string );
    my @result  = ();
    if ( $res->is_success ) {
        # JSON support coming soon
        if ( $format eq 'json' ) {
            #my $json = new JSON(skipinvalid => 1);
            #print $res->content;
            #$result = $json->jsonToObj($res->content);
        }
        elsif ( $format eq 'xml' ) {
            #print $res->content;
            my $res = XMLin($res->content, ForceArray => 1);
            if ( $res->{Response} and
                 $res->{Response}->[0]->{Status}->[0]->{code}->[0] eq '200' )
            {
                foreach my $address ( @{$res->{Response}->[0]->{Placemark}} ) {
                    push @result,
                        Geo::Coder::Google::Address->new_xml($address);
                }
            }
            elsif ( $res->{Response}->[0]->{Status}->[0]->{code}->[0] ) {
                warn "Geocode error: " .
                    $ERROR_CODES{$res->{Response}->[0]->{Status}->[0]->{code}->[0]} . "\n";
            }
        } else {
            return $res->content;
        }
    } else {
        warn "Failed fetching response from " .
            +GEO_HOST . ": " . $res->status_line;
    }
    return @result;
}

=head1 AUTHORS

Copyright 2006 J. Shirley <jshirley@gmail.com>

This program is free software;  you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=head2 THANKS

Google!  You can do no evil, except in China.  We still love you, though.

=head1 SEE ALSO

L<Geo::Coder::Google::Address> - The Google address object

=cut

1;
