All data downloaded from https://legiscan.com/NE/datasets on 2023-01-26 at 15:00.

ack -i "Date of introduction" `find ./ -name "history.csv"` | cut -d, -f 2 | sort | uniq -c | perl -lane 'print "$F[1],$F[0]"' > b.csv

