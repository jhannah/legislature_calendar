#! env perl

use 5.36.0;
# use Data::Printer;

my ($cnt, $all_mds);
($cnt, $all_mds) = memorize_counts();
print_years($cnt, $all_mds);


sub print_years {
  my ($cnt, $all_mds) = @_;
  say join ",", "Month-Day", 2010..2023;
  foreach my $md (sort keys %$all_mds) {
    print "$md";
    foreach my $y (2010..2023) {
      print "," . ($cnt->{$y}->{$md} || "");
    }
    print "\n";
  }
}

sub memorize_counts {
  my ($cnt, $all_mds);
  open my $fh, "ack -i 'Date of introduction' `find ./ -name 'history.csv'` |" or die $!;
  while (<$fh>) {
    # NE/2015-2016_104th_Legislature/csv/history.csv:15632:861951,2016-03-09,Legislature,1,"Date of introduction"
    my @l = split ",";
    my ($y, $md) = ($l[1] =~ /(\d\d\d\d)-(\d\d\-\d\d)/);
    # say "$y -> $md";
    $cnt->{$y}->{$md}++;
    $all_mds->{$md} = 1;
  }
  return $cnt, $all_mds;
}


