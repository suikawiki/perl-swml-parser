use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::Differences;
use Test::HTCT::Parser;
use Test::X1;
use SWML::Parser;
use Web::DOM::Document;
use Web::HTML::Dumper qw/dumptree/;

$Web::HTML::Dumper::NamespaceMapping->{q<urn:x-suika-fam-cx:markup:suikawiki:0:9:>} = 'sw';
$Web::HTML::Dumper::NamespaceMapping->{q<urn:x-suika-fam-cx:markup:suikawiki:0:10:>} = 'sw10';

my $test_data_path = path (__FILE__)->parent->parent->child ('t_deps/tests/swml/parsing');

for my $path ($test_data_path->children (qr/\.dat$/)) {
  for_each_test ($path, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    document => {is_prefixed => 1},
  }, sub {
    my $test = shift;
    warn "No #errors section ($test->{data}->[0])" unless $test->{errors};
    test {
      my $c = shift;

      my $doc = new Web::DOM::Document;
      my @errors;
      my $onerror = sub {
        my %opt = @_;
        push @errors, join ';',
            $opt{token}->{line} || $opt{line},
            $opt{token}->{column} || $opt{column},
            $opt{type},
            defined $opt{text} ? $opt{text} : '',
            defined $opt{value} ? $opt{value} : '',
            $opt{level};
      }; # $onerror

      my $p = SWML::Parser->new;
      $p->onerror ($onerror);
      $p->parse_char_string ($test->{data}->[0] => $doc);
      my $result = dumptree ($doc);

      @errors = sort {$a cmp $b} @errors;
      @{$test->{errors}->[0]} = sort {$a cmp $b} @{$test->{errors}->[0] ||= []};
      eq_or_diff \@errors, $test->{errors}->[0], 'Parse errors';

      $test->{document}->[0] .= "\x0A" if length $test->{document}->[0];
      eq_or_diff $result, $test->{document}->[0], 'Document tree';

      done $c;
    } n => 2, name => [$path->relative ($test_data_path), $test->{data}->[0]];
  });
} # $path

run_tests;

## License: Public Domain.
