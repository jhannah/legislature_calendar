#! env perl
use Modern::Perl;
use Text::CSV_XS;
no warnings "experimental";

my $people;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<:encoding(utf8)", "people.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  $people->{$row->[0]} = {name => $row->[1]};
}

open $fh, "<:encoding(utf8)", "votes.csv" or die $!;
<$fh>;  # skip header
while (my $row = $csv->getline($fh)) {
  $people->{$row->[1]}->{$row->[3]}++;
}

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

