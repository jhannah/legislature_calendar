#! env perl
use 5.38.0;
use DBD::SQLite;

my $dbname = "../../leg.sqlite3";

# sqlite3 leg.sqlite3
# .tables
# .schema bills
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","");
my $strsql = <<EOT;
SELECT bill_id, date, action
FROM history
WHERE (
  action = 'Date of introduction' OR
  action like 'Referred to%'
)
ORDER BY bill_id, sequence
EOT
my $sth = $dbh->prepare($strsql);
$sth->execute;
while (my @row = $sth->fetchrow) {
  say join "|", @row;
}
 

