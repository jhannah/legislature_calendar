#! env perl
use Modern::Perl;
use LWP::UserAgent;
use JSON::XS qw(decode_json);
use MIME::Base64;

my $api_key = 'ad1ae3b54176acb67c2d7d5082c805a5';

# https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getDatasetList&state=NE
# https://api.legiscan.com/?key=ad1ae3b54176acb67c2d7d5082c805a5&op=getDataset&access_key=4tRlAgDqR0s1vi6vCbKqfw&id=1810

my $ua = LWP::UserAgent->new;
my $base_url = "https://api.legiscan.com/?key=$api_key";
my $req = HTTP::Request->new(GET => $base_url . "&op=getDatasetList&state=NE");
my $res = $ua->request($req);
unless ($res->is_success) {
  die $res->status_line;
}
my $datasetList = decode_json($res->decoded_content) or die $!;
my $ds = $datasetList->{datasetlist}->[0];
my $sid = $ds->{session_id};
my $ak  = $ds->{access_key};
my $st  = $ds->{session_title};
my $sn  = $ds->{session_name};
mkdir("sessions")      unless (-d "sessions");
mkdir("sessions/$sid") unless (-d "sessions/$sid");
my $dir = "sessions/$sid";

$req = HTTP::Request->new(GET => $base_url . "&op=getDataset&access_key=$ak&id=$sid");
$res = $ua->request($req);
unless ($res->is_success) {
  die $res->status_line;
}
my $dataset = decode_json($res->decoded_content) or die $!;
open my $fh, ">", "$dir/dataset.json";
print $fh $res->decoded_content;
open $fh, ">", "$dir/dataset.zip";
print $fh decode_base64($dataset->{dataset}->{zip});



