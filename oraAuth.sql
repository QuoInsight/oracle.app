/*
 select
  apps.fnd_web_sec.validate_login(user,passw)
 from dual;

 select
  apps.fnd_web_sec.change_password('<userName>','<password>'),
  apps.fnd_message.get()
 from dual;
*/

declare
  usr varchar2(20); pwd varchar2(20); returnVal VARCHAR(255);
  i number;

begin
  usr := '<userName>';  pwd := '<password>';

  -- check user account
  SELECT
    u.user_name||'; '||u.description||'; '||(SELECT p.employee_number
       FROM apps.PER_PEOPLE_F p WHERE p.person_id=u.employee_id)||Chr(10)||
    'Notes: '||u.fax||Chr(10)||Chr(10)||
    'AcctDisabled = '||To_Char(u.end_date)||Chr(10)||
    --The below applies to 11.5.10
    --'Account Locked = '||Decode(u.encrypted_user_password,'INVALID','Y','N')||Chr(10)||
    'PasswdDate = '||Nvl(To_Char(u.password_date),'*expired*')||Chr(10)||
    'LastSuccess = '||u.last_logon_date||Chr(10)||
    'LastFail(Apps) = '||(SELECT Max(f.failure_date)
       FROM icx.icx_failures f WHERE Upper(f.user_name)=u.user_name)||Chr(10)||
    'LastFail = '||(SELECT Max(l.attempt_time) FROM apps.fnd_unsuccessful_logins l
       WHERE l.user_id=u.user_id)
  INTO returnVal
  FROM fnd_user u WHERE u.user_name=Upper(usr);

  FOR i IN 1 .. trunc(Length(returnVal)/255)+1 LOOP
    dbms_output.put_line(SubStr(returnVal,(i-1)*255,254));
  END LOOP;

RETURN;

  -- validate password
  returnVal := apps.fnd_web_sec.validate_login(usr,pwd)
    ||chr(10)||apps.fnd_message.get();
  dbms_output.put_line('Password Verified = '||returnVal);

RETURN;

  -- reset account
  IF returnVal LIKE '%Invalid application User Name' THEN
    update fnd_user set end_date=null where user_name=upper(usr);
    COMMIT;
  END IF;

  -- reset password
  returnVal := apps.fnd_web_sec.change_password(usr,pwd);
  dbms_output.put_line(
    'Password Changed = '||returnVal||chr(10)||apps.fnd_message.get()
  );
  IF returnVal='Y' THEN
    --make password expires, force user to change it
    update fnd_user set password_date=null where user_name=upper(usr);
    COMMIT;
  END IF;

 /*
  fnd_user_pkg.disableuser('<userName>');
  --update fnd_user set end_date=sysdate where user_name='<userName>'
  --update fnd_user set end_date=null where user_name='<userName>'
 */

 /*
  apps.fnd_user_pkg.addresp(
    username       => '<userName>',
    resp_app       => 'SYSADMIN',
    resp_key       => 'SYSTEM_ADMINISTRATOR',
    security_group => 'STANDARD',
    description    => '',
    start_date     => SYSDATE-1,
    end_date       => SYSDATE+365
  );
 */
end;
