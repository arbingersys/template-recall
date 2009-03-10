# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Recall.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

use lib '../blib/lib';
use Template::Recall;


# Text
my $tr = Template::Recall->new( template_path => 't/.', flavor => qr/txt$/i );
my $h = { test => 'helowrld' };
my $s = $tr->render('04tmpl', $h );
ok( $s ne '', "From text file:\n$s" );


# Switch to XML

$tr = Template::Recall->new( template_path => 't/.', flavor => qr/xml$/i );
$s = $tr->render('04tmpl', $h );
ok( $s ne '', "Switched to XML:\n$s" );

