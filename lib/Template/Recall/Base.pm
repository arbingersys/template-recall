package Template::Recall::Base;

use strict;
no warnings;


our $VERSION='0.06'; 


sub render {

	my ( $class, $template, $hash_ref, $delims ) = @_;

	if ( not defined ($template) ) { return "Template::Recall::Base::render() 'template' parameter not present"; }

	if ( ref($hash_ref) ) {

		foreach my $k ( keys %{$hash_ref} ) {

			# $delims must be 2 element array reference
			if ( ref($delims) and $#{$delims} == 1 ) {	
				my $r = ${$delims}[0] . '\s*' . $k . '\s*' . ${$delims}[1];
				$template =~ s/$r/${$hash_ref}{$k}/g;
			}
			else {
				$template =~ s/$k/${$hash_ref}{$k}/g;
			}
			
		} # foreach
	
	} # if


	# Do trimming, if so flagged
	return trim($class->{'trim'}, $template) if defined($class->{'trim'});


	return $template;

} # render()




# Trim output if directed to do so

sub trim {
	my ($trim, $template) = @_;

	return $template if !defined($trim);

	if ($trim eq 'left' or $trim eq 'l') {
		$template =~ s/^\s+//g;
		return $template;
	}

	if ($trim eq 'right' or $trim eq 'r') {
		$template =~ s/\s+$//g;
		return $template;
	}

	if ($trim eq 'both' or $trim eq 'b') {
		$template =~ s/^\s+|\s+$//g;
		return $template;	
	}


} # trim()


1;
