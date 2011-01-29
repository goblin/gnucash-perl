package Gnucash::Commodity;

use strict;
use warnings;

use XML::TreeBuilder;

sub from_xml {
	my ($node) = @_;

	my $ret = {};
	foreach my $n ($node->content_list) {
		if(ref($n)) {
			if($n->tag =~ /^cmdty:(.*)$/) {
				$ret->{$1} = ($n->content_list)[0];
			} else {
				die "unknown namespace in commodity: ".$n->tag;
			}
		}
	}

	return bless($ret, 'Gnucash::Commodity');
}

sub identify {
	my ($n) = @_;
				
	my ($space, $id);

	foreach my $subtag ($n->content_list) {
		if(ref($subtag)) {
			if($subtag->tag eq 'cmdty:space') {
				$space = ($subtag->content_list)[0];
			} elsif($subtag->tag eq 'cmdty:id') {
				$id = ($subtag->content_list)[0];
			} else {
				die "unknown comodity " . $subtag->tag .
					" in acct";
			}
		}
	}

	return $space .'::'. $id;
}

sub to_xml {
	my ($self) = @_;

	my $ret = XML::Element->new('gnc:commodity', 'version', '2.0.0');
	$ret->push_content("\n");

	foreach my $k (qw/space id get_quotes quote_source quote_tz/) {
		$ret->push_content("  ");
		$ret->push_content(XML::Element->new("cmdty:$k")->push_content(
			$self->{$k}));
		$ret->push_content("\n");
	}

	return $ret;
}

sub short_to_xml {
	my ($self, $in) = @_;

	$in->push_content("\n    ");
	$in->push_content(XML::Element->new("cmdty:space")->push_content(
		$self->{space}));
	$in->push_content("\n    ");
	$in->push_content(XML::Element->new("cmdty:id")->push_content(
		$self->{id}));
	$in->push_content("\n  ");

	return $in;
}

1;
