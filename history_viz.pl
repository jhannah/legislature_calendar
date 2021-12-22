#! env perl
use Modern::Perl;
use Text::CSV_XS;
no warnings "experimental";

my (%dates, $actions);
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", "history.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  my $b = $row->[0];
  my $d = $row->[1];
  $dates{$d} = 1;
  # say $d;
  $actions->{$b}->{$d} = $row->[4];
}

foreach my $b (sort keys %$actions) {
  print "$b ";
  foreach my $d (sort keys %dates) {
    my $x = $actions->{$b}->{$d};
    if ($x) {
      for ($x) {
        when (/Date of introduction/) { print "I" }
        when (/Referred/) { print "r" }
        when (/Notice/) { print "n" }
        when (/Presented to Governor/) { print "P" }
        when (/Approved by Governor/) { print "A" }
        when (/Returned by Governor/) { print "R" }
        default { print "x" }
      }
    } else {
      print ".";
    }
  }
  print "\n";
}

