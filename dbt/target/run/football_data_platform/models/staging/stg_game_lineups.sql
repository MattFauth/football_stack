
  create view "football"."staging"."stg_game_lineups__dbt_tmp"
    
    
  as (
    with source as (
    select * from "football"."raw"."game_lineups"
)

select
    game_lineups_id,
    cast(date as date) as game_date,
    game_id,
    player_id,
    club_id as team_id,
    player_name,
    type as lineup_type,
    position,
    number as jersey_number,
    cast(team_captain as integer) as is_team_captain
from source
  );