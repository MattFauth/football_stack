with valuations as (
    select * from "football"."staging"."stg_player_valuations"
)

select
    player_id,
    valuation_date,
    market_value_in_eur,
    current_club_id as team_id,
    player_club_domestic_competition_id as competition_id
from valuations