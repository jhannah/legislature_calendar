#! env perl
use Modern::Perl;
use Text::CSV_XS;
no warnings "experimental";

my ($bills, %dates_list, $history_per_bill);

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<:encoding(utf8)", "bills.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  my $bill_id = $row->[0];
  $bills->{$bill_id} = {
    bill_number => $row->[2],
    status_desc => $row->[4],
    title       => $row->[6],
    url         => $row->[12],
    state_link  => $row->[13],
  };
}

open $fh, "<:encoding(utf8)", "history.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  my $bill_id = $row->[0];
  my $date = $row->[1];
  $dates_list{$date} = 1;
  $history_per_bill->{$bill_id}->{$date} = $row->[4];
}

print_header();

foreach my $bill_id (sort keys %$history_per_bill) {
  #next unless ($bill_id eq "1395774");
  printf('<tr><td><a href="%s">%s</a></td> <td>',
    $bills->{$bill_id}->{state_link},
    $bills->{$bill_id}->{bill_number},
  );
  my $dots = 1;
  foreach my $date (sort keys %dates_list) {
    my $action = $history_per_bill->{$bill_id}->{$date};
    if ($action) {
      for ($action) {
        when (/Date of introduction/) { print "I" }
        when (/Referred/) { print "r" }
        when (/Notice/) { print "n" }
        when (/Presented to Governor/) { print "P" }
        when (/Approved by Governor/) { print "A"; $dots = 0; }
        when (/Returned by Governor/) { print "R" }
        when (/President\/Speaker signed/) { print "S"; $dots = 0; }
        when (/Bill withdrawn/) { print "W"; $dots = 0; }
        default { print "x" }
      }
    } else {
      print $dots ? "." : " ";
    }
  }
  print "</td>";
  printf('<td>%s</td>', $bills->{$bill_id}->{status_desc});
  printf('<td>%s <a href="%s">LegiScan</a></td>',
    $bills->{$bill_id}->{title},
    $bills->{$bill_id}->{url},
  );
  print "</tr>\n";
}

print_footer();


sub print_header {
  print <<EOT;
<!DOCTYPE html>
<html>
<head>
<style>
body { font-family: Courier; }
table td {
  // width: 30px;
  //overflow: hidden;
  //display: inline-block;
  white-space: nowrap;
}
</style>
</head>
<body>

<h1>2021 Nebraska Legislature</h1>
<table>
EOT
}

sub print_footer {
  print <<EOT;
</table>

</br></br>
<a href="https://github.com/jhannah/legislature_calendar">Source code</a>
</body>
</html>
EOT
}


