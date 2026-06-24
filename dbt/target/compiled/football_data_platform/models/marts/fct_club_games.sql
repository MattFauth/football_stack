with club_games as (
    select * from "football"."staging"."stg_club_games"
)

select
    game_id,
    team_id,
    own_goals,
    opponent_id,
    opponent_goals,
    hosting,
    is_win
from club_games