package Gnucash::Transaction;

use strict;
use warnings;

use XML::TreeBuilder;
use XML::Element;
use Gnucash::Commodity;
use Gnucash::Date;
use Gnucash::Slot;
use Gnucash::Transaction::Split;

sub from_xml {
	my ($node, $commodities, $accounts) = @_;

	my $ret = {};

	foreach my $n ($node->content_list) {
		if(ref($n)) {
			my $done = 0;
			foreach my $attr (qw/num description/) {
				if($n->tag eq "trn:$attr") {
					$ret->{$attr} = ($n->content_list)[0];
					$done = 1;
				}
			}
			next if($done);
			if($n->tag eq 'trn:id') {
				my $type = $n->attr('type');
				die "unknown ID type $type" unless $type eq 'guid';
				$ret->{id} = ($n->content_list)[0];
			} elsif($n->tag eq 'trn:currency') {
				my $id = Gnucash::Commodity::identify($n);
				$ret->{currency} = $commodities->{$id};
				die "unknown currency $id" unless(defined($ret->{currency}));
			} elsif($n->tag =~ /^trn:date-(entered|posted)$/) {
				$ret->{"date-$1"} = Gnucash::Date::from_xml($n);
			} elsif($n->tag eq 'trn:slots') {
				$ret->{slots} = [];
				foreach my $slot ($n->content_list) {
					if(ref($slot)) {
						die "unknown slot tag " . $slot->tag
							unless $slot->tag eq 'slot';
						push @{$ret->{slots}}, Gnucash::Slot::from_xml($slot);
					}
				}
			} elsif($n->tag eq 'trn:splits') {
				$ret->{splits} = [];
				foreach my $split ($n->content_list) {
					if(ref($split)) {
						die "unknown split tag " . $split->tag
							unless $split->tag eq 'trn:split';
						push @{$ret->{splits}}, 	
							Gnucash::Transaction::Split::from_xml(
								$split, $accounts);
					}
				}
			} else {
				die "unknown transaction tag " . $n->tag;
			}
		}
	}
	
	return bless($ret, 'Gnucash::Transaction');
}

sub to_xml {
	my ($self) = @_;

	my $ret = XML::Element->new('gnc:transaction', 'version', '2.0.0');
	$ret->push_content("\n  ");
	$ret->push_content(XML::Element->new('trn:id', 'type', 'guid')->
		push_content($self->{id}));
	$ret->push_content("\n  ");
	$ret->push_content($self->{currency}->short_to_xml(
		XML::Element->new('trn:currency')));

	if(exists($self->{num})) {
		$ret->push_content("\n  ");
		$ret->push_content(XML::Element->new('trn:num')->
			push_content($self->{num}));
	}
	
	$ret->push_content("\n  ");
	$ret->push_content($self->{'date-posted'}->to_xml(
		XML::Element->new('trn:date-posted')));
	$ret->push_content("\n  ");
	$ret->push_content($self->{'date-entered'}->to_xml(
		XML::Element->new('trn:date-entered')));
	$ret->push_content("\n  ");
	$ret->push_content(XML::Element->new('trn:description')->
		push_content($self->{description}));

	if(exists($self->{slots})) {
		$ret->push_content("\n  ");
		my $slots = XML::Element->new('trn:slots');
		foreach my $slot (@{$self->{slots}}) {
			$slots->push_content("\n    ");
			$slots->push_content($slot->to_xml);
		}
		$slots->push_content("\n  ");
		$ret->push_content($slots);
	}

	my $splits = XML::Element->new('trn:splits');
	foreach my $split (@{$self->{splits}}) {
		$splits->push_content("\n    ");
		$splits->push_content($split->to_xml);
	}
	$splits->push_content("\n  ");
	$ret->push_content("\n  ");
	$ret->push_content($splits);
	
	$ret->push_content("\n");

	return $ret;
}

1;
