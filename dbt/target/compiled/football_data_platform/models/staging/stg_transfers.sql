with source as (
    select * from "football"."raw"."transfers"
)

select
    player_id,
    cast(transfer_date as date) as transfer_date,
    transfer_season,
    from_club_id,
    to_club_id,
    from_club_name,
    to_club_name,
    transfer_fee,
    cast(market_value_in_eur as numeric) as market_value_in_eur,
    player_name
from source