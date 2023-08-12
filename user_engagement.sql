WITH eng AS
(SELECT 
u.id AS user_id,
u.email,
u.age,
u.gender,
u.country,
u.traffic_source,
CAST(u.created_at AS DATE) AS account_creation_date,
e.id AS event_id,
e.sequence_number,
e.session_id,
e.created_at AS event_creation_date,
e.browser,
e.traffic_source AS event_traffic_source,
e.uri AS url,
e.event_type
FROM bigquery-public-data.thelook_ecommerce.users u 
LEFT JOIN bigquery-public-data.thelook_ecommerce.events e
ON u.id = e.user_id
WHERE u.id = 67676),

user_metrics AS (
  SELECT
    user_id,
    MIN(event_creation_date) as first_event,
    MAX(event_creation_date) as last_event,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as total_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) as total_purchases
  FROM
    eng
  GROUP BY
    user_id
),

traffic_sources AS (
  SELECT
    user_id,
    traffic_source,
    COUNT(DISTINCT session_id) as sessions_per_source
  FROM
    eng
  GROUP BY
    user_id,
    traffic_source
),

browser_usage AS (
  SELECT
    user_id,
    browser,
    COUNT(DISTINCT session_id) as sessions_per_browser
  FROM
    eng
  GROUP BY
    user_id,
    browser
)

SELECT
  user_metrics.user_id,
  TIMESTAMP_DIFF(user_metrics.last_event, user_metrics.first_event, SECOND) as user_duration,
  user_metrics.total_events / user_metrics.total_sessions as average_events_per_session,
  user_metrics.total_sessions,
  user_metrics.total_purchases / user_metrics.total_sessions as conversion_rate,
  traffic_sources.traffic_source,
  traffic_sources.sessions_per_source,
  browser_usage.browser,
  browser_usage.sessions_per_browser
FROM
  user_metrics
LEFT JOIN
  traffic_sources
ON
  user_metrics.user_id = traffic_sources.user_id
LEFT JOIN
  browser_usage
ON
  user_metrics.user_id = browser_usage.user_id
