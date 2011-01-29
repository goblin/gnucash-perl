package Gnucash::Book;

use strict;
use warnings;

use XML::TreeBuilder;
use XML::Element;
use Gnucash::File;
use Gnucash::Commodity;
use Gnucash::Account;
use Gnucash::Transaction;

sub _check_ver {
	my ($node) = @_;

	my $ver = $node->attr('version');
	die "unsupported version $ver of tag " . $node->tag
		unless $ver eq '2.0.0';
}

sub from_xml {
	my ($book) = @_;
	
	my $ret = {
		commodities => {},
		accounts => {},
		transactions => [],
		acct_tree => [],
	};

	foreach my $node ($book->content_list) {
		if(ref($node)) {
			if($node->tag eq 'book:id') {
				die "multiple IDs?" if(exists $ret->{id});
				$ret->{id} = Gnucash::File::_get_guid($node);
			} elsif($node->tag eq 'gnc:count-data') {
				# just ignore these
			} elsif($node->tag eq 'gnc:commodity') {
				_check_ver($node);
				die "commodity specified after account"
					if(scalar(keys %{$ret->{accounts}}) > 0);
				my $cmdty = Gnucash::Commodity::from_xml($node);
				$ret->{commodities}->{$cmdty->{space}.'::'.$cmdty->{id}} =
					$cmdty;
			} elsif($node->tag eq 'gnc:account') {
				_check_ver($node);
				die "account specified after transaction"
					if(scalar(@{$ret->{transactions}}) > 0);
				my $act = Gnucash::Account::from_xml($node, 
					$ret->{commodities}, $ret->{accounts});
				$ret->{accounts}->{$act->{id}} = $act;
				$ret->{acct_tree}->[$act->{level}] ||= [];
				push @{$ret->{acct_tree}->[$act->{level}]}, $act;
			} elsif($node->tag eq 'gnc:transaction') {
				_check_ver($node);
				my $trn = Gnucash::Transaction::from_xml($node,
					$ret->{commodities}, $ret->{accounts});
				push @{$ret->{transactions}}, $trn;
			} else {
				die "unknown node in book: " . $node->tag;
			}
		}
	}

	return bless($ret, 'Gnucash::Book');

}

sub to_xml {
	my ($self) = @_;

	my $root = XML::Element->new('gnc:book', 'version' => '2.0.0');
	$root->push_content("\n");
	$root->push_content(XML::Element->new('book:id', 'type' => 'guid')->
		push_content($self->{id}));
	$root->push_content("\n");
	$root->push_content(XML::Element->new('gnc:count-data', 
		'cd:type' => 'account')->push_content(
			scalar(keys %{$self->{accounts}})));
	$root->push_content("\n");
	$root->push_content(XML::Element->new('gnc:count-data', 
		'cd:type' => 'transaction')->push_content(
			scalar(@{$self->{transactions}})));
	$root->push_content("\n");
	foreach my $k (keys %{$self->{commodities}}) {
		$root->push_content($self->{commodities}->{$k}->to_xml);
		$root->push_content("\n");
	}
	foreach my $lvl (@{$self->{acct_tree}}) {
		foreach my $acct (@$lvl) {
			$root->push_content($acct->to_xml);
			$root->push_content("\n");
		}
	}
	foreach my $tx (@{$self->{transactions}}) {
		$root->push_content($tx->to_xml);
		$root->push_content("\n");
	}

	return $root;
}

1;
