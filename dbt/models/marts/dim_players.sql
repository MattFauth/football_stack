with players as (
    select * from {{ ref('stg_players') }}
),

historical_players as (
    select
        a.player_id,
        max(nullif(a.player_name, '')) as player_name
    from {{ ref('stg_appearances') }} a
    left join players p on a.player_id = p.player_id
    where p.player_id is null
    group by a.player_id
),

all_players as (
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
        url,
        false as is_inferred
    from players

    union all

    select
        player_id,
        cast(null as text) as first_name,
        cast(null as text) as last_name,
        coalesce(player_name, 'Unknown player ' || player_id::text) as player_name,
        cast(null as text) as popular_name,
        cast(null as text) as player_code,
        cast(null as text) as country_of_birth,
        cast(null as text) as city_of_birth,
        cast(null as text) as country_of_citizenship,
        cast(null as date) as date_of_birth,
        cast(null as text) as sub_position,
        cast(null as text) as position,
        cast(null as text) as dominant_foot,
        cast(null as integer) as height_in_cm,
        cast(null as numeric) as market_value_in_eur,
        cast(null as numeric) as highest_market_value_in_eur,
        cast(null as text) as agent_name,
        cast(null as text) as image_url,
        cast(null as text) as url,
        true as is_inferred
    from historical_players
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
    dominant_foot,
    height_in_cm,
    market_value_in_eur,
    highest_market_value_in_eur,
    agent_name,
    image_url,
    url,
    is_inferred
from all_players
