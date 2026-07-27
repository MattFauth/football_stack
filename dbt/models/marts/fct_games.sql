with games as (
    select * from {{ ref('stg_games') }}
),

teams as (
    select * from {{ ref('int_teams') }}
),

score_components as (
    select * from {{ ref('int_game_score_components') }}
)

select
    g.game_id,
    g.season,
    g.game_date,
    g.competition_id,
    g.round,
    g.home_club_id as home_team_id,
    th.team_name as home_team_name,
    th.team_type as home_team_type,
    g.away_club_id as away_team_id,
    ta.team_name as away_team_name,
    ta.team_type as away_team_type,
    g.home_club_goals as home_team_goals,
    g.away_club_goals as away_team_goals,
    sc.home_team_goals_excl_shootout,
    sc.away_team_goals_excl_shootout,
    sc.home_team_shootout_goals,
    sc.away_team_shootout_goals,
    sc.event_data_available,
    sc.went_to_shootout,
    sc.score_reconciled,
    sc.score_format,
    case
        when g.home_club_goals > g.away_club_goals then 'home_win'
        when g.home_club_goals < g.away_club_goals then 'away_win'
        else 'draw'
    end as game_result,
    case
        when sc.home_team_goals_excl_shootout
            > sc.away_team_goals_excl_shootout
            then 'home_win'
        when sc.home_team_goals_excl_shootout
            < sc.away_team_goals_excl_shootout
            then 'away_win'
        when sc.home_team_goals_excl_shootout is not null
            then 'draw'
        else null
    end as game_result_excl_shootout,
    g.stadium,
    g.attendance,
    g.referee,
    g.url
from games g
left join teams th on g.home_club_id = th.team_id
left join teams ta on g.away_club_id = ta.team_id
left join score_components sc on g.game_id = sc.game_id
