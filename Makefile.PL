use ExtUtils::MakeMaker;

$xs = 0;

WriteMakefile(
    'NAME'          => 'Geo::Coder::Google',
    'VERSION_FROM'  => 'lib/Geo/Coder/Google.pm',
    PREREQ_PM       => {
                            'XML::Simple',
                            'Class::Accessor',
                            'LWP::UserAgent',
                            'URI'
                       }
);
