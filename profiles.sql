/*

  SELECT apps.FND_PROFILE.value('org_id')  FROM dual
  SELECT apps.FND_PROFILE.value('ACCOUNTING_CATEGORY_SET') FROM dual

  fnd_profile.put('XLA_MO_SECURITY_PROFILE_LEVEL','**FND_UNDEFINED_VALUE**'); --!!--[MO: Security Profile]--!!--
  fnd_profile.put('DEFAULT_ORG_ID',82); --!!--[MO: Default Operating Unit]--!!--
  fnd_profile.put('ORG_ID',82); --!!--[MO: Operating Unit]--!!--

  SELECT mo_global.get_ou_count,
   fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL'), -- MO: Security Profile
   fnd_profile.value('DEFAULT_ORG_ID'), -- MO: Default Operating Unit
   fnd_profile.value('ORG_ID'), -- MO: Operating Unit
   mo_global.check_access(null)
  FROM dual

*/
SELECT --a.application_name, p.profile_option_name,
  t.user_profile_option_name AS profile,
  Decode(v.level_id, '10001','SITE', '10002','APPL', '10003','RESP',
   '10004','USER', '10005','SERVER', '10006','ORG', To_Char(v.level_id))
  ||' ['||v.level_id||']' AS LEVEL_,
  Decode(v.level_id,
   '10002',(SELECT application_name FROM apps.FND_APPLICATION_TL
     WHERE language=userenv('LANG') AND application_id=v.level_value
   ),
   '10003',(SELECT responsibility_name FROM apps.FND_RESPONSIBILITY_TL
     WHERE language=userenv('LANG') AND responsibility_id=v.level_value AND (
       v.level_value_application_id IS NULL OR application_id=v.level_value_application_id
   )),
   '10004',(SELECT user_name FROM apps.FND_USER WHERE user_id=v.level_value),
   To_Char(v.level_value))
  ||' ['||v.level_value||']' AS LEVEL_VALUE,
  CASE WHEN p.profile_option_name IN ('CLIENT_TIMEZONE_ID','SERVER_TIMEZONE_ID') THEN (
    SELECT '(GMT '||GMT_OFFSET||') '||NAME FROM apps.FND_TIMEZONES_VL
    WHERE UPGRADE_TZ_ID=v.profile_option_value
   )||' ['||v.profile_option_value||']'
  ELSE v.profile_option_value
  END AS Value,
  v.LAST_UPDATE_DATE,
  u.USER_NAME AS LAST_UPDATED_BY
FROM apps.FND_PROFILE_OPTIONS p, apps.FND_PROFILE_OPTION_VALUES v,
  apps.FND_PROFILE_OPTIONS_TL t, apps.FND_APPLICATION_TL a,
  apps.FND_USER u
WHERE v.profile_option_id=p.profile_option_id
  AND v.application_id=p.application_id
  AND t.profile_option_name=p.profile_option_name
  AND t.language=userenv('LANG')
  AND a.language=USERENV('LANG')
  AND a.application_id=p.application_id
  AND u.USER_ID=v.LAST_UPDATED_BY
  --AND a.application_name='Oracle Inventory'
  --AND p.profile_option_name='INV_DEBUG_LEVEL'
  AND t.user_profile_option_name LIKE '%Debug%'
ORDER BY a.application_name, t.user_profile_option_name, v.level_id, 3
