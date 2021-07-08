SELECT
  we.NAME, we.STATUS event_status,
  wes.RULE_FUNCTION,
  wes.STATUS subscription_status,
  nvl(wes.PHASE,0) subscription_phase,
  wes.LICENSED_FLAG subscription_licensed_flag,
  we.LICENSED_FLAG event_licensed_flag
FROM apps.WF_EVENTS we, apps.WF_EVENT_SUBSCRIPTIONS wes
WHERE we.STATUS='ENABLED' AND wes.STATUS='ENABLED'
  AND wes.EVENT_FILTER_GUID = we.GUID
  --AND we.NAME like 'oracle.apps.wsh.delivery%'
  AND Upper(wes.RULE_FUNCTION) LIKE '%XX%'
ORDER BY 1, 3
