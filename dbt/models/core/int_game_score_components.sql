with games as (
    select * from {{ ref('stg_games') }}
),

events_by_game as (
    select
        cast(events.game_id as integer) as game_id,
        count(*) as event_count,
        count(*) filter (
            where event_type = 'Goals'
        ) as match_event_goals,
        count(*) filter (
            where event_type = 'Shootout'
        ) as shootout_attempts,
        count(*) filter (
            where event_type = 'Shootout'
              and description ilike '%Scored%'
        ) as shootout_goals,
        count(*) filter (
            where event_type = 'Shootout'
              and description ilike '%Scored%'
              and cast(team_id as integer) = games.home_club_id
        ) as home_team_shootout_goals,
        count(*) filter (
            where event_type = 'Shootout'
              and description ilike '%Scored%'
              and cast(team_id as integer) = games.away_club_id
        ) as away_team_shootout_goals
    from {{ ref('stg_game_events') }} as events
    inner join games
        on cast(events.game_id as integer) = games.game_id
    group by cast(events.game_id as integer)
),

classified as (
    select
        games.*,
        events_by_game.event_count,
        events_by_game.match_event_goals,
        events_by_game.shootout_attempts,
        events_by_game.shootout_goals,
        events_by_game.home_team_shootout_goals,
        events_by_game.away_team_shootout_goals,
        case
            when events_by_game.event_count is null
                then 'no_event_data'
            when coalesce(events_by_game.shootout_attempts, 0) = 0
                then 'no_shootout'
            when
                games.home_club_goals + games.away_club_goals
                = (
                    events_by_game.match_event_goals
                    + events_by_game.shootout_goals
                )
                then 'includes_shootout'
            when
                games.home_club_goals + games.away_club_goals
                = events_by_game.match_event_goals
                then 'excludes_shootout'
            else 'unreconciled_shootout'
        end as score_format
    from games
    left join events_by_game
        on games.game_id = events_by_game.game_id
)

select
    game_id,
    event_count is not null as event_data_available,
    case
        when event_count is null then null
        else coalesce(shootout_attempts, 0) > 0
    end as went_to_shootout,
    case
        when event_count is null then null
        else coalesce(home_team_shootout_goals, 0)
    end as home_team_shootout_goals,
    case
        when event_count is null then null
        else coalesce(away_team_shootout_goals, 0)
    end as away_team_shootout_goals,
    case
        when score_format in ('no_shootout', 'excludes_shootout')
            then home_club_goals
        when score_format = 'includes_shootout'
            then home_club_goals - coalesce(home_team_shootout_goals, 0)
        else null
    end as home_team_goals_excl_shootout,
    case
        when score_format in ('no_shootout', 'excludes_shootout')
            then away_club_goals
        when score_format = 'includes_shootout'
            then away_club_goals - coalesce(away_team_shootout_goals, 0)
        else null
    end as away_team_goals_excl_shootout,
    case
        when event_count is null then null
        when score_format in (
            'no_shootout',
            'includes_shootout',
            'excludes_shootout'
        )
            then match_event_goals = (
                case
                    when score_format = 'includes_shootout'
                        then
                            home_club_goals
                            + away_club_goals
                            - coalesce(shootout_goals, 0)
                    else home_club_goals + away_club_goals
                end
            )
        else false
    end as score_reconciled,
    score_format
from classified
