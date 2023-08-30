create table matches (
match_id int PRIMARY KEY,
city varchar,
date date,
player_of_match varchar,
venue varchar,
neutral_venue int,
team1 varchar,
team2 varchar,
toss_winner varchar,	
toss_decision varchar,
winner varchar,
result varchar,
result_margin int,
eliminator varchar,
method_dl varchar,
umpire1 varchar,
umpire2 varchar
);

--Copying Data
copy matches from 'C:\Program Files\PostgreSQL\15\data\Practice Data\Data\IPL_matches.csv' delimiter ',' csv header;

select * from matches;

--Task 2

create table ball(
match_id INT,
inning int,
over int,
ball int,
batsman varchar,
non_striker varchar,
bowler varchar,
batsman_runs int,
extra_runs int,
total_runs int,
wicket_ball int,
desmissal_kind varchar,
player_dismissed varchar,
fielder varchar,
extras_type varchar,
batting_team varchar,
bowling_team varchar
);

--copying data

copy ball from 'C:\Program Files\PostgreSQL\15\data\Practice Data\Data\IPL_ball.csv' delimiter ',' csv header;

select * from ball;

--Task 01-- Players with high strike rate faced atleast 500 balls in IPL--

select batsman,sum(batsman_runs) as runs, count (ball) as balls,
round(sum (batsman_runs)*1.0/count (ball)*100,2) as strike_rate from ball
where not (extras_type='wides')
group by batsman
having count (ball)>500
order by strike_rate desc
limit 10;

select * from ball;

---Q2---Good average players who have played more than 2 IPL season--

select a.batsman,sum(a.batsman_runs),sum(case a.wicket_ball when 0 then null else 1 end) as out_batter,
round((sum(a.batsman_runs*1.0)/sum(case a.wicket_ball when 0 then null else 1 end))) as avg_batting,
count(distinct (extract(year from b.date))) as season_played
from ball as a inner join matches as b
on a.match_id = b.match_id
group by batsman
having count (distinct (extract(year from b.date)))>2
order by season_played desc,avg_batting desc nulls last limit 10;
			  
---Q3---Hard hitting players who have played more than 2 IPL season--

select a.batsman,
sum(case when batsman_runs in (4,6) then batsman_runs else 0 end) as total_fours_and_sixes, 
sum(total_runs) as total_runs,
round(sum(case when batsman_runs in (4,6) then batsman_runs else 0 end)*1.0/sum(total_runs),2) * 100 as Boundary_percentage,
count(distinct extract(year from b.date)) as Season_played
from ball as a
join Matches b
on a.match_id = b.match_id
group by a.batsman 
having count(distinct extract(year from b.date)) > 2
order by boundary_percentage desc
limit 10;		


---Q4---Bowlers with good economy--

select distinct bowler as bowler ,
sum (total_runs) as total_runs , 
round(count (bowler)/6,2) as total_over ,
round ((sum(total_runs)*1.0 / (count(bowler)/6.0)),2) as economy 
from ball
group by bowler 
having count(bowler)>=500
order by economy asc limit 10;

--Q5---Best strike rate bowler

select bowler,count(ball) as Number_of_balls,
sum(wicket_ball) as total_wicket,
((count(ball)/sum(wicket_ball)))as strike_rate from ball
where not desmissal_kind = 'run out' or 
desmissal_kind = 'obstructing the field' or
desmissal_kind = 'retired hurt'
group by bowler 
having count(ball)>=500 
order by strike_rate desc
limit 10;

---Q6---All rounders with best batting as well as bowling strike rate--

select batsman as All_rounder,
round((sum(batsman_runs)*1.0/count(ball) *100),2) as batting_strike_rate,bowler_strike_rate
from ball as a 
inner join
(select bowler,count(bowler) as balls,
sum(wicket_ball) as total_wicket,
round(((count(bowler)*1.0/sum(wicket_ball))),2)as bowler_strike_rate
from ball
group by bowler 
having count(bowler)>300 
order by bowler_strike_rate asc)  as b
on a.batsman = b.bowler
where not extras_type= 'wides'
group by batsman,bowler_strike_rate
having count(ball)>=500
order by batting_strike_rate desc, bowler_strike_rate desc 
limit 10;

