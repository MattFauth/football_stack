with lineups as (
    select * from "football"."staging"."stg_game_lineups"
)

select
    game_lineups_id,
    game_id,
    game_date,
    team_id,
    player_id,
    player_name,
    lineup_type,
    position,
    jersey_number,
    is_team_captain
from lineups