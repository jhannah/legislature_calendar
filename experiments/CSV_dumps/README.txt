All data downloaded from https://legiscan.com/NE/datasets on 2023-01-26 at 15:00.

ack -i "Date of introduction" `find ./ -name "history.csv"` | cut -d, -f 2 | sort | uniq -c | perl -lane 'print "$F[1],$F[0]"' > b.csv

SQLite:

Load all the bills:
find . -type f -name 'bills.csv' | xargs -I% sqlite3 NE.sqlite3 ".mode csv" ".import % bills" ".exit"

Load all the history:
find . -type f -name 'history.csv' | xargs -I% sqlite3 NE.sqlite3 ".mode csv" ".import % history" ".exit"

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


