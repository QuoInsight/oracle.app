/*
  Application: Validation : Set          [FND_FLEX_VALUE_SETS]
  Application: Flexfield  : Key          [FND_ID_FLEXS]
  Application: Flexfield  : Descriptive  [FND_DESCRIPTIVE_FLEXS_VL]
*/
SELECT 
 ffv.VALUE_CATEGORY, ffv.FLEX_VALUE, 
 ffv.ATTRIBUTE1, ffvt.DESCRIPTION
FROM apps.FND_FLEX_VALUE_SETS ffvs, apps.FND_FLEX_VALUES ffv, apps.FND_FLEX_VALUES_TL ffvt
WHERE ffvs.FLEX_VALUE_SET_NAME='?????' 
 AND ffv.ENABLED_FLAG='Y' AND ffvt.LANGUAGE(+)='US'
 AND ffv.FLEX_VALUE_SET_ID=ffvs.FLEX_VALUE_SET_ID 
 AND ffvt.FLEX_VALUE_ID(+)=ffv.FLEX_VALUE_ID
ORDER BY 1, 2
