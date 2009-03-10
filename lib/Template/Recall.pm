package Template::Recall;

use 5.008001;
use strict;
use warnings;

use base qw(Template::Recall::Base);

our $VERSION='0.15';


sub new {

	
	my $class = shift;
	my $self = {};

	my ( %h ) = @_;


	# Set default values
	$self->{'is_file_template'} = 0;
	$self->{'template_flavor'} = qr/html$|htm$/i;
	$self->{'template_secpat'} = qr/\[\s*=+\s*\w+\s*=+\s*\]/;		# Section pattern
	$self->{'secpat_delims'} = [ '\[\s*=+\s*', '\s*=+\s*\]' ];	# Section delimiters
	$self->{'delims'} = [ '\[\'', '\'\]' ];
	$self->{'trim'} = undef;		# undef=off
	$self->{'stored_secs'} = {};	# Store rendered sections internally
	

	bless( $self, $class );


	# Compile flavor, if there is one
	$self->{'template_flavor'} = $h{'flavor'} if defined( $h{'flavor'} );



	# User defines section pattern
	$self->{'template_secpat'} = qr/$h{'secpat'}/ if defined( $h{'secpat'} ); 


	# Section: User sets 'no delimiters'
	$self->{'secpat_delims'} = undef 
		if defined($h{'secpat_delims'}) and !ref($h{'secpat_delims'});
		
	# Section: User specifies delimiters
	$self->{'secpat_delims'} = [ @{ $h{'secpat_delims'} } ] 
		if defined($h{'secpat_delims'}) and ref($h{'secpat_delims'});
	


	# User sets 'no delimiters'
	$self->{'delims'} = undef if defined($h{'delims'}) and !ref($h{'delims'});
		
	# User specifies delimiters
	$self->{'delims'} = [ @{ $h{'delims'} } ] 
		if defined($h{'delims'}) and ref($h{'delims'});



	# Check the path
	$self->{'template_path'} = '.' 
		if ( not defined($h{'template_path'}) or !-e $h{'template_path'} );		# Default is local dir


	# User supplied the template from a string

	if ( defined($h{'template_str'}) ) {
		$self->{'template_str'} = $h{'template_str'};
		$self->init_template_str();
		return $self;
	}


	# Single file template:

	if ( defined($h{'template_path'} ) and -f $h{'template_path'} ) {

		$self->{'template_path'} = $h{'template_path'};
		$self->{'is_file_template'} = 1;	# true

		$self->init_file_template();

		return $self;

	}
	elsif ( defined($h{'template_path'}) and -d $h{'template_path'} ) {		
		# It's a directory

		$self->{'template_path'} = $h{'template_path'};

	}



	$self->{'template_path'} =~ s/\\$|\/$//g;	# Remove last slash
	$self->{'template_path'} =~ s/\\/\//g;		# All forward slashes


	# Get all the template files in the given directory

	opendir(DIR, $self->{'template_path'}) || die "Can't open $self->{'template_path'} $!";
	$self->{'template_files'} = 
		[	map { "$self->{'template_path'}/$_" } 
			grep { /$self->{'template_flavor'}/ && -f "$self->{'template_path'}/$_" } 
			readdir(DIR) ];
	closedir(DIR);

	return $self;



} # new()






