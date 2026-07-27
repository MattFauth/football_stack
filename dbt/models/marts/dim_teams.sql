with teams as (
    select * from {{ ref('int_teams') }}
)

select
    team_id,
    team_name,
    team_code,
    team_type,
    is_inferred,
    total_market_value,
    squad_size,
    average_age,
    foreigners_number,
    foreigners_percentage,
    coach_name,
    last_season,
    url
from teams
