with source as (
    select * from {{ source('raw', 'club_games') }}
)

select
    game_id,
    club_id as team_id,
    own_goals,
    own_position,
    own_manager_name as team_manager_name,
    opponent_id,
    opponent_goals,
    opponent_position,
    opponent_manager_name,
    hosting,
    is_win
from source
