#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;

my $README = 'README.md';
my $filename = $ARGV[0];
my $version = $ARGV[1];

my %fields = (

	# announcement 	optional 	8192
	# This field contains the text for the announcement on the CTAN mailing
	# list. If no text is present then no announcement will be sent.
	'announcement' => '',

	# author 	mandatory 	128
	# This field contains the name or the names of the authors. Several authors
	# can be separated by semicolon or several author fields can be specified.
	'author' => 'Alex Hirzel',

	# bugtracker 	optional 	255
	# This field contains the URL of the bug tracker for the package.
	'bugtracker' => 'http://github.com/alhirzel/ajhresume/issues',

	# ctanPath 	optional 	64
	# This field contains the proposed path in the CTAN archive. This is the
	# part after /tex-archive when browsing the archive in the Web portal.
	'ctanPath' => 'macros/latex/contrib/ajhresume',

	# description 	mandatory 	4096
	# This field contains an abstract description of the package.
	'description' => 'TODO',

	# email 	mandatory 	255
	# This field contains the email address of the uploader.
	'email' => 'alex@hirzel.us',

	# home 	optional 	255
	# The value of this field is the URL of the package's home page.
	'home' => 'http://github.com/alhirzel/ajhresume',

	# license 	mandatory 	64
	# This field contains the licenses associated with the package or parts
	# thereof. This field may be given several times to pass in several
	# licenses.
	'license' => 'mit',

	# mailinglist 	optional 	255
	# This field contains the URL of the mailing list of the package.
	'mailinglist' => '',

	# note 	optional 	2048
	# This field contains a note to the upload managers on CTAN. Any additional
	# information which is useful for processing the upload or categorizing the
	# package can be given here. The text is for communication purposes only. It
	# is not shown publicly.
	'note' => '',

	# pkg 	mandatory 	32
	# This field contains the name of the package. It consists of lower case
	# letters, digits, the minus sign, or the underscore. The first character
	# must be a lower-case letter.
	'pkg' => 'ajhresume',

	# repository 	optional 	255
	# This field contains the URL of the package's repository.
	'repository' => 'http://github.com/alhirzel/ajhresume',

	# summary 	mandatory 	128
	# This field contains a short one-line description of the package.
	'summary' => 'A judicious, hard-working resume document class based on memoir',

	# topic 	optional 	1024
	# This field contains the classification into topics of the catalogue.
	# Several topics can be specified. The values returned by JSON List of
	# Topics or XML List of Topics can be given as values. Other values are
	# reported as warning. They have to be processed manually by a CTAN upload
	# manager. <https://ctan.org/xml/1.3/topics>
	'topic' => 'cv',

	# update 	mandatory 	8
	# This field contains the value true if the package already exists on CTAN
	# and false if it is a new package.
	'update' => 'false',

	# uploader 	mandatory 	255
	# This field contains the name of the uploader. The uploader can be
	# different from the author. In this case he needs to be permitted by an
	# author to do so.
	'uploader' => 'Alex Hirzel',

	# version 	mandatory 	32
	# This field contains the version number of the package. No numbering scheme
	# is imposed. An updated package must just have a different version number
	# than the current version on CTAN.
	#'version' => trim(`make print-version`),
	'version' => trim($version),
);

print(Dumper(\%fields));

%fields = (%fields, ('file' => [$filename]));

my $userAgent = LWP::UserAgent->new();
my $response = $userAgent->post('https://www.ctan.org/submit/validate', \
	%fields, 'Content_Type' => 'form-data');

# 200	This status code indicates success. The return value is a list in JSON
# 		notation which contains the warning and info items.
# 404	This status code indicates that an invalid request has been made. This
# 		can be caused by an invalid version number of the API or an invalid
# 		service method. The return body may contain further details.
# 409	This status code indicates that some inconsistencies have been found in
# 		the data or a technical error has occurred. The return body contains a
# 		list in JSON notation with the error, warning and info items.
# 500	This status code indicates an internal server error.

my $retCode = $response->code();
my $retContent = $response->decoded_content();

if (200 == $retCode) {
	print("no errors found\n");
	exit 0;
} else {
	print("JSON response (with code=$retCode)\n");
	print($retContent);
	exit 1;
}

sub trim {
	(my $s = $_[0]) =~ s/^\s+|\s+$//g;
	return $s;
}

