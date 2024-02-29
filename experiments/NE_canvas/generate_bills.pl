#! env perl
use 5.38.0;
use DBD::SQLite;
use Data::Printer array_max => 3;
use JSON::XS;

my $dbname = "../../leg.sqlite3";
my $committees_json_file = "committees.json";
my $bills_json_file = "bills.json";

# sqlite3 leg.sqlite3
# .tables
# .schema bills
say "Connecting to $dbname...";
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
  # if ($row->{number} eq "LB1") {
  #   say "LB1 [" . $row->{action} . "]";
  # }
  $row->{action} =~ s/Date of introduction/Introduced/;
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
  say "Reading from $committees_json_file...";
  local $/; # Enable 'slurp' mode
  open my $fh, "<", $committees_json_file;
  $json_str = <$fh>;
}
my $json_committees = decode_json($json_str);
# p $json_committees;
my $committees = {};
foreach my $committee (@$json_committees) {
  # say $committee->{name};
  $committees->{$committee->{name}} = {
    nextX => $committee->{x},
    nextY => $committee->{y} + 6,  # 10 to drop below the text
  };
}
# p $committees;

# Now that we have the ordered stacks, let's calculate xFrom, xTo, yFrom, yTo
my $bills;
foreach my $committee (keys %stacks) {
  unless ($committees->{$committee}) {
    say "uhh... unknown committee $committee";
  }
  foreach my $bill (@{$stacks{$committee}}) {
    # say "$committee $bill";
    if ($committee eq "Introduced") {
      $bills->{$bill}->{xFrom} = $committees->{$committee}->{nextX};
      $bills->{$bill}->{yFrom} = $committees->{$committee}->{nextY};
    } else {
      $bills->{$bill}->{xTo} = $committees->{$committee}->{nextX};
      $bills->{$bill}->{yTo} = $committees->{$committee}->{nextY};
    }
    $committees->{$committee}->{nextX} += 5;
  }
}

# Cap to first 1200 pixels for now
foreach my $number (keys %$bills) {
  if (
    (not defined $bills->{$number}->{xFrom}) ||
    (not defined $bills->{$number}->{xTo}) ||
    $bills->{$number}->{xFrom} > 1200 ||
    $bills->{$number}->{xTo} > 1200
  ) {
    delete $bills->{$number};
  }
}


{
  say "Writing $bills_json_file...";
  open my $fh, ">", $bills_json_file;
  # TODO canonical() sorts ASCII, not by the numeric part of the bill number 
  print $fh JSON::XS->new->pretty(1)->canonical(1)->encode($bills);
}
# p $bills;
# p $committees;