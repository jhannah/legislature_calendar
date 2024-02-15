#! env perl
use 5.38.0;
use Text::CSV_XS;
use utf8;

my $dir = "NE/2023-2024_108th_Legislature/csv";
my $header = "Nebraska 2023-2024 108th Legislature";
my $data_source = 'Data as of 2024-02-11 from <a href="https://legiscan.com/NE/datasets">Legiscan</a>.';
my $source_code = '<a href="https://github.com/jhannah/legislature_calendar/blob/main/experiments/CSV_experiments/history_viz.pl">Source code</a>.';

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
  if ($current =~ /(Date of introduction|signed|Placed on|Indefinitely Postponed)/) {
    # Don't overwrite.
  } else {
    # Overwrite
    $history_per_bill->{$bill_id}->{$date} = $row->[4];
  }
}

print_header();

foreach my $bill_id (sort keys %$history_per_bill) {
  #next unless ($bill_id eq "1395419");
  printf $out '<tr><td><a href="%s">%s</a></td> <td class="fixed">',
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
      elsif (/Indefinitely Postponed/)    { print $out "P"; $dots = "&nbsp;" }
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
table td.fixed {
  // width: 30px;
  // overflow: hidden;
  // display: inline-block;
  font-family: Courier;
}
td {
  white-space: nowrap;
}
</style>
</head>
<body>

<h1>$header</h1>

<p>Reading from left to right, each character is one calendar day of this session, and what action(s) were taken.
"." means no action was taken on this bill on that calendar day, but the bill is neither Passed nor Failed so far.
$data_source
$source_code
</p>

<table>
<tr><td class="fixed">I</td><td>Date of introduction</td></tr>
<tr><td class="fixed">r</td><td>Referred</td></tr>
<tr><td class="fixed">H</td><td>Notice of Hearing/other</td></tr>
<tr><td class="fixed">1</td><td>Placed on General File</td></tr>
<tr><td class="fixed">2</td><td>Placed on Select File</td></tr>
<tr><td class="fixed">F</td><td>Final Reading</td></tr>
<tr><td class="fixed">G</td><td>Presented to Governor</td></tr>
<tr><td class="fixed">A</td><td>Approved by Governor</td></tr>
<tr><td class="fixed">R</td><td>Returned by Governor</td></tr>
<tr><td class="fixed">S</td><td>President/Speaker signed</td></tr>
<tr><td class="fixed">W</td><td>Bill withdrawn</td></tr>
<tr><td class="fixed">P</td><td>Indefinitely Postponed</td></tr>
<tr><td class="fixed">x</td><td>other action</td></tr>
<tr><td class="fixed">.</td><td>No action taken on this day</td></tr>
</table>

<table>
EOT
}

sub print_footer {
  print $out <<EOT;
</table>

</br></br>
$data_source
$source_code
</body>
</html>
EOT
}


