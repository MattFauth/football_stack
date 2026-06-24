
  
    

  create  table "football"."marts"."fct_games__dbt_tmp"
  
  
    as
  
  (
    with games as (
    select * from "football"."staging"."stg_games"
),

teams as (
    select * from "football"."core"."int_teams"
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
    case
        when g.home_club_goals > g.away_club_goals then 'home_win'
        when g.home_club_goals < g.away_club_goals then 'away_win'
        else 'draw'
    end as game_result,
    g.stadium,
    g.attendance,
    g.referee,
    g.url
from games g
left join teams th on g.home_club_id = th.team_id
left join teams ta on g.away_club_id = ta.team_id
  );
  