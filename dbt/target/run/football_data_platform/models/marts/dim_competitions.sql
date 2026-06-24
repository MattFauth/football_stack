
  
    

  create  table "football"."marts"."dim_competitions__dbt_tmp"
  
  
    as
  
  (
    with competitions as (
    select * from "football"."staging"."stg_competitions"
),
countries as (
    select * from "football"."staging"."stg_countries"
)

select
    c.competition_id,
    c.competition_code,
    c.competition_name,
    c.sub_type,
    c.competition_type,
    c.country_id,
    c.country_name,
    c.domestic_league_code,
    c.confederation,
    co.total_clubs as country_total_clubs,
    co.total_players as country_total_players,
    c.url
from competitions c
left join countries co on c.country_id = co.country_id
  );
  