------------------------------
-- STATE SENATE
------------------------------

-- Setup county votes table...
select count(*)
from votes_20080715;

select *
from votes_20080715
limit 200;

delete from votes_20080715
where candidate = 'Totals';

select office, count(*) as cnt
from votes_20080715
group by office
order by office;

select *
into state_senate_20080715
from votes_20080715
where office = 'State Senator';

select *
from state_senate_20080715;

update state_senate_20080715
  set district = replace(district, 'District ', '');

update state_senate_20080715
  set office = 'State Senate'

select distinct party
from state_senate_20080715;

update state_senate_20080715
  set party =
    case
        when party = 'R' then 'Republican'
        else 'Democrat'
    end;

alter table state_senate_20080715
    rename column candidate to last_name;

alter table state_senate_20080715
    add column candidate varchar(50);

-- Setup fullname table...
select count(*)
from "20080715_state_senate_fullname";

select *
from "20080715_state_senate_fullname";

-- Lots of cleanup to do...

drop table if exists state_senate_fullname_20080715;

select *
into state_senate_fullname_20080715
from "20080715_state_senate_fullname";

select *
from state_senate_fullname_20080715;

select *
-- delete
from state_senate_fullname_20080715
where coalesce(district, '') = ''
  and coalesce(percent, '') = '';

select *
-- delete
from state_senate_fullname_20080715
where trim(candidate) = 'No Candidates';

select *
-- delete
from state_senate_fullname_20080715
where trim(votes) = 'Votes';

update state_senate_fullname_20080715
  set district = replace(replace(district, 'State Senator, ', ''), '100% of precincts reporting', '');

alter table state_senate_fullname_20080715
    add column ukey serial primary key;


;with previous_district as (
  select ukey, lag(district) over(order by ukey) as district
  from state_senate_fullname_20080715
)
update state_senate_fullname_20080715 as a
  set district = b.district
from previous_district as b
where a.ukey = b.ukey
  and coalesce(a.district, '') = ''
  and coalesce(b.district, '') <> '';

delete from state_senate_fullname_20080715
where coalesce(candidate, '') = '';

alter table state_senate_fullname_20080715
  add column last_name varchar(50);

update state_senate_fullname_20080715
  set candidate = replace(candidate, '  ', ' ');

update state_senate_fullname_20080715
  set last_name = split_part(candidate, ' ', 2);

select candidate, last_name
from state_senate_fullname_20080715
order by last_name;

update state_senate_fullname_20080715
  set district = replace(district, 'District ', '');

-- Okay now we have the two data sets clean and ready...

select *
from state_senate_fullname_20080715
order by ukey;

select *
from state_senate_20080715
order by district::int, last_name;

-- QC to make sure we are matching both sides...
select a.district, a.candidate, a.last_name
from state_senate_fullname_20080715 as a
  left join state_senate_20080715 as b
    on a.last_name = b.last_name
      and a.district::int = b.district::int
where b.last_name is null;

update state_senate_20080715
  set last_name = 'Carter'
where district = '3'
  and last_name = 'carter';

select *
from state_senate_20080715 as a
  left join state_senate_fullname_20080715 as b
    on a.last_name = b.last_name
      and a.district::int = b.district::int
where b.last_name is null;

-- QC make sure total votes match from each side...
;with total_votes as (
  select last_name, district, sum(votes::int) as votes
  from state_senate_20080715
  group by last_name, district
)
select *
from total_votes as a
  left join state_senate_fullname_20080715 as b
    on a.last_name = b.last_name
      and a.district::int = b.district::int
      and a.votes::int = b.votes::int
where b.last_name is null;


select district, candidate, sum(votes) as votes
from results
where party = 'Democrat'
group by district, party, candidate
order by district::int, votes desc;


-- Generate the final output .csv file...
select b.county, 'State Senate' as office,
  a.district, b.party, a.candidate,
  b.votes as votes
from state_senate_fullname_20080715 as a
  inner join state_senate_20080715 as b
    on a.last_name = b.last_name
      and a.district::int = b.district::int
order by a.district::int, b.party, b.county, a.candidate;

