select
    game_id,
    home_team_goals,
    away_team_goals,
    home_team_goals_excl_shootout,
    away_team_goals_excl_shootout,
    home_team_shootout_goals,
    away_team_shootout_goals
from {{ ref('fct_games') }}
where went_to_shootout
  and score_reconciled
  and (
      (
          score_format = 'includes_shootout'
          and (
              home_team_goals
                  <> home_team_goals_excl_shootout
                      + home_team_shootout_goals
              or away_team_goals
                  <> away_team_goals_excl_shootout
                      + away_team_shootout_goals
          )
      )
      or (
          score_format = 'excludes_shootout'
          and (
              home_team_goals <> home_team_goals_excl_shootout
              or away_team_goals <> away_team_goals_excl_shootout
          )
      )
      or home_team_goals_excl_shootout < 0
      or away_team_goals_excl_shootout < 0
  )