---Q7--- good Wicketkeeper--

Select * from (select batsman,count(desmissal_kind) as wicketkeeper_wicket							
from ball							
where  desmissal_kind = 'caught' or desmissal_kind = 'stumped' 							
group by batsman 							
order by wicketkeeper_wicket desc) as a							
inner join  (select batsman,sum(batsman_runs) as runs, count(ball) as balls,							
round(sum(batsman_runs*1.0)/count(ball)*100,2) as strike_rate							
from ball							
where not (extras_type = 'wides')							
group by batsman							
having count(ball) >=500							
order by strike_rate desc) as b							
on a.batsman = b.batsman							
order by wicketkeeper_wicket desc,strike_rate							
limit 10;

-- Additional question
--Task 01 count of cities that have hosted an IPL match--

select count( distinct city)as city_count from matches where not city = 'NA';

--task 02 Create table deliveries_v02--

create table deliveries_v02 as select *,
case when total_runs>=4 then 'boundary'
when total_runs=0 then 'dot'
else 'other'
end as ball_result
from ball ;

select * from deliveries_v02;





/*--task 03 Write a query to fetch the total number of boundaries and dot balls from the
deliveries_v02 table.*/

select ball_result , 
count (*) from deliveries_v02
group by ball_result;


/* Task 04 Write a query to fetch the total number of boundaries scored by each team from the
deliveries_v02 table and order it in descending order of the number of boundaries
scored.*/

select batting_team, 
count(*) from deliveries_v02
where ball_result = 'boundary'
group by batting_team
order by count
desc;


/* Task 05 Write a query to fetch the total number of dot balls bowled by each team and order it in
descending order of the total number of dot balls bowled.*/

Select * from (select distinct batting_team, 
count(ball_result) as Number_of_dot_balls
from deliveries_v02 where ball_result = 'dot'
group by batting_team) as a
order by a.Number_of_dot_balls desc;

/* Task 06 Write a query to fetch the total number of dismissals by dismissal kinds where dismissal
kind is not NA.*/

select * from ball;
select desmissal_kind , count (*) from deliveries_v02 where 
desmissal_kind <> 'NA'
group by desmissal_kind
order by count 
desc;

select count(desmissal_kind) as Total_dismissal from ball
where not desmissal_kind = 'NA';

/* Task 07  Write a query to get the top 5 bowlers who conceded maximum extra runs from the
deliveries table.*/


select * from ball;
select bowler , sum(extra_runs) as total_extra_runs
from ball 
group by bowler 
order by total_extra_runs
desc limit 5;

/* Task 08 Write a query to create a table named deliveries_v03 with all the columns of
deliveries_v02 table and two additional column (named venue and match_date) of venue
and date from table matches */

select * from matches;

create table deliveries_vo3 as select a.*,
b.venue,
b.match_date 
from deliveries_v02 as a 
left join (select max(venue)as venue ,
		  max(date)as match_date,
		  match_id from matches group by match_id)
		  as b
		  on a.match_id=b.match_id;

		  
select * from deliveries_vo3;
		  
/* Task 09 Write a query to fetch the total runs scored for each venue and order it in the descending
order of total runs scored.*/

select venue,
sum(total_runs) as runs
from deliveries_vo3 group by venue 
order by runs 
desc;

/*Task  10 . Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the
descending order of total runs scored.*/

select venue,extract(year from match_date) as IPL_YEAR,
sum(total_runs) as runs
from deliveries_vo3 where venue = 'Eden Gardens'
group by IPL_YEAR,deliveries_vo3.venue
order by runs desc;