sub render {

	my $self = shift;
	my $tpattern = shift;
	my $href = shift; # Check this for storage directive below


	return "Error: no section to render: $tpattern\n" if !defined($tpattern);


	# Check for store/append flag
	my $stor = undef;
	if ( $href and !ref($href) and $href =~ /a|s/ ) {
		$stor = $href;
		$href = shift; # The next parameter must be the hashref
	}

	return "Error: must pass reference to hash\n" if defined($href) and !ref($href);




	# Single file template handling

	if ( $self->{'is_file_template'} and ref($href) )
	{
		
		# Save sections internally
		if ( defined($stor) and $stor eq 'a' ) { # Append
			${$self->{'stored_secs'}}{$tpattern} .= 
				render_file($self, $tpattern, $href);
			return;
		}


		if ( defined($stor) and $stor eq 's' ) { # Overwrite
			${$self->{'stored_secs'}}{$tpattern} = 
				render_file($self, $tpattern, $href);
			return;
		}


		# Otherwise, return value to calling code
		return render_file($self, $tpattern, $href);
		
	}
	elsif ( $self->{'is_file_template'} ) {			# No tags to replace

		# Save sections internally
		if ( defined($stor) and $stor eq 'a' ) { # Append
			${$self->{'stored_secs'}}{$tpattern} .= render_file($self, $tpattern);
			return;
		}

		if ( defined($stor) and $stor eq 's' ) { # Overwrite
			${$self->{'stored_secs'}}{$tpattern} = render_file($self, $tpattern);
			return;
		}
		
		return render_file($self, $tpattern); 
	}







	# Multiple file template handling


	# It's preloaded:

	if ( defined($self->{'preloaded'}{$tpattern}) ) {


		# Save section internally
		if ( defined($stor) and $stor eq 'a' ) { # Append
			
			${$self->{'stored_secs'}}{$tpattern} .=  
				$self->SUPER::render( 
					$self->{'preloaded'}{$tpattern}, $href, $self->{'delims'} );
			return;
		}


		# Overwrite
		if ( defined($stor) and $stor eq 's' ) { 
			${$self->{'stored_secs'}}{$tpattern} =  
				$self->SUPER::render( 
					$self->{'preloaded'}{$tpattern}, $href, $self->{'delims'} );		
			return;
		}


		# Return value
		return $self->SUPER::render( 
			$self->{'preloaded'}{$tpattern}, $href, $self->{'delims'} );

	}






	# Load template file from disk

	# Does file exist at our location?
	my $file;
	for( @{ $self->{'template_files'} } ) {		
		$file = $_ and last if /$tpattern/;
	}

	# If we've found it, render it
	if (defined($file)) {
		my $t;
		open(F, $file) or die "Couldn't open $file $!";
		while(<F>) { $t .= $_; }
		close(F);


		# Save section internally
		if ( defined($stor) and $stor eq 'a' ) { # Append
			${$self->{'stored_secs'}}{$t} .=  
				$self->SUPER::render( $t, $href, $self->{'delims'} );
			return;
		}

		# Overwrite
		if ( defined($stor) and $stor eq 's' ) { 
			${$self->{'stored_secs'}}{$t} =  
				$self->SUPER::render( $t, $href, $self->{'delims'} );
			return;
		}		

		# Otherwise...
		return $self->SUPER::render( $t, $href, $self->{'delims'} );

	}


} # render()




# Handles rendering when template is stored in single, sectioned template file

sub render_file {

	my ( $self, $tpattern, $hash_ref ) = @_;

	my $retval;


	# Handle section pattern delimiters if they are defined

	if ( ref($self->{'secpat_delims'}) ) {
		$tpattern = 
			${$self->{'secpat_delims'}}[0] . $tpattern .
			${$self->{'secpat_delims'}}[1];
	}

	my @template_secs = @{ $self->{'template_secs'} };


	for ( my $i=0; $i<$#template_secs; $i++ ) {


		
		if ( $template_secs[$i] =~ /$tpattern/ ) {

			return $template_secs[$i+1] if ( not ref($hash_ref) ); # Return template untouched

			$retval = $template_secs[$i+1]; # Make copy -- necessary

			return $self->SUPER::render( $retval, $hash_ref, $self->{'delims'} );	
			
		}

	}


	return;

} # render_file()





# Preload template in memory (template sections in multiple files only)

sub preload {

	my ($self, $tpattern) = @_;
	
	return if not defined($tpattern) or $self->{'is_file_template'} == 1;

	# Get the appropriate file
	my $file;
	for( @{ $self->{'template_files'} } ) {
		$file = $_ and last if /$tpattern/;
	}


	if (defined($file)) {
		my $t;
		
		open(F, $file) or die "Couldn't open $file $!";
		while(<F>) { $t .= $_; }
		close(F);

		$self->{'preloaded'}{$tpattern} = $t;

	}


	return;
	
} # preload()



# Remove template from memory (multiple file templates only)

sub unload {
		my ($self, $tpattern) = @_;
		delete $self->{'preloaded'}{$tpattern};
}





# Load the single file template into array of sections

sub init_file_template {

	my $self = shift;

	my $t;
	open(F, $self->{'template_path'}) or die "Couldn't open $self->{'template_path'} $!";
	while(<F>) { $t .= $_; }
	close(F);

	$self->{'template_secs'} = [ split( /($self->{'template_secpat'})/, $t ) ];


} # init_file_template()





# Handle template passed by user as string

