package Gnucash::Slot;

use strict;
use warnings;

use XML::Element;

sub from_xml {
	my ($node) = @_;

	my $ret = {};
	
	foreach my $n ($node->content_list) {
		if(ref($n)) {
			if($n->tag eq 'slot:key') {
				$ret->{key} = ($n->content_list)[0];
			} elsif($n->tag eq 'slot:value') {
				$ret->{value} = ($n->content_list)[0];
				$ret->{type} = $n->attr('type');
			} else {
				die "unknown slot tag " . $n->tag;
			}
		}
	}

	return bless($ret, 'Gnucash::Slot');
}

sub to_xml {
	my ($self) = @_;

	my $ret = XML::Element->new('slot');
	$ret->push_content("\n      ");
	$ret->push_content(XML::Element->new('slot:key')->push_content(
		$self->{key}));
	$ret->push_content("\n      ");
	$ret->push_content(XML::Element->new('slot:value', 'type', 
		$self->{type})->push_content($self->{value}));
	$ret->push_content("\n    ");

	return $ret;
}

1;
