#! env perl
use Modern::Perl;
use Text::CSV_XS;
no warnings "experimental";
no warnings "uninitialized";

my $people;
my $votes;
my $friendship;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<:encoding(utf8)", "people.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  # people_id -> name
  $people->{$row->[0]} = {name => $row->[1]};
}

open $fh, "<:encoding(utf8)", "votes.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  # people_id -> roll_call_id = vote_desc
  next unless ($row->[3] =~ /(Yea|Nay)/);
  $votes->{$row->[1]}->{$row->[0]} = $row->[3];
}

foreach my $person (keys %$people) {
  next unless ($person == 18370);  # Justin Wayne
  foreach my $other_person (keys %$people) {
    next if ($person == $other_person); # ignore themselves
    foreach my $roll_call_id (keys %{$votes->{$other_person}}) {
      my $person_vote = $votes->{$person      }->{$roll_call_id};
      my $other_vote  = $votes->{$other_person}->{$roll_call_id};
      next unless ($person_vote && $other_vote);
      if ($person_vote eq $other_vote) {
        $friendship->{$person}->{$other_person} += 1;
        # say "$roll_call_id: $person $person_vote $other_person $other_vote +1 = " . $friendship->{$person}->{$other_person};
      } else {
        $friendship->{$person}->{$other_person} -= 1;
        # say "$roll_call_id: $person $person_vote $other_person $other_vote -1 = " . $friendship->{$person}->{$other_person};
      }
    }
  }
}

foreach my $person (keys %$friendship) {
  next unless ($person == 18370);  # Justin Wayne
  my $x = $friendship->{$person};
  foreach my $other_person (sort { $x->{$b} <=> $x->{$a} } keys %$x) {
    printf("%s %s\n", $x->{$other_person}, $people->{$other_person}->{name});
  }
}

__END__

say "Name                 Yea Nay Absent NotVoting";
foreach my $people_id (keys %$people) {
  next unless (
    defined $people->{$people_id}->{Yea} ||
    defined $people->{$people_id}->{Nay}
  );   # Skip the committees
  printf("%-20s %3s %3s %3s %3s\n",
    $people->{$people_id}->{name}   // '',
    $people->{$people_id}->{Yea}    // '',
    $people->{$people_id}->{Nay}    // '',
    $people->{$people_id}->{Absent} // '',
    $people->{$people_id}->{NV}     // '',
  );
}

