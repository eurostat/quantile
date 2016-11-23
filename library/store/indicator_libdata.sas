*  Begin EG generated code (do not edit this line);
*
*  Stored process registered by
*  Enterprise Guide Stored Process Manager V7.1
*
*  ====================================================================
*  Stored process name: indicator_libdata
*  ====================================================================
*
*  Stored process prompt dictionary:
*  ____________________________________
*  PROMPT_LIBDATA
*       Type: Text
*      Label: Data library
*       Attr: Visible, Required
*    Default: System.Collections.ArrayList
*  ____________________________________
*;


*ProcessBody;

%global PROMPT_LIBDATA;

%STPBEGIN;

*  End EG generated code (do not edit this line);


/* --- Start of code for "Program". --- 
%_eg_conditional_dropds(WORK.QUERY_FOR_INDICATOR_CODES);
*/
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_INDICATOR_CODES AS 
   SELECT t1.code
      FROM SILCFMT.INDICATOR_CODES_&prompt_libdata as t1;
QUIT;

/* --- End of code for "Program". --- */

*  Begin EG generated code (do not edit this line);
;*';*";*/;quit;
%STPEND;

*  End EG generated code (do not edit this line);

