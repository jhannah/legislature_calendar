#! env perl

use 5.26.0;
use DBI;
use GraphViz2;
my $dbh = DBI->connect("dbi:SQLite:dbname=NE.sqlite3","","");

my $edges;
my $graph = GraphViz2->new(
  global => {directed => 1},
);

my $strsql = "select bill_id, action from history order by bill_id, sequence";
my $sth = $dbh->prepare($strsql);
$sth->execute;
my $row_cnt;
my $prev_g;
my $prev_bill_id;
while (my ($bill_id, $action) = $sth->fetchrow) {
  my $g = generic($action);
  say "($prev_bill_id) $bill_id $g";
  last if ($row_cnt++ > 100);
  if ((defined $prev_bill_id) && $bill_id != $prev_bill_id) {
    $prev_g = $g;
    $prev_bill_id = $bill_id;
    next;
  }
  if ($prev_g) {
    say "  $prev_g -> $g";
    $graph->add_edge(from => $prev_g, to => $g);
  }
  $prev_g = $g;
  $prev_bill_id = $bill_id;
}
$sth->finish;
$dbh->disconnect;

$graph->run(format => 'svg', output_file => 'NE.svg');



sub generic {
  my ($action) = @_;
  $action =~ s/.* (name added|name withdrawn|point of order|priority bill)/\[Senator\] $1/;
  $action =~ s/.* AM\d+ (adopted|filed|withdrawn|refiled|lost|reoffered|not considered|pending)/\[Senator\] \[Amendment] $1/;
  $action =~ s/.* MO\d+ (adopted|filed|withdrawn|failed|pending|Indefinitely postpone filed|Indefinitely postpone|prevailed|Invoke cloture pursuant to Rule 7, Sec\. 10 filed)/\[Senator\] \[Motion] $1/;
  $action =~ s/.* FA\d+ (adopted|filed|withdrawn|lost|pending|not considered)/\[Senator\] \[Floor Amendment] $1/;
  $action =~ s/(Provisions\/portions of) LB.*(amended into).*/$1 \[Bill1\] $2 \[Bill2\] by \[Amendment\]/;
  $action =~ s/(Placed on General File with) AM.*/$1 \[Amendment\]/;
  $action =~ s/(Placed on Select File with) ER.*/$1 \[Enrollement and Review\]/;
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
  return $action;
}

