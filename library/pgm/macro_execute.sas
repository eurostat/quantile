/** 
## macro_execute {#sas_macro_execute}
Execute a macro with its arguments.

	%macro_execute(macro_name, macro_arguments... );
	%let ... =%macro_execute(macro_name, macro_arguments... );

### Arguments
* `macro_name` : name of the macro (whose existence will be checked) to run; if the macro does 
	not exist, do nothing;
* `macro_arguments...` : (_option_) whatever additional (positional or keyword) arguments taken 
	by the macro `%&macro_name`.

### Returns
... whatever the original macro `%&macro_name` returns.

### Note
The macro `%%macro_execute` does not test the actual existence of `macro_name`. 	
Therefore, this macro should be combined together with `%%macro_exist` prior to its use, _e.g._
to be ran as:

 	%macro_exist(&macro_name, _ans_=ans);
	%if %error_handle(ErrorInputParameter, &ans EQ 0, txt=!!! Input macro not found !!!) %then
		%goto exit;
	%else
		%macro_execute(&macro_name, &macro_arguments);

### See also
[%macro_exist](@ref sas_macro_exist), 
[CxMacro](http://www.sascommunity.org/wiki/Routine_CxMacro),
[CxInclud](http://www.sascommunity.org/wiki/Routine_CxInclude),
[CallMacr](http://www.sascommunity.org/wiki/Macro_CallMacr).
*/ /** \cond */


%macro macro_execute/parmbuff;
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%local SEP	/* string separator used in syspbuff */
		DEBUG; 	/* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else								%let DEBUG=0;
	%let SEP=%str(,);

	%if %error_handle(ErrorInputParameter, 
			&syspbuff  EQ , mac=&_mac,		
			txt=!!! Missing input parameters !!!) %then 
		%goto exit;
	
	%local ans		/* output of the macro existence test */
		macro_name 	/* macro name */
		arguments;	/* list of arguments to be passed to the macro */
	%let ans=;

	/* get rid of the parentheses */
	%let syspbuff=%sysfunc(substr(&syspbuff, 2, %eval(%sysfunc(length(&syspbuff))-2)));

	/* retrieve the macro_name */
	%let macro_name=%scan(%quote(&syspbuff), 1, &SEP);
		
	/* the call to macro_exist here prevents the call to macros that return results */
	/*%macro_exist(&macro_name, _ans_=ans, verb=yes);
	%if %error_handle(ErrorInputParameter,
			&ans EQ 0, mac=&_mac,		
			txt=!!! Input macro not found !!!) %then
		%goto exit;
	/* else: proceed ... */

	/* retrieve the arguments */
 	%let arguments=%list_slice(%quote(&syspbuff), ibeg=2, sep=&SEP);

	/* run (execute) the desired macro with its arguments */
	%&macro_name(%unquote(&arguments))

	%exit: 
	/* %return; */
%mend macro_execute;


%macro _example_macro_execute;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var ans;

	%put;
	%put (i) Test a dummy macro;
	%macro_exist(_DUMMY_, _ans_=ans);
	%if not %error_handle(ErrorInputMacro, &ans EQ 0, txt=!!! Input macro not found !!!) %then
		%macro_execute(_DUMMY_,1, 2,3); /* should not happen */

	%macro test1(a, b, _c_=);
		%let var=&a &b &_c_;
	%mend;

	%put;
	%put (ii) Test a simple macro;
	%macro_execute(test1, 1, 2, _c_=c);
	%if &var=1 2 c %then 	%put OK: TEST PASSED - Macro test1 found and ran;
	%else 					%put ERROR: TEST FAILED - Macro test1 not found and/or not ran;

	%macro test2(a, b, _c_=);
		&a &b &_c_
	%mend;

	%put;
	%put (iii) Test a simple macro that returns an output;
	%let var=%macro_execute(test2, 1, 2, _c_=c);
	%if &var=1 2 c %then 	%put OK: TEST PASSED - Macro test2 found and ran;
	%else 					%put ERROR: TEST FAILED - Macro test2 not found and/or not ran;

	%put;
	%put (iv) Test a macro from the PING library;
	%let var=%macro_execute(list_length, %quote(a_b_c_d), sep=%str(_));
	%if &var=4 %then 	%put OK: TEST PASSED - Macro list_length found and ran;
	%else 				%put ERROR: TEST FAILED - Macro list_length not found and/or not ran;

	%put;
