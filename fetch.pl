#! env perl
use 5.38.0;
use LWP::UserAgent;
use JSON::XS qw(decode_json);
use DBD::SQLite;

my $dbname = "leg.sqlite3";
my $session_id = 2028;
my $api_key = 'ad1ae3b54176acb67c2d7d5082c805a5';
my %status = (
  1 => "Introduced",
  2 => "Engrossed",
  3 => "Enrolled",
  4 => "Passed",
  6 => "Failed",
);

# API docs: https://legiscan.com/gaits/documentation/legiscan
# Get session list:
#   https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getSessionList&state=NE
# Get all bills for session 2028:
#   https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getMasterList&id=2028
# Get list of people:
#   https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getSessionPeople&id=2028

my $ua = LWP::UserAgent->new;
my $base_url = "https://api.legiscan.com/?key=$api_key";
my $req = HTTP::Request->new(GET => $base_url . "&op=getMasterList&id=$session_id");
my $res = $ua->request($req);
unless ($res->is_success) {
  die $res->status_line;
}
my $masterList = decode_json($res->decoded_content) or die $!;
my $session = $masterList->{masterlist}->{session};
delete $masterList->{masterlist}->{session};

# sqlite3 leg.sqlite3
# .tables
# .schema bills
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","");
$dbh->do("DELETE from bills");
my $strsql = <<EOT;
INSERT INTO bills (id, session_id, number, number_numeric, status, last_action_date, last_action, title, url)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
EOT
my $sth = $dbh->prepare($strsql);

my $rowcount;
my @ml = values %{$masterList->{masterlist}};
foreach my $bill (sort { $b->{last_action_date} cmp $a->{last_action_date} } @ml) {
  unless ($status{$bill->{status}}) {
    die "What does status $bill->{status} mean? $bill->{number}";
  }
  my $number_numeric = $bill->{number};
  $number_numeric =~ s/[^0-9]//g;
  $sth->execute(
    $bill->{bill_id},
    $session_id,
    $bill->{number},
    $number_numeric,
    $status{$bill->{status}},
    $bill->{last_action_date},
    $bill->{last_action},
    $bill->{title},
    $bill->{url},
  );
  $rowcount++;
}
 
say "Inserted $rowcount rows into $dbname";

