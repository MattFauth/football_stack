select
    game_id,
    score_format
from {{ ref('fct_games') }}
where competition_id = 'FIWC'
  and not score_reconciled
