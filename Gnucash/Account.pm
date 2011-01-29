package Gnucash::Account;

use strict;
use warnings;

use XML::TreeBuilder;
use Gnucash::Commodity;
use Gnucash::Slot;

sub from_xml {
	my ($node, $commodities, $accounts) = @_;

	my $ret = {};
	foreach my $n ($node->content_list) {
		if(ref($n)) {
			my $done = 0;
			foreach my $attr (qw/name type commodity-scu description/) {
				if($n->tag eq "act:$attr") {
					$ret->{$attr} = ($n->content_list)[0];
					$done = 1;
				}
			}
			next if($done);
			if($n->tag eq 'act:id') {
				my $type = $n->attr('type');
				die "unknown ID type $type" unless $type eq 'guid';
				$ret->{id} = ($n->content_list)[0];
			} elsif($n->tag eq 'act:commodity') {
				my $id = Gnucash::Commodity::identify($n);
				$ret->{commodity} = $commodities->{$id};
				die "unknown commodity $id" 
					unless(defined($ret->{commodity}));
			} elsif($n->tag eq 'act:parent') {
				my $type = $n->attr('type');
				die "unknown parent type $type" unless $type eq 'guid';
				$ret->{parent} = $accounts->{($n->content_list)[0]};
				die "weird parent" unless(defined($ret->{parent}));
			} elsif($n->tag eq 'act:slots') {
				$ret->{slots} = [];
				foreach my $slot ($n->content_list) {
					if(ref($slot)) {
						die "unknown slot tag " . $slot->tag
							unless $slot->tag eq 'slot';
						push @{$ret->{slots}}, Gnucash::Slot::from_xml($slot);
					}
				}
			} else {
				die "unknown account tag " . $n->tag;
			}
		}
	}

	if($ret->{type} eq 'ROOT') {
		$ret->{level} = 0;
	} else {
		$ret->{level} = $ret->{parent}->{level} + 1;
	}

	return bless($ret, 'Gnucash::Account');
}

sub to_xml {
	my ($self) = @_;

	my $ret = XML::Element->new('gnc:account', 'version', '2.0.0');
	$ret->push_content("\n  ");
	$ret->push_content(XML::Element->new('act:name')->push_content(
		$self->{name}));
	$ret->push_content("\n  ");
	$ret->push_content(XML::Element->new('act:id', 'type', 'guid')->
		push_content($self->{id}));
	$ret->push_content("\n  ");
	$ret->push_content(XML::Element->new('act:type')->
		push_content($self->{type}));
	if(exists($self->{commodity})) {
		$ret->push_content("\n  ");
		$ret->push_content($self->{commodity}->short_to_xml(
			XML::Element->new('act:commodity')));
	}
	if(exists($self->{'commodity-scu'})) {
		$ret->push_content("\n  ");
		$ret->push_content(XML::Element->new('act:commodity-scu')->
			push_content($self->{'commodity-scu'}));
	}

	if(exists($self->{description})) {
		$ret->push_content("\n  ");
		$ret->push_content(XML::Element->new('act:description')->push_content(
			$self->{description}));
	}
	
	if(exists($self->{slots})) {
		$ret->push_content("\n  ");
		my $slots = XML::Element->new('act:slots');
		foreach my $slot (@{$self->{slots}}) {
			$slots->push_content("\n    ");
			$slots->push_content($slot->to_xml);
		}
		$slots->push_content("\n  ");
		$ret->push_content($slots);
	}

	if(exists($self->{parent})) {
		$ret->push_content("\n  ");
		$ret->push_content(XML::Element->new('act:parent', 'type', 'guid')->
			push_content($self->{parent}->{id}));
	}

	$ret->push_content("\n");

	return $ret;
}

1;
