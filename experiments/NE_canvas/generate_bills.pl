#! env perl
use 5.38.0;
use DBD::SQLite;
use Data::Printer array_max => 3;
use JSON::XS;
use Clone 'clone';

my $dbname = "../../leg.sqlite3";
my $committees_json_file = "committees.json";
my $dates_json_file = "dates.json";

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
LIMIT 100
EOT
my $sth = $dbh->prepare($strsql);
$sth->execute;

my $dates;   # Sets of bill movements per date
  # ->{$date}->{stacks}  # How many rows/columns of bills are in play for any given committee on any given date
my $prev_date;
while (my $row = $sth->fetchrow_hashref) {
  # if ($row->{number} eq "LB1") {
  #   say "LB1 [" . $row->{action} . "]";
  # }
  $row->{action} =~ s/Date of introduction/Introduced/;
  $row->{action} =~ s/Referred to (the )?//;
  $row->{action} =~ s/ Committee$//;
  unless (defined $dates->{ $row->{date} }) {
    if ($prev_date) {
      # We've arrived at a new date. Copy/paste the previous date stacks as our starting point
      $dates->{ $row->{date} }->{stacks} = clone($dates->{$prev_date}->{stacks});
    }
  }
  my $stacks = \$dates->{ $row->{date} }->{stacks};
  # p $stacks;
  push @{$$stacks->{ $row->{action} }}, $row->{number};
  $prev_date = $row->{date};
}

p $dates;

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
    nextX      => $committee->{x},
    original_x => $committee->{x},
    rollover_x => $committee->{rollover_x},
    nextY      => $committee->{y} + 6,  # drop the bill boxes below the text
    row        => 1,
  };
}
# p $committees;

my $bills_previous_location;
# Now that we have the bill and committee info, calculate movements (xFrom, xTo, yFrom, yTo)
foreach my $date (keys %$dates) {
  my $stacks = $dates->{$date}->{stacks};
  my $movements;

  foreach my $committee (keys %$stacks) {
    unless ($committees->{$committee}) {
      say "uhh... unknown committee $committee";
    }
    foreach my $bill (@{$stacks->{$committee}}) {
      # say "$committee $bill";
      if ($committee eq "Introduced") {
        $movements->{$bill}->{xFrom} = 0;
        $movements->{$bill}->{yFrom} = 0;
        $movements->{$bill}->{xTo} = $committees->{$committee}->{nextX};
        $movements->{$bill}->{yTo} = $committees->{$committee}->{nextY};
        $movements->{$bill}->{rowFrom} = $committees->{$committee}->{row};
      } else {
        $movements->{$bill}->{xFrom} = $bills_previous_location->{$bill}->{x};
        $movements->{$bill}->{yFrom} = $bills_previous_location->{$bill}->{y};
        $movements->{$bill}->{xTo} = $committees->{$committee}->{nextX};
        $movements->{$bill}->{yTo} = $committees->{$committee}->{nextY};
        $movements->{$bill}->{rowTo} = $committees->{$committee}->{row};
      }
      $bills_previous_location->{$bill} = {
        x => $committees->{$committee}->{nextX},
        y => $committees->{$committee}->{nextY},
      };
      $committees->{$committee}->{nextX} += 5;
      if ($committees->{$committee}->{nextX} > $committees->{$committee}->{rollover_x}) {
        # Start a new row
        $committees->{$committee}->{nextX} = $committees->{$committee}->{original_x};
        $committees->{$committee}->{nextY} += 6;
        $committees->{$committee}->{row} += 1;
        say "committee $committee is now on row " . $committees->{$committee}->{row};
      }
    }
  }
  $dates->{$date}->{movements} = $movements;
}

# Cap to first 3 rows of Introduced for now
# foreach my $number (keys %$bills) {
#   if (
#     (not defined $bills->{$number}->{xFrom}) ||
#     (not defined $bills->{$number}->{xTo}) ||
#     $bills->{$number}->{rowFrom} > 3
#   ) {
#     delete $bills->{$number};
#   }
# }

{
  say "Writing $dates_json_file...";
  open my $fh, ">", $dates_json_file;
  # TODO canonical() sorts ASCII, not by the numeric part of the bill number 
  print $fh JSON::XS->new->pretty(1)->canonical(1)->encode($dates);
}
