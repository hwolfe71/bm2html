#!/usr/bin/perl -s
#
# File:
#	bm2html.pl
#
# Version:
#	1.0 - June 15, 2000
#	2.0 - August 05, 2000
#	2.1 - August 24, 2000
#	3.0 - November 03, 2001 (never released)
#	3.1 - March 23, 2002
#	3.2 - September 2003
#
# Author:
#	Herb Wolfe, Jr.
#	hwolfe@inetnebr.com
#	http://incolor.inetnebr.com/hwolfe/
#	http://incolor.inetnebr.com/hwolfe/computer/mysoftware/bm2html
#
# Description:
#	This program strips Netscape's extra tags from a bookmark file and 
#	creats a links.html file from the output. It also provides options 
#	to create a yahoo-like group of pages, or a main links.html	file 
#	and links to separate files for each top level folder.
#
#	It is best run in a temp directory, so the files can be validated
#	and/or formatted before copying to the actual web directory. It does
#	produce valid HTML, according to both weblint and tidy. However, it
#	does not correct any errors already present, notable unescaped "&'s".
#
#	Also there is currently no ability to overwrite files.
#
#	See also the accompaning readme.txt
#
# Options:
#	-y: Create a yahoo-like directory
#	-o: Create one level of files
#	-x: Chop a 2nd trailng character, if using on dos/windows file
#	-css: Use an external stylesheet
#

# Initialize default values

$scriptname = "bm2html.pl";
$username = "Herb Wolfe";
$headerfile = "header.html";
$footerfile = "footer.html";
$defaultfile = "bookmark.htm";
$outfile = "links";
$ext = ".shtml";
$bgc = "white";
$textc = "black";
$linkc = "blue";
$vlinkc = "maroon";
$level = 0;

# Change to name of your style sheet
#$cssfile ="~hwolfe/mystyle.css";
$cssfile = $css;

# Check command line parameters

$y && $o && die ("-y and -o options can not be used together.\n");

# If file not specified, use $defaultfile

$infile = $ARGV[0] || $defaultfile;

die ("$infile not found.\n") unless ( -e $infile);

die ("$outfile$ext already exists\n") if ( -e $outfile.$ext) ;

# get footer
if ( -e $footerfile ) {
	open (FTR, $footerfile);
	@ftr = <FTR>;
} else {
	@ftr = ("</body>\n", "</html>\n");
}

open (IN, $infile ) || die ( "Error opening $infile: $!");

&ProcessBookMarks("", $outfile, $level);

close (IN);

#-------------------------------------------------

sub ProcessBookMarks {
	local ( $currdir, $oldtitle, $level ) = @_;
	local ( $newtitle ) = "";

	open (CURROUT, ">>$currdir$oldtitle$ext") || 
		die ("Error creating output file $currdir$oldtitle$ext\n");

	while ( <IN> ) {

# Skip the DOCTYPE, and header, since we print them elsewhere 
# Skip blank lines and lines with just <DD>

		next if ( ( /DOCTYPE/ ) || ( /<H1>/ ) || ( /^$/ ) || 
				( /^ *<DD> *$/ ) );

# Chop the trailing newline character(s).

		$x ? substr($_,-2) = '' : chop;

# Remove comments
		if ( /<!--/ ) {
			while ( ! /-->/ ) {
				$_ = <IN>;
			}
			next;
		}

# Print the title out

		if ( /TITLE/ ) {
			($title) = />([^<]+)</;
			&PrintHeader(CURROUT, $title);
			next;
		}

# Strip netscape's tags

		s/(A HREF="[^"]+")[^>]*/$1/;

# Convert the Definition Term tags to List Entry tags for better HTML

		s/<DT>/<LI>/;
		
# Strip <DD>, since we're converting to an unordered list

		s/<DD>//;

		if ( /<H3/ ) {

# Strip the netscape junk, and convert to <BIG> to fit in lists properly

			s/<H3[^>]+>/<H3>/;
			s/H3>/BIG>/g;

# Since we're here, check if we need to create subdirectories and/or files

			($newtitle) = />([^<]+)</;

# Replace all spaces and / with a single _ 

			$newtitle =~ tr# /#_#s;

# If yahoo option, or one-level option, and at the first level

			if ( ( $y ) || ( $o && ( $level == 1 ) ) ) {

# Create a file, and new directory if necessary,
# for "folders" and a link to the new file

				if ( $y ) {
					$newdir = "$currdir$newtitle/";
					printf CURROUT ("\t<LI><A HREF=\"%s/%s%s\">%s</a>\n",
						$newtitle, $newtitle, $ext, $newtitle);
				} else {
					$newdir = $currdir;
					printf CURROUT ("\t<LI><A HREF=\"%s%s%s\">%s</a>\n",
						$newdir, $newtitle, $ext, $newtitle);
				}

				close CURROUT;

				if ( $y ) {
					mkdir ($newdir, 0766) || 
						die ("Error creating directory $newdir\n");
				}
				open (NEWFILE, ">$newdir$newtitle$ext") ||
					die ("Error creating file $newdir$newtitle$ext\n");


				&PrintHeader(NEWFILE, $newtitle);
				close NEWFILE;
				&ProcessBookMarks($newdir, $newtitle, $level);
				open (CURROUT, ">>$currdir$oldtitle$ext");

			} else {
				print CURROUT "$_\n";
			}

		} else {

# Increment the level count because we have a new one
# Also convert the Definition List to an Unordered List 

			if ( /<DL>/ ) {
				$level++;
				s/( *)<DL><p>/$1<UL>/;
			}

# Decrement the level count when the end is reached
# Stop if the top level is reached, or if doing yahoo-style

			if ( m#</DL># ) {
				$level--;
				s#</DL><p>#</UL>#;
				if ( $y || ( $o && ($level <= 1) ) || ( $level == 0 ) ) {
					print CURROUT "$_\n@ftr";
					close CURROUT;
					last;
				}
			}
			print CURROUT "$_\n";
		}
	}
}

#-------------------------------------------------

sub PrintHeader {
	local( $OFILE, $title ) = @_;

	if ( -e $headerfile ) {
		open (HDR, $headerfile);
		@hdr = <HDR>;
		print $OFILE (@hdr);
		close HDR;
	} elsif ($css) {
		print $OFILE ("<!DOCTYPE HTML PUBLIC ".
			"\"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<HTML>\n");
	} else {
		print $OFILE ("<!DOCTYPE HTML PUBLIC ".
			"\"-//W3C//DTD HTML 3.2//EN\">\n<HTML>\n");
	}

# Add username to title
	$mytitle = "$title - $username";

# Print the title

	if ($css) {
		printf $OFILE ("<!-- This file generated by %s -->\n".
			"<HEAD>\n<TITLE>%s</TITLE>\n".
			"<meta http-equiv=\"Content-Type\" ".
			"content=\"text/html; charset=us-ascii\">\n".
			"<LINK REL=\"STYLESHEET\" HREF=\"$cssfile\" TYPE=\"TEXT/CSS\">\n".
			"</HEAD>\n<BODY>\n<H1>%s</H1>\n", 
			$scriptname, $mytitle, $title);
	} else { 
		printf $OFILE ("<!-- This file generated by %s -->\n".
			"<HEAD><TITLE>%s</TITLE></HEAD>\n".
			"<BODY BGCOLOR=%s TEXT=%s LINK=%s VLINK=%s>\n".
			"<H1 ALIGN="CENTER">%s</H1>\n", 
			$scriptname, $mytitle, $bgc, $textc, $linkc, $vlinkc, $title);
	}
}

