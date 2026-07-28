with home_perspective as (
    select *
    from {{ ref('fct_team_games_enriched') }}
    where venue = 'home'
),

away_perspective as (
    select *
    from {{ ref('fct_team_games_enriched') }}
    where venue = 'away'
)

select
    h.game_id,
    h.team_id as home_team_id,
    a.team_id as away_team_id
from home_perspective h
inner join away_perspective a
    on h.game_id = a.game_id
where h.team_id <> a.opponent_id
   or h.opponent_id <> a.team_id
   or h.goals_for <> a.goals_against
   or h.goals_against <> a.goals_for
   or h.goal_difference <> -a.goal_difference
   or h.total_goals <> a.total_goals
   or h.attendance is distinct from a.attendance
   or (
       h.result = 'win'
       and a.result <> 'loss'
   )
   or (
       h.result = 'loss'
       and a.result <> 'win'
   )
   or (
       h.result = 'draw'
       and a.result <> 'draw'
   )
