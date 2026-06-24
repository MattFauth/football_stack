with transfers as (
    select * from "football"."staging"."stg_transfers"
)

select
    player_id,
    transfer_date,
    transfer_season,
    from_club_id as from_team_id,
    to_club_id as to_team_id,
    transfer_fee,
    market_value_in_eur
from transfers