sub init_template_str {

	my $self = shift;
	$self->{'template_secs'} = 
		[ 
		split( /($self->{'template_secpat'})/, $self->{'template_str'} ) 
		];

	shift(@{$self->{'template_secs'}});
	$self->{'is_file_template'} = 1; # render_file() will process this 
	
}






# Set trim flags
sub trim {
	my ($self, $flag) = @_;



	# trim() with no params defaults to trimming both ends
	if (!defined($flag)) {
		$self->{'trim'} = 'both';
		return;
	}


	
	# Turn trimming off
	if ($flag =~ /^(off|o)$/i) {
		$self->{'trim'} = undef;
		return;
	}

	
	# Make sure we get something valid
	if ($flag !~ /^(off|left|right|both|l|r|b|o)$/i) {
		$self->{'trim'} = undef;
		return;
	}


	$self->{'trim'} = $flag;
	return;


} # trim()





sub assemble {
	my $self = shift;
	my $aref = shift;
	my $clear = shift;

	# Make sure we get an array reference
	return if !ref($aref);

	# Must not be empty
	return if !keys %{ $self->{'stored_secs'} };

	my $ret;
	for (@{$aref}) {
		$ret .= ${ $self->{'stored_secs'} }{$_};
	}

	# Clear the hash
	$self->{'stored_secs'} = {} if defined($clear);

	return $ret;
} # assemble()




1;


__END__

=head1 NAME

Template::Recall - "Reverse callback" templating system


=head1 SYNOPSIS
	
	use Template::Recall;

	# Load template sections from file

	my $tr = Template::Recall->new( template_path => '/path/to/template/sections' );

	# Or, use single file, with sections marked
	# my $tr = Template::Recall->new( template_path => '/path/to/template_file.html' );


	my @prods = (
		'soda,sugary goodness,$.99', 
		'energy drink,jittery goodness,$1.99',
		'green tea,wholesome goodness,$1.59'
		);

	$tr->render('header');

	# Load template into memory

	$tr->preload('prodrow');
							
	for (@prods) 
	{
		my %h;
		my @a = split(/,/, $_);

		$h{'product'} = $a[0];
		$h{'description'} = $a[1];
		$h{'price'} = $a[2];

		print $tr->render('prodrow', \%h);
	}

	# Remove template from memory

	$tr->unload('prodrows');

	print $tr->render('footer');

=head1 DESCRIPTION	

Template::Recall works using what I call a "reverse callback" approach. A "callback" templating system (i.e. Mason, Apache::ASP) generally includes template markup and code in the same file. The template "calls" out to the code where needed. Template::Recall works in reverse. Rather than inserting code inside the template, the template remains separate, but broken into sections. The sections are called from within the code at the appropriate times.

A template section is merely a file on disk (or a "marked" section in a single file). For instance, 'prodrow' above (actually F<prodrow.html> in the template directory), might look like

	<tr>
		<td>[' product ']</td>
		<td>[' description ']</td>
		<td>['price']</td>
	</tr>

The C<render()> method is used to "call" back to the template sections. Simply create a hash of name/value pairs that represent the template tags you wish to replace, and pass a reference of it along with the template section, i.e.

	$tr->render('prodrow', \%h);

=head1 METHODS

=head3 C<new( [ template_path =E<gt> $path, flavor =E<gt> $template_flavor, secpat =E<gt> $section_pattern, delims =E<gt> ['opening', 'closing'] ] )>

Instantiates the object. If you do not specify C<template_path>, it will assume
templates are in the directory that the script lives in. If C<template_path>
points to a file rather than a directory, it loads all the template sections
from this file. The file must be sectioned using the "section pattern", which
can be adjusted via the C<secpat> parameter.

C<flavor> is a pattern to specify what type of template to load. This is C</html$|htm$/i> by default, which picks up HTML file extensions. You could set it to C</xml$/i>, for instance, to get *.xml files.

C<secpat>, by default, is C<[\s*=+\s*\w+\s*=+\s*]/>. So if you put all your template sections in one file, the way Template::Recall knows where to get the sections is via this pattern, e.g.

	[ ==================== header ==================== ]
	<html
		<head><title>Untitled</title></head>
	<body>

	<table>

	[ ==================== prodrow ==================== ]
	<tr>
		<td>[' product ']</td>
		<td>[' description ']</td>
		<td>[' price ']</td>
	</tr>
	
	[==================== footer ==================== ]
	
	</table>

	</body>
	</html>

