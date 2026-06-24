with source as (
    select * from {{ source('raw', 'countries') }}
)

select
    country_id,
    country_name,
    country_code,
    confederation,
    total_clubs,
    total_players,
    average_age,
    url
from source
