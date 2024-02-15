#! env perl
use 5.38.0;
use Text::CSV_XS;
use utf8;

my $dir = "NE/2023-2024_108th_Legislature/csv";
my $header = "Nebraska 2023-2024 108th Legislature";
open my $out, ">:encoding(utf8)", "history_viz.html" or die $!;

my ($bills, %dates_list, $history_per_bill);

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<:encoding(utf8)", "$dir/bills.csv" or die $!;
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

open $fh, "<:encoding(utf8)", "$dir/history.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  my $bill_id = $row->[0];
  my $date = $row->[1];
  $dates_list{$date} = 1;
  # Gah... multiple things on same day cause problems for simply overwriting...
  # Make the more important ones stick.
  my $current = $history_per_bill->{$bill_id}->{$date} // '';
  if ($current =~ /(Date of introduction|signed|Placed on)/) {
    # Don't overwrite.
  } else {
    # Overwrite
    $history_per_bill->{$bill_id}->{$date} = $row->[4];
  }
}

print_header();

foreach my $bill_id (sort keys %$history_per_bill) {
  #next unless ($bill_id eq "1395419");
  printf $out '<tr><td><a href="%s">%s</a></td> <td>',
    $bills->{$bill_id}->{state_link},
    $bills->{$bill_id}->{bill_number},
  ;
  my $dots = "&nbsp;";
  foreach my $date (sort keys %dates_list) {
    my $action = $history_per_bill->{$bill_id}->{$date} // '';
    for ($action) {
      if    (/Date of introduction/)      { print $out "I"; $dots = "." }
      elsif (/Referred/)                  { print $out "r" }
      elsif (/Notice/)                    { print $out "H" }
      elsif (/Placed on General File/)    { print $out "1" }
      elsif (/Placed on Select File/)     { print $out "2" }
      elsif (/Final Reading/)             { print $out "F" }
      elsif (/Presented to Governor/)     { print $out "G" }
      elsif (/Approved by Governor/)      { print $out "A"; $dots = "&nbsp;" }
      elsif (/Returned by Governor/)      { print $out "R" }
      elsif (/President\/Speaker signed/) { print $out "S"; $dots = "&nbsp;" }
      elsif (/Bill withdrawn/)            { print $out "W"; $dots = "&nbsp;" }
      elsif (/\w/)                        { print $out "x" }
      else                                { print $out $dots }
    }
  }
  print $out "</td>";
  printf $out '<td>%s</td>', $bills->{$bill_id}->{status_desc};
  printf $out '<td>%s <a href="%s">LegiScan</a></td>',
    $bills->{$bill_id}->{title},
    $bills->{$bill_id}->{url},
  ;
  print $out "</tr>\n";
}

print_footer();


sub print_header {
  print $out <<EOT;
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

<h1>$header</h1>
<table>
EOT
}

sub print_footer {
  print $out <<EOT;
</table>

</br></br>
<a href="https://github.com/jhannah/legislature_calendar/blob/main/experiments/CSV_experiments/history_viz.pl">Source code</a>
</body>
</html>
EOT
}


