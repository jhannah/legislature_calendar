#! env perl
use Modern::Perl;
use LWP::UserAgent;
use JSON::XS qw(decode_json);

my $api_key = 'ad1ae3b54176acb67c2d7d5082c805a5';
my %status = (
  1 => "Introduced",
  2 => "Engrossed",
  3 => "Enrolled",
  4 => "Passed",
  6 => "Failed",
);

# https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getMasterList&id=1810

my $ua = LWP::UserAgent->new;
my $base_url = "https://api.legiscan.com/?key=$api_key";
my $req = HTTP::Request->new(GET => $base_url . "&op=getMasterList&id=1810");
my $res = $ua->request($req);
unless ($res->is_success) {
  die $res->status_line;
}
my $masterList = decode_json($res->decoded_content) or die $!;
my $session = $masterList->{masterlist}->{session};
delete $masterList->{masterlist}->{session};
print_header($session);
my @ml = values %{$masterList->{masterlist}};
foreach my $bill (sort { $b->{last_action_date} cmp $a->{last_action_date} } @ml) {
  unless ($status{$bill->{status}}) {
    die "What does status $bill->{status} mean? $bill->{number}";
  }
  printf('<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>' . "\n",
    $bill->{url},
    $bill->{number},
    $status{$bill->{status}},
    $bill->{last_action_date},
    $bill->{last_action},
    $bill->{title},
  );
}
print_footer();
 
 
sub print_header {
  my ($session) = @_;
  print <<EOT;
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: Courier; }
  table td { white-space: nowrap; }
</style>
</head>
<body>

<h1>Nebraska $session->{session_title} $session->{session_name}</h1>
<table>
EOT
}

sub print_footer {
  print <<EOT;
</table>

</br></br>
<a href="https://github.com/jhannah/legislature_calendar">Source code</a>
</body>
</html>
EOT
}

