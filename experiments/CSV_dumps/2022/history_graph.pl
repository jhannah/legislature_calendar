#! env perl

use 5.36.0;
use DBI;
use GraphViz2;
my $dbh = DBI->connect("dbi:SQLite:dbname=NE.sqlite3","","");

my $edges;
my $strsql = <<EOT;
  SELECT b.bill_number, action
  FROM bills b, history h
  WHERE b.bill_id = h.bill_id
  ORDER BY h.bill_id, h.date, h.sequence
EOT
my $sth = $dbh->prepare($strsql);
$sth->execute;
my ($row_cnt, $prev_g, $prev_bill_number);
while (my ($bill_number, $action) = $sth->fetchrow) {
  # Only Bills. Not Appropriation Bills or Resolutions or other things.
  next unless ($bill_number =~ /LB\d+$/);
  my $g = generic($action);
  say "($prev_bill_number) $bill_number $g";
  # say $g;
  # last if ($row_cnt++ > 100);
  if ((defined $prev_bill_number) && $bill_number ne $prev_bill_number) {
    $prev_g = $g;
    $prev_bill_number = $bill_number;
    next;
  }
  if ($prev_g) {
    say "  $prev_g -> $g";
    $edges->{$prev_g}->{$g}++;
  }
  $prev_g = $g;
  $prev_bill_number = $bill_number;
}
$sth->finish;
$dbh->disconnect;


my $graph = GraphViz2->new(
  global => {directed => 1},
  graph  => {
    # rankdir => 'LR',  # Layout: left to right (instead of top to bottom)
  },
);
foreach my $from (keys %$edges) {
  foreach my $to (keys %{$edges->{$from}}) {
    my $cnt = $edges->{$from}->{$to};
    #if ($cnt > 19) {
      $graph->add_edge(from => $from, to => $to, label => $cnt);
    #}
  }
}
$graph->run(
  format => 'svg', output_file => 'NE.svg',
  # format => 'png', output_file => 'NE.png',
);



sub generic {
  my ($action) = @_;
  $action =~ s/.* (name added|name withdrawn|point of order|priority bill)/\[Senator\] $1/;
  # $action =~ s/.* (AM|FA)\d+ (adopted|filed|withdrawn|refiled|lost|reoffered|not considered|pending)/\[Senator\] \[Amendment] $2/;
  $action =~ s/.* (AM|FA)\d+ (adopted|filed|withdrawn|refiled|lost|reoffered|not considered|pending)/\[Senator\] \[Amendment] \[Action\]/;
  # $action =~ s/.* FA\d+ (adopted|filed|withdrawn|lost|pending|not considered)/\[Senator\] \[Floor Amendment] $1/;
  # $action =~ s/.* MO\d+ (adopted|filed|withdrawn|failed|pending|Indefinitely postpone filed|Indefinitely postpone|prevailed|Invoke cloture pursuant to Rule 7, Sec\. 10 filed)/\[Senator\] \[Motion] $1/;
  $action =~ s/.* MO\d+ (adopted|filed|withdrawn|failed|pending|Indefinitely postpone filed|Indefinitely postpone|prevailed|Invoke cloture pursuant to Rule 7, Sec\. 10 filed)/\[Senator\] \[Motion] \[Action\]/;
  $action =~ s/(Provisions\/portions of) LB.*(amended into).*/$1 \[Bill1\] $2 \[Bill2\] by \[Amendment\]/;
  $action =~ s/(Placed on General File with) AM.*/$1 \[Amendment\]/;
  $action =~ s/(Placed on Select File with) ER.*/$1 \[Enrollment and Review\]/;
  $action =~ s/(Placed on Final Reading with) ST.*/$1 \[Standing Committee Amendment\]/;
  $action =~ s/(Passed on Final Reading) \d\d.*/$1 \[Vote\]/;
  $action =~ s/(Passed on Final Reading with Emergency Clause) \d\d.*/$1 \[Vote\]/;
  $action =~ s/(Passed on Final Reading with Emergency Clause striken) \d\d.*/$1 \[Vote\]/;
  $action =~ s/Notice of [Hh]earing for \w+ \d\d, \d\d\d\d.*/Notice of hearing for \[Date\]/;
  $action =~ s/(Enrollment and Review) \w+ (adopted|filed)/$1 \[#\] $2/;
  $action =~ s/.* MO\d+ Bracket until .* filed/\[Senator\] \[Motion\] Bracket until \[Date\] filed/;
  $action =~ s/((Presented to|Approved by) Governor on) .*/$2 Governor on \[Date\]/;
  $action =~ s/(Attorney General Opinion) \d\d.*/$1 \[ID\] to \[Senator\]/;
  $action =~ s/.* MO\d+ (Recommit|Rerefer) to (.*) filed/\[Senator\] \[Motion\] $1 to $2 filed/;
  $action =~ s/.* MO\d+ (Becomes law notwithstanding the objections of the Governor filed)/\[Senator\] \[Motion\] $1/;
  $action =~ s/.* Withdraw (bill )?filed/\[Senator\] \[Motion\] Withdraw filed/;
  $action =~ s/.*suspend rules.*/Motion to suspend rules/i;
  $action =~ s/Referred to .* Committee/Referred to \[Committee\]/;
  $action =~ s/.* AM\d+ divided/\[Committee\] \[Amendment\] divided/;
  $action =~ s/Chair ruled.*/Chair ruled \[Action\]/;
  $action =~ s/(.{50}).*/$1.../;   # GraphViz explodes at some certain length
  # e.g. This is too long: Stinner MO218 To override the Governors line-item veto contained in the following section of the bill: Section 28, transfer of funds from the Prison Overcrowding Contingency Fund to the Vocational and Life Skills Programming Fund filed
  return $action;
}

