#! /usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Gnucash::File;

my $gnc_file = Gnucash::File::load($ARGV[0]);

$gnc_file->save;

print "\n";