%mend _example_macro_execute;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_macro_execute; 
*/


%macro _bass_execute_macro(macroname);
   	%let debug=0;

   	%if (%superq(macroname) eq ) %then %return;
   	%let fullname=&macroname;
   	%let macroname=%scan(&macroname,1,%str(%());

	/* is the macro pre-compiled in work.sasmacr (or work.sasmac1, work.sasmac2, etc) */
	%if (%sysmacexist(&macroname)) %then %do;
		%put SYSMACEXIST: &macroname;
	    %&fullname
	    %return;
	%end;

   	/* is SASMSTORE active?  If so, is the macro pre-compiled there? 
   	* Assume the SASMSTORE catalog name is sasmacr */
   	%let option_mstored   = %sysfunc(getoption(mstored));
   	%let option_sasmstore = %sysfunc(getoption(sasmstore));
   	%if (&debug) %then %put &=option_sasmstore &=option_mstored;
   	%if ((&option_mstored eq MSTORED) and (%length(&option_sasmstore) gt 0)) %then %do;
      	%if (%sysfunc(cexist(&option_sasmstore..sasmacr.&macroname..MACRO))) %then %do;
         	%put SASMSTORE: %upcase(&option_sasmstore..&macroname..MACRO);
         	%&fullname
         	%return;
      	%end;
   	%end;

   	/* is it an autocall macro? */
   	%let rx1=%sysfunc(prxparse(/^\%str(%()(.*)\%str(%))$/));  %* remove leading and trailing parentheses ;
   	%let rx2=%sysfunc(prxparse(/('.*?'|".*?"|\S+)/));  %* return single|double-quoted string, or non-space tokens ;
   	%if (&debug) %then %put &=rx1 &=rx2;

   	/* get sasautos setting */
   	%let sasautos=%sysfunc(strip(%sysfunc(getoption(sasautos))));
   	%if (&debug) %then %put &=sasautos;

   	/* remove leading and trailing parentheses if present */
   	%if (%sysfunc(prxmatch(&rx1,%superq(sasautos)))) %then %let sasautos=%sysfunc(prxposn(&rx1,1,%superq(sasautos)));
   	%if (&debug) %then %put &=sasautos;

   	/* now parse the sasautos setting */
   	%let start=1;
   	%let stop=%length(%superq(sasautos));
   	%let position=0;
   	%let length=0;
   	%syscall prxnext(rx2, start, stop, sasautos, position, length);
   	%if (&debug) %then %put &=start &=stop &=position &=length;

   	%do %while (&position gt 0);
      	%let found = %substr(%superq(sasautos), &position, &length);
      	%if (&debug) %then %put &=found &=position &=length;

      	%if (%superq(found) eq %str(,)) %then %goto skip;

      	%* If a physical pathname then allocate a temporary fileref ;
      	%* If a fileref then just use that one ;
      	%if (%sysfunc(indexc(&found,%str(%"%')))) %then %do;
         	%let fileref=________;
         	%let rc=%sysfunc(filename(fileref,&found));
      	%end;
      	%else %do;
         	%let fileref=&found;
      	%end;

      	%let dir_handle=%sysfunc(dopen(&fileref));
      	%if (&dir_handle ne 0) %then %do;
         	%let mem_handle=%sysfunc(mopen(&dir_handle,&macroname..sas,i));
         	%if (&mem_handle ne 0) %then %do;
            	%put SASAUTOS: %sysfunc(pathname(&fileref))/&macroname..sas;
            	%&fullname
            	%goto cleanup;
            	%return;  %* should never execute but does not hurt ;
         	%end;
         	%let rc=%sysfunc(dclose(&dir_handle));
         	%if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));
      	%end;

      	%* Next token ;
      	%skip:
      	%syscall prxnext(rx2, start, stop, sasautos, position, length);      
   	%end;

   	%cleanup: 
   	%if (&mem_handle ne 0) %then %let rc=%sysfunc(fclose(&mem_handle));
   	%if (&dir_handle ne 0) %then %let rc=%sysfunc(dclose(&dir_handle));
   	%if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));

   	%syscall prxfree(rx1);
   	%syscall prxfree(rx2);
   	%return;
%mend _bass_execute_macro;


/** \endcond */
