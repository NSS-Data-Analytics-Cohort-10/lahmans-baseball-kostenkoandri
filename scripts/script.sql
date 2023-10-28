-- exploratory selects
select * from people where playerid ='alvarpe01';
select * from managershalf;
select * from salaries;
select * from managers;
select * from teams;
select * from teamshalf;
select * from appearances;
select * from fieldingofsplit;
select * from fieldingof;
select * from fielding;
select * from pitching;
select * from batting;
select * from halloffame;
select * from awardsshareplayers;
select * from awardsplayers;
select * from awardsmanagers;
select * from allstarfull;
select * from collegeplaying;
select * from schools;

-- questions
-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
-- 1871 - 2016
select min(year),
	max(year)
from homegames;
-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
-- Eddie Gaedel: 43 inches
   select playerid, 
   		namefirst,
		namelast,
		height
	from people
	where height = (
		select min(height)
		from people)

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?


-- need to check if all of the salary years were in major leage

select distinct playerid,
	namefirst,
	namelast,
	schoolname,
	sum(salary)::numeric::money as total_salary
from people
join collegeplaying using(playerid)
join schools using(schoolid)
left join salaries s using(playerid)
where schoolname = 'Vanderbilt University'
group by playerid, namefirst, namelast, schoolname
order by total_salary desc;

select * from schools where schoolname ilike '%vanderbilt%';
select * from salaries where playerid = 'embresl01'

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
with cte as (
select playerid,
	po,
	case
		when pos = 'OF' then 'Outfield'
		when pos in ('SS', '1B', '3B') then 'Infield'
		else 'Battery'
	end as position_group
	
from fielding)
select playerid,
position_group,
sum(po) over(partition by position_group)
from cte
order by playerid
;

   select playerid, count(playerid) from fielding
   group by playerid
   order by playerid;
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
   select
   floor(yearid/10)*10 as decade,
   sum(so) / sum(G) as avg_so_per_game --should I divide by homegames instead since it will give an actual number of games??
   from teams
   where yearid >= 1920
   group by decade
   order by decade;
   

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
select playerid,
	sb + cs as stolen_base_attempts,
	case when sb != 0 then round(sb::numeric / (sb + cs) * 100, 2)
	else 0 end as percentage_of_sb_success
	
from batting
where yearid = 2016
order by sb desc;

select * from batting

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- 1981 was split season
(select teamid, W, WSWin, yearid
from teams
where yearid between 1970 and 2016
	and WSWin = 'N'
 	and yearid != 1981
order by W desc
limit 1)
union
(select teamid, W, WSWin, yearid
from teams
where yearid between 1970 and 2016
	and WSWin = 'Y'
 	and yearid != 1981
order by W asc
limit 1);

-- SELECT yearid, teamid, w, (
-- select max(w) from teams where wswin = 'N' and yearid = t.yearid) as most_wins
-- from teams t
-- where WSWin = 'Y'
-- order by yearid;
with cte as (
	select yearid, max(w) as max_wins
	from teams
where yearid between 1970 and 2016
 	and yearid != 1981
	group by yearid
),
cte2 as(
select yearid,
	teamid,
	w,
	c.max_wins as max_wins
from teams t
join cte c using(yearid)
where yearid between 1970 and 2016
	and WSWin = 'Y'
 	and yearid != 1981
order by yearid)
select count(*) as count_winner_teams_with_max_wins,
	round(count(*) / 46.0 * 100) as percentage
from cte2 where w = max_wins;

select * from teams where yearid = 1981

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
select * from homegames;

with highest_attendance as (select year, team,
	park,
	attendance,
	attendance / games as att_per_game
from homegames
where games >= 10 and year = 2016
order by att_per_game desc
limit 5
)
select distinct team, park_name, att_per_game
from highest_attendance h
left join parks p using(park)
order by att_per_game desc;
---------------------------------------------
with lowest_attendance as (select year, team,
	park,
	attendance,
	attendance / games as att_per_game
from homegames
where games >= 10 and year = 2016
order by att_per_game
limit 5
)
select distinct team, park_name, att_per_game
from lowest_attendance h
left join parks p using(park)
order by att_per_game;
	

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
select a.playerid,
	p.namefirst || ' ' || p.namelast as full_name,
	yearid,
	teamid
from awardsmanagers a
join people p using(playerid)
join managers m using(playerid, yearid)
where a.awardid = 'TSN Manager of the Year'
	and a.lgid = 'NL' and playerid in (
	select aw.playerid
	from awardsmanagers aw
	where aw.awardid = 'TSN Manager of the Year'
	and aw.lgid = 'AL');


select * from managers
-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
