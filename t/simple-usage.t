# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Recall.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

use lib '../blib/lib';
use Template::Recall;

my $tr = Template::Recall->new( template_path => 't/.' );
my $h = { test => 'helowrld' };
my $s = $tr->render('01tmpl', $h );
ok( $s ne '', $s );
