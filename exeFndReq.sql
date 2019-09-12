
-- !! THE BELOW ONLY WORKS UNDER APPS LOGIN !!! --

DECLARE
  reqID number;
  appl VARCHAR2(30);
  prog VARCHAR2(240);
  dscr VARCHAR2(240);
  start_time date;
  subreq BOOLEAN;

  PROCEDURE init_fnd(p_user VARCHAR2, p_resp VARCHAR2) AS
    l_user NUMBER;  l_resp NUMBER;   l_appl NUMBER;
  BEGIN
    --'How To Run the FND_GLOBAL.APPS_INITIALIZE Using A User Other Than APPS [ID 822225.1]'
    IF sys_context('USERENV','SESSION_USER')<>'APPS' THEN
      Dbms_Output.put_line('Warning! init_fnd() will only working properly under apps logon.');
    END IF;

    Dbms_Output.put_line('SESSION_ID: '||fnd_global.SESSION_ID);
    IF fnd_global.SESSION_ID<>-1 THEN
      Dbms_Output.put_line('Has already initialized! Skip re-initialization. That seems only work correctly if you disconnect??');
      RETURN;
    END IF;

    SELECT USER_ID INTO l_user FROM applsys.FND_USER WHERE USER_NAME=p_user;

    SELECT r.RESPONSIBILITY_ID, r.APPLICATION_ID INTO l_resp, l_appl
    FROM applsys.FND_RESPONSIBILITY_TL r
    WHERE r.RESPONSIBILITY_NAME=p_resp AND r.LANGUAGE='US';

    fnd_global.apps_initialize(l_user, l_resp, l_appl);
  END init_fnd;

  PROCEDURE wait_for_request(p_request_id NUMBER, p_check_interval NUMBER DEFAULT 1, p_timeout NUMBER DEFAULT NULL) AS
    l_complete BOOLEAN;
    l_complete_text VARCHAR2(10):='False';
    l_phase_text VARCHAR2(20);
    l_status_text VARCHAR2(20);
    l_phase_code VARCHAR2(20);
    l_status_code VARCHAR2(20);
    l_message VARCHAR2 (200);
  BEGIN
    l_complete := apps.FND_CONCURRENT.wait_for_request(
      p_request_id, p_check_interval, p_timeout,
      l_phase_text, l_status_text, l_phase_code, l_status_code, l_message
    );
    IF l_complete THEN l_complete_text := 'True'; END IF;
    Dbms_Output.put_line('ReqID#'||p_request_id||': '||l_message);
    Dbms_Output.put_line(
      ' Complete='||l_complete_text||'; Phase='||l_phase_text||'; Status='||l_status_text
        --||'; Phase='||l_phase_code||'; Status='||l_status_code
    );
  END;

  FUNCTION getLogFileUrl(p_request_id NUMBER)
  RETURN VARCHAR2 AS
  BEGIN
    -- http://challaappsworld.blogspot.com/2015/04/how-to-get-concurrent-program-output.html
    RETURN FND_WEBFILE.get_url(
      file_type   => FND_WEBFILE.request_log,
      ID          => p_request_id,
      gwyuid      => FND_PROFILE.value ('GWYUID'),   -- 'APPLSYSPUB/PUB'
      two_task    => FND_PROFILE.value ('TWO_TASK'), -- '<instanceID>'
      expire_time => 500 -- minutes, security!.
    );
  END;

  PROCEDURE getLogFile(p_request_id NUMBER) AS
    l_LOGFILE_NODE_NAME VARCHAR2(256);
    l_LOGFILE_NAME VARCHAR2(255);
  BEGIN
   /*
    SELECT r.LOGFILE_NODE_NAME, r.LOGFILE_NAME
    INTO l_LOGFILE_NODE_NAME, l_LOGFILE_NAME
    FROM apps.FND_CONCURRENT_REQUESTS r
    WHERE r.REQUEST_ID = p_request_id;

    Dbms_Output.put_line(l_LOGFILE_NODE_NAME);
    Dbms_Output.put_line(l_LOGFILE_NAME);
   */

    Dbms_Output.put_line(getLogFileUrl(p_request_id));
  END;

BEGIN
  /*
  --  Below is to load the $PROFILE$.?? information
  --  [available under Help->Diagnonis->Examine]
  */

  init_fnd('<userName>', '<respName>');

  /*
  --  Ready to submit the request
  */

  appl := 'INV';              -- Oracle Inventory
  prog := 'MTL_CCEOI_IMPORT'; -- Import cycle count entries from open interface
  dscr := prog;
  start_time := SYSDATE;
  subreq := FALSE;

  reqID := FND_REQUEST.SUBMIT_REQUEST (appl, prog, dscr, start_time, subreq,
             21, -- select SELECT * FROM apps.MTL_CYCLE_COUNT_HEADERS
              1,
              1,
             '',
              2  -- Do not delete processed records
           );
  if (reqID = 0) then
    FND_MESSAGE.RETRIEVE(dscr);
    dbms_output.put_line('Failed on SUBMIT_REQUEST() !! ' || dscr);
    /* Handle submission error */
    rollback;
    RETURN;
  end if;

  dbms_output.put_line('Submitted request_id: '|| reqID || ' !!');
  commit; -- must commit for the concurrent manager to process this !

  wait_for_request(reqID);
  getLogFile(reqID);

END;

