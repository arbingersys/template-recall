# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TEST.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

use strict;
use lib '../blib/lib';
use Template::Recall;


# Text
my $tstr;
for (<DATA>) { $tstr .= $_ }
my $tr = Template::Recall->new( template_str => $tstr );


# Render and save internally
$tr->render('one', 's', { var => 'helo' } );

$tr->trim(); # Might as well try trimming, too
$tr->render('two', 's', { var => 'wrld' } );
$tr->trim('OFF');


# Render & store + regular render
$tr->render('three', 's', 
	{ 
		var => $tr->render( 'two', { var => 'helowrld'} ) 
	} 
);

$tr->render('four', 's');
$tr->render('four', 'a'); # Do an append. Result: two sections output


# Output sections arbitrarily
my $s = $tr->assemble( [ 'three', 'two', 'one' ] );
my $t = $tr->assemble( [ 'one', 'two', 'three', 'four' ], 'clear' );
ok( ( defined($s) and defined($t) ), "$s-------------$t");

# This has been cleared, so we should get nothing
$s = undef;
$s = $tr->assemble( [ 'two', 'one', 'three' ] );
ok( !defined($s) );

# Turn off storage

$s = undef;
$s = $tr->render('one', { var => '"No storage"' } );
ok( defined( $s ), "render() returns stuff: $s" );




__DATA__
[===== one =====]
one (['var'])
[===== two =====]
two (['var'])

[===== three =====]
three (['var'])


[===== four =====]
four (no interp.)

