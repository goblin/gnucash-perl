package Gnucash::Date;

use strict;
use warnings;

use XML::TreeBuilder;

sub from_xml {
	my ($node) = @_;

	my $ret = {};

	foreach my $n ($node->content_list) {
		if(ref($n)) {
			if($n->tag eq 'ts:date') {
				$ret->{date} = ($n->content_list)[0];
			} elsif($n->tag eq 'ts:ns') {
				$ret->{ns} = ($n->content_list)[0];
			} else {
				die "unknown timestamp tag " . $n->tag;
			}
		}
	}

	return bless($ret, 'Gnucash::Date');
}

sub to_xml {
	my ($self, $in) = @_;

	$in->push_content("\n    ");
	$in->push_content(XML::Element->new('ts:date')->push_content(
		$self->{date}));
	if(exists($self->{ns})) {
		$in->push_content("\n    ");
		$in->push_content(XML::Element->new('ts:ns')->push_content(
			$self->{ns}));
	}
	$in->push_content("\n  ");

	return $in;
}

1;
