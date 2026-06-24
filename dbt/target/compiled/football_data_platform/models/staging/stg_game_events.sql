with source as (
    select * from "football"."raw"."game_events"
)

select
    game_event_id,
    cast(date as date) as event_date,
    game_id,
    cast(minute as integer) as minute,
    type as event_type,
    club_id as team_id,
    club_name as team_name,
    player_id,
    description,
    player_in_id,
    player_assist_id
from source