You may set C<secpat> to any pattern you wish. Note that if you use delimiters (i.e. opening and closing symbols)
for the section pattern, you will also need to set the C<secpat_delims>
parameter to those delimiters. So if you had set C<secpat> to that above, you
would need also need to set C<secpat_delims =E<gt> [ '[\s*=+\s*', '\s*=+\s*]' ]>. If you decide to not use delimiters, and use something like C<secpat =E<gt> qr/MYTEMPLATE_SECTION_\w+/>, then you must set C<secpat_delims =E<gt> 'no'>.

The default delimeters for variables in Template::Recall are C<['> (opening) and
C<']> (closing). This tells Template::Recall that C<[' price ']> is different from "price" in the same template, e.g.

	What is the price? It's [' price ']

You can change C<delims> by passing a two element array to C<new()> representing
the opening and closing delimiters, such as C<delims =E<gt> [ 'E<lt>%', '%E<gt>' ]>. If you don't want to use delimiters at all, simply set C<delims =E<gt> 'none'>.

The C<template_str> parameter allows you to pass in a string that contains the template data, instead of reading it from disk:

C<new( template_str =E<gt> $str )>

For example, this enables you to store templates in the C<__DATA__> section of the calling script

=head3 C<render( $template_pattern [, $store, $reference_to_hash ] );>

You must specify C<$template_pattern>, which tells C<render()> what template "section" to load. C<$reference_to_hash> is optional. Sometimes you just want to return a template section without any variables. Usually, C<$reference_to_hash> will be used, and C<render()> iterates through the hash, replacing the F<key> found in the template with the F<value> associated to F<key>. A reference was chosen for efficiency. The hash may be large, so either pass it using a backslash like in the synopsis, or do something like C<$hash_ref = { 'name' =E<gt> 'value' }> and pass C<$hash_ref>.

The other optional argument C<$store> must either be the string "a" or the
string "s", for "append" or "store", respectively. This tells C<render()> that
you want the rendered section to internal storage, until the call to
C<assemble()> is made (see below). It's not always expedient to render a section
immediately when you invoke C<render()>. Here's how to save the rows from the
synopsis loop above:

        for (@prods) 
        {
            # ... etc ...

            $tr->render('prodrow', 'a', \%h);
        }

To replace an internally rendered section instead of appending to it, change "a" to "s":

        $tr->render('section', 's', \%h);

Use C<assemble()> below to arrange the sections you want and output.

=head3 C<preload( $template_pattern );>

In the loop over C<@prods> in the synopsis, the 'prodrow' template is being accessed multiple times. If the section is stored in a file, i.e. F<prodrow.html>, you have to read from the disk every time C<render()> is called. C<preload()> allows you to load a template section file into memory. Then, every time C<render()> is called, it pulls the template from memory rather than disk. This does not work for single file templates, since they are already loaded into memory.

=head3 C<unload( $template_pattern );>

When you are finished with the template, free up the memory.

=head3 C<trim( 'off|left|right|both' );>

You may want to control whitespace in your section output. You could use 
C<s///> on the returned text, of course, but C<trim()>is included for convenience 
and clarity. Simply pass the directive you want when you call it, e.g.

	$tr->trim('right');
	print $tr->render('sec1', \%values);
	$tr->trim('both')
	print $tr->render('sec2', \%values2);
	$tr->trim('off');
	# ...etc...

If you just do

	$tr->trim();

it will default to trimming both ends of the template. Note that you can also
use abbreviations, i.e. C<$tr-E<gt>trim( 'o|l|r|b' )> to save a few keystrokes.

=head3 C<assemble( $array_ref [, 'clear'] )>

If you have stored any sections internally using the "a" or "s" directives to
C<render()>, this method is used to return those sections. Pass in a reference
to an array that contains the section names you want returned, e.g.

	print $tr->assemble( [ 'section1', 'section2', 'section3' ] );

This also gives you some flexibility, for instance, you could just as easily
reverse the sections like

	print $tr->assemble( [ 'section3', 'section2', 'section1' ] );

Since internal storage causes memory to be used, you will probably at some point
want to remove all the stored sections. Do this with the C<'clear'> parameter.
For instance,

	print $tr->assemble( [ 'section1', 'section2' ], 'clear' );

will return the sections, and immediately remove them from internal storage.

=head1 AUTHOR

James Robson E<lt>info F<AT> arbingersys F<DOT> comE<gt>

=head1 SEE ALSO

http://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html
