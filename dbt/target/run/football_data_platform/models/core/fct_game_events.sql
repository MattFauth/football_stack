
  
    

  create  table "football"."core"."fct_game_events__dbt_tmp"
  
  
    as
  
  (
    with events as (
    select * from "football"."staging"."stg_game_events"
)

select
    game_event_id,
    game_id,
    event_date,
    minute,
    event_type,
    team_id,
    player_id,
    description,
    player_in_id,
    player_assist_id
from events
  );
  