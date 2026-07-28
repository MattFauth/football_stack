with perspectives_by_game as (
    select
        game_id,
        count(*) as perspective_count,
        count(distinct team_id) as team_count,
        count(*) filter (where venue = 'home') as home_count,
        count(*) filter (where venue = 'away') as away_count
    from {{ ref('fct_team_games_enriched') }}
    group by game_id
)

select *
from perspectives_by_game
where perspective_count <> 2
   or team_count <> 2
   or home_count <> 1
   or away_count <> 1
