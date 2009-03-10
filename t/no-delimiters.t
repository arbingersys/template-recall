# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Recall.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

use lib '../blib/lib';
use Template::Recall;


# Section file templates

my $tr = Template::Recall->new( template_path => 't/.', delims => 'none' );
my $h = { TEMPLATE_VAR_test => 'helowrld' };
my $s = $tr->render('03tmpl', $h );

ok( $s ne '', "Section file templates: $s" );




# Single file, sectioned template

$tr = Template::Recall->new( 
	template_path => 't/03atmpl.html', 
	delims => 'none',
	secpat => qr/TEMPLATE_SECTION_\w+/,
	secpat_delims => 'no'
);

$h = { TEMPL_VAR_test => 'helowrld' };
$s = $tr->render('TEMPLATE_SECTION_one', $h ) . $tr->render('TEMPLATE_SECTION_TWO', $h );
ok( $s ne '', "Single file, sectioned template: $s" );
