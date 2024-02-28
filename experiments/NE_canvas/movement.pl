#! env perl
use 5.38.0;
use DBD::SQLite;
use Data::Printer array_max => 3;
use JSON::XS;

my $dbname = "../../leg.sqlite3";

# sqlite3 leg.sqlite3
# .tables
# .schema bills
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","");
my $strsql = <<EOT;
SELECT bills.number, date, action
FROM history
JOIN bills ON bills.id = history.bill_id
WHERE (
  action = 'Date of introduction' OR
  action like 'Referred to%'
)
ORDER BY date, bill_id, sequence
EOT
my $sth = $dbh->prepare($strsql);
$sth->execute;

# Create stacks we'll assign x,y values to once we have all the stacks.
my %stacks;

while (my $row = $sth->fetchrow_hashref) {
  $row->{action} =~ s/Referred to (the )?//;
  $row->{action} =~ s/ Committee$//;
  push @{$stacks{$row->{action}}}, $row->{number};
}

# p %stacks;
# my @keys = keys %stacks;
# p @keys;

# Read starting positions from the local hard-coded JSON file
my $nextX;
my $json_str;
{
  local $/; # Enable 'slurp' mode
  open my $fh, "<", "committees.json";
  $json_str = <$fh>;
}
my $json_committees = decode_json($json_str);
p $json_committees;
my $committees = {};
foreach my $committee (@$json_committees) {
  # say $committee->{name};
  $committees->{$committee->{name}} = {
    nextX => $committee->{x},
    nextY => $committee->{y} + 20,  # 20 to drop below the text
  };
}
p $committees;

# Now that we have the ordered stacks, let's calculate xFrom, xTo, yFrom, yTo
my $bills;
foreach my $committee (keys %stacks) {
  foreach my $bill (@{$stacks{$committee}}) {
    # say "$committee $bill";
    if ($committee eq "Date of introduction") {
      $bills->{$bill}->{xFrom} = $nextX->{$committee};
      $bills->{$bill}->{yFrom} = $committee->{$committee}->{nextY};
    }
    $nextX->{$committee} += 5;
  }
}

p $bills;