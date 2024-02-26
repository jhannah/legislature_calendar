delete from people;
.import --csv --skip 1 NE/2023-2024_108th_Legislature/csv/people.csv    people
delete from votes;
.import --csv --skip 1 NE/2023-2024_108th_Legislature/csv/votes.csv     votes
delete from rollcalls;
.import --csv --skip 1 NE/2023-2024_108th_Legislature/csv/rollcalls.csv rollcalls

