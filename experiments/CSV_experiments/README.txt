All data downloaded from https://legiscan.com/NE/datasets on 2024-02-18.

ack -i "Date of introduction" `find ./ -name "history.csv"` | cut -d, -f 2 | sort | uniq -c | perl -lane 'print "$F[1],$F[0]"' > b.csv

------------
SQLite
------------

sqlite3 NE.sqlite3 < schema.sql

Load all the bills:
find . -type f -name 'bills.csv' | xargs -I% sqlite3 NE.sqlite3 ".mode csv" ".import --skip 1 % bills" ".exit"

Load all the history:
find . -type f -name 'history.csv' | xargs -I% sqlite3 NE.sqlite3 ".mode csv" ".import --skip 1 % history" ".exit"

sqlite3 NE.sqlite3

delete from bills where last_action_date = 'last_action_date';
.schema bills
select count(*) from bills;
select substr(last_action_date, 1, 4), count(*) from bills group by 1;

delete from history where date = 'date';
.schema history
select count(*) from history;
select substr(date, 1, 4), count(*) from history group by 1;

select h.date, b.bill_number, b.title, b.state_link
from bills b, history h
where b.bill_id = h.bill_id
and h.action = "Date of introduction"
and substr(b.bill_number, 1, 2) = 'LB'
and substr(b.bill_number, -1, 1) != 'A'
and substr(h.date, 6, 5) > '01-25';

--------------
2024 Feb stuff
--------------
echo ".mode csv\n.import experiments/CSV_experiments/NE/2023-2024_108th_Legislature/csv/people.csv    people"    | sqlite3 leg.sqlite3
echo ".mode csv\n.import experiments/CSV_experiments/NE/2023-2024_108th_Legislature/csv/votes.csv     votes"     | sqlite3 leg.sqlite3
echo ".mode csv\n.import experiments/CSV_experiments/NE/2023-2024_108th_Legislature/csv/rollcalls.csv rollcalls" | sqlite3 leg.sqlite3


select bills.number, rollcalls.date, rollcalls.roll_call_id, votes.vote_desc, users.name, watchlists.stance
from rollcalls
join votes on rollcalls.roll_call_id = votes.roll_call_id
join people on votes.people_id = people.people_id
join bills on rollcalls.bill_id = bills.id
join watchlists on bills.id = watchlists.bill_id
join users on watchlists.user_id = users.id
where people.name = 'Justin Wayne'
order by 1 asc, 2 desc;



# https://antonz.org/sqlite-pivot-table/
my $debug_sql = <<EOT;
  SELECT
    people.name,
    COUNT(*) FILTER (WHERE votes.vote_desc = 'Yea') AS "Yea",
    COUNT(*) FILTER (WHERE votes.vote_desc = 'Nay') AS "Nay",
    COUNT(*) FILTER (WHERE votes.vote_desc = 'NV') AS "NV",
    COUNT(*) FILTER (WHERE votes.vote_desc = 'Absent') AS "Absent"
  FROM people
  JOIN votes ON votes.people_id = people.people_id
  GROUP BY 1
  ORDER BY "Yea" + "Nay" DESC;
EOT
