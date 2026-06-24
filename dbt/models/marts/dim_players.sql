with players as (
    select * from {{ ref('stg_players') }}
)

select
    player_id,
    first_name,
    last_name,
    player_name,
    popular_name,
    player_code,
    country_of_birth,
    city_of_birth,
    country_of_citizenship,
    date_of_birth,
    sub_position,
    position,
    foot as dominant_foot,
    height_in_cm,
    market_value_in_eur,
    highest_market_value_in_eur,
    agent_name,
    image_url,
    url
from players
