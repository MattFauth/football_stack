
  
    

  create  table "football"."marts"."dim_teams__dbt_tmp"
  
  
    as
  
  (
    with teams as (
    select * from "football"."core"."int_teams"
)

select
    team_id,
    team_name,
    team_code,
    team_type,
    total_market_value,
    squad_size,
    average_age,
    foreigners_number,
    foreigners_percentage,
    coach_name,
    last_season,
    url
from teams
  );
  