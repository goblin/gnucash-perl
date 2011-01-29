package Gnucash::File;

use strict;
use warnings;

use XML::TreeBuilder;
use XML::Element;
use Gnucash::Book;
use Data::Dumper;

sub _get_guid {
	my ($node) = @_;
	
	my $type = $node->attr('type');
	die "unknown ID type ". $type if($type ne 'guid');

	return ($node->content_list)[0];
}

sub load {
	my ($filename) = @_;

	my $tree = XML::TreeBuilder->new();
	$tree->parse_file($filename);

	die "unsupported root node ". $tree->tag if($tree->tag ne 'gnc-v2');

	# iterate through books
	my @books;
	foreach my $node ($tree->content_list) {
		if(ref($node)) {
			next if($node->tag eq 'gnc:count-data'); # just ignore these
			die "unknown 2nd level node " . $node->tag
				if($node->tag ne 'gnc:book');
			push @books, Gnucash::Book::from_xml($node);
		}
	}

	return bless({
		name => $filename,
		books => \@books,
	}, 'Gnucash::File');
}

sub save {
	my ($self, $filename) = @_;
	my @nss = qw/ gnc act book cd cmdty price slot split sx trn ts
		fs bgt recurrence lot job invoice addr cust billterm bt-days
		bt-prox taxtable tte order employee entry owner vendor /;
	my @namespaces = map { ("xmlns:$_" => "http://www.gnucash.org/XML/$_"); } 
		@nss;

	$filename ||= $self->{name};

	my $root = XML::Element->new('gnc-v2', @namespaces);
	$root->push_content("\n");
	my $cnt = XML::Element->new('gnc:count-data', 'cd:type', 'book');
	$cnt->push_content(scalar(@{$self->{books}}));
	$root->push_content($cnt);
	$root->push_content("\n");
	foreach my $book (@{$self->{books}}) {
		$root->push_content($book->to_xml);
	}
	$root->push_content("\n");

	print '<?xml version="1.0" encoding="utf-8" ?>', "\n";
	print $root->as_XML;
}

1;
