/*
  exclude those [ends before I starts] and [starts after I ended]
  only look at those which [starts before I ended] and [ends after I starts]
*/
  SELECT
    r.REQUEST_ID, t.USER_CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT,
    r.REQUEST_DATE, r.ACTUAL_COMPLETION_DATE,
    --round((r.ACTUAL_COMPLETION_DATE-r.REQUEST_DATE)*24*60, 2) AS total_duration,
    round((r.ACTUAL_START_DATE-r.REQUEST_DATE)*24*60, 2) AS delay_start,
    round((r.ACTUAL_COMPLETION_DATE-r.ACTUAL_START_DATE)*24*60, 2) AS actual_run,
   Nvl2(r.CONTROLLING_MANAGER,
     (select q.CONCURRENT_QUEUE_NAME
       from apps.FND_CONCURRENT_PROCESSES ps, apps.FND_CONCURRENT_QUEUES_TL q
       where ps.CONCURRENT_PROCESS_ID=r.CONTROLLING_MANAGER
         and q.CONCURRENT_QUEUE_ID=ps.CONCURRENT_QUEUE_ID
         and q.APPLICATION_ID=ps.QUEUE_APPLICATION_ID
         and q.LANGUAGE=UserEnv('LANG')
     ),
     (select Max(q.USER_CONCURRENT_QUEUE_NAME)||(CASE WHEN Count(1)>1 THEN ' ['||Max(r.REQUEST_ID)||']' END)
      from apps.FND_CONCURRENT_WORKER_REQUESTS w, apps.FND_CONCURRENT_QUEUES_TL q
      where w.REQUEST_ID=r.REQUEST_ID
        and w.CONCURRENT_QUEUE_NAME NOT IN ('FNDCRM','STANDARD')
        and q.CONCURRENT_QUEUE_ID=w.CONCURRENT_QUEUE_ID
        and q.APPLICATION_ID=w.QUEUE_APPLICATION_ID
        and q.LANGUAGE=UserEnv('LANG')
     )||'*'
   ) AS MGR,
   Decode(r.HOLD_FLAG, 'Y','HOLD:', 'N',NULL, NULL,NULL,
     HOLD_FLAG||':'
   )||Decode(r.PHASE_CODE, 'I','Inactive', 'P','Pending',
     'R','<font color=blue><b>Running</b></font>',
     'C','Completed',
     r.PHASE_CODE
   )||Decode(r.CANCEL_OR_HOLD,
     'H','*'/*NoDetails or SubReq is still running*/,
     'C',':Cancel', NULL,NULL,
     CANCEL_OR_HOLD||':'
   )||Decode(p.ENABLED_FLAG,
     'N','-Inactive', NULL
   ) PHASE,
   Decode(r.STATUS_CODE,
     'I','Scheduled', 'A','Waiting', 'Q','Standby',
     'D','Cancelled', 'U','Disabled', 'H','On Hold',
     'W','Paused', 'S','Suspended', 'B','Resuming',
     'T','Terminating', 'X','Terminated',
     'R','Normal'/*phase:running*/, 'C','Normal'/*phase:completed*/,
     'G','Warning', 'E','Error:'||r.COMPLETION_TEXT, 'M','No Manager',
     r.STATUS_CODE
   )||Decode(p.ENABLED_FLAG,
     'N','-Disabled', NULL
   ) STATUS,
   (r.RESUBMIT_INTERVAL||' '||decode(r.RESUBMIT_INTERVAL_UNIT_CODE,
     'MINUTES','min ', 'HOURS','hr ', 'DAYS','day ',
     'WEEKS','w ', 'MONTHS','mth ',
    r.RESUBMIT_INTERVAL_UNIT_CODE)||c.CLASS_TYPE
   ) SCHD
  FROM apps.FND_CONCURRENT_PROGRAMS_TL t, apps.FND_CONCURRENT_PROGRAMS p,
    apps.FND_CONCURRENT_REQUESTS r, apps.FND_USER u, apps.FND_CONC_RELEASE_CLASSES c
  WHERE p.APPLICATION_ID = r.PROGRAM_APPLICATION_ID

    --AND t.USER_CONCURRENT_PROGRAM_NAME LIKE  '....'
    --AND r.REQUEST_ID > (SELECT Max(REQUEST_ID)-1000 FROM apps.FND_CONCURRENT_REQUESTS)

    AND r.ACTUAL_START_DATE > '07-JUN-2018 02:30:00'
    AND r.ACTUAL_COMPLETION_DATE < '13-JUN-2018 10:00:00'
    AND Upper(t.USER_CONCURRENT_PROGRAM_NAME) LIKE  '%...%'

    AND p.CONCURRENT_PROGRAM_ID = r.CONCURRENT_PROGRAM_ID
    AND p.APPLICATION_ID = t.APPLICATION_ID
    AND p.CONCURRENT_PROGRAM_ID = t.CONCURRENT_PROGRAM_ID
    AND t.LANGUAGE = 'US'
    AND c.RELEASE_CLASS_ID(+)=r.RELEASE_CLASS_ID
    AND c.APPLICATION_ID(+)=r.RELEASE_CLASS_APP_ID
    AND u.USER_ID=r.REQUESTED_BY
  ORDER BY REQUESTED_START_DATE desc
