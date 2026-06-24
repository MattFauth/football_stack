with source as (
    select * from {{ source('raw', 'player_valuations') }}
)

select
    player_id,
    cast(date as date) as valuation_date,
    cast(market_value_in_eur as numeric) as market_value_in_eur,
    current_club_name,
    current_club_id,
    player_club_domestic_competition_id
from source
