package Gnucash::Transaction::Split;

use strict;
use warnings;

sub from_xml {
	my ($node, $accounts) = @_;

	my $ret = {};
	
	foreach my $n ($node->content_list) {
		if(ref($n)) {
			my $done = 0;
			foreach my $attr (qw/reconciled-state value quantity memo/) {
				if($n->tag eq "split:$attr") {
					$ret->{$attr} = ($n->content_list)[0];
					$done = 1;
				}
			}
			next if($done);
			if($n->tag eq 'split:id') {
				my $type = $n->attr('type');
				die "unknown ID type $type" unless $type eq 'guid';
				$ret->{id} = ($n->content_list)[0];
			} elsif($n->tag eq 'split:account') {
				my $type = $n->attr('type');
				die "unknown acct ID type $type" unless $type eq 'guid';
				$ret->{account} = $accounts->{($n->content_list)[0]};
				die "unknown account" unless defined($ret->{account});
			} else {
				die "unknown slot tag " . $n->tag;
			}
		}
	}

	return bless($ret, 'Gnucash::Transaction::Split');
}

sub to_xml {
	my ($self) = @_;

	my $ret = XML::Element->new('trn:split');
	$ret->push_content("\n      ");
	$ret->push_content(XML::Element->new('split:id', 'type', 'guid')->
		push_content($self->{id}));
	
	if(exists($self->{memo})) {
		$ret->push_content("\n      ");
		$ret->push_content(XML::Element->new('split:memo')->
			push_content($self->{memo}));
	}

	foreach my $attr qw/reconciled-state value quantity/ {
		$ret->push_content("\n      ");
		$ret->push_content(XML::Element->new("split:$attr")->
			push_content($self->{$attr}));
	}

	$ret->push_content("\n      ");
	$ret->push_content(XML::Element->new('split:account', 'type', 'guid')->
		push_content($self->{account}->{id}));

	$ret->push_content("\n    ");

	return $ret;
}

1;
