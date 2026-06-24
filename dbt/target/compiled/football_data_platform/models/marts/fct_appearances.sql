with appearances as (
    select * from "football"."staging"."stg_appearances"
),

games as (
    select * from "football"."staging"."stg_games"
)

select
    a.appearance_id,
    a.game_id,
    g.game_date,
    g.season,
    a.player_id,
    a.player_club_id as team_id,
    a.yellow_cards,
    a.red_cards,
    a.goals,
    a.assists,
    a.minutes_played
from appearances a
left join games g on a.game_id = g.game_id