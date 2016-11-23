/** 
## macro_exist {#sas_macro_exist}
Verify the existence of a given macro by searching into the set of pre-compiled macros as well
as the content of all autocall libraries.

	%macro_exist(macro_name, _ans_=);

### Argument
`macro_name` : name of the macro to check the existence of; the macro may already be compiled 
	or would be brought in via `autocall`.

### Returns:
`_ans_` : name of the variable storing the result of the test, _e.g._:
		+ 1 when the macro `%%macro_name` is found in the catalog macros compiled for the current 
			session (_e.g._, catalog `WORK.SASMACR` or `WORK.SASMAC1`, see note below),
		+ 2 when it is found in the catalog of pre-compiled macros (_e.g._, catalog `WORK.MSTORE`),
		+ 3 when it is found in set of autocall macros (_i.e._, set through `SASAUTOS`),
		+ 0 otherwise.

### Notes
1. **The macro `%%macro_exist` is  an adaptation of S. Bass's original `%%execute_macro.sas` 
macro, so as to keep only the existence testing**. Original source code (no disclaimer) is 
available at <https://github.com/scottbass/SAS/blob/master/Macro/execute_macro.sas>. 
2. Given a macro name, we determine if it would be executed if invoked:
	- first check to see if it's pre-compiled: if not in compiled form, then 
	- try to locate in the list of all sasautos directories.
See reference 2 below.
3. Note that, with SAS version 9.3, the SAS-supplied macro `%%sysmacexist` checks for the existence 
of a macro in `WORK.SASMACR` and `SOURCE.SASMACR` only.  However, on Linux, esp. in EG, compiled 
macros are saved to `WORK.SASMAC1` instead of `WORK.SASMACR`. For SAS versions prior to 9.3, we 
implemented our own search macro (see reference 3 below).
4. See also R. Langston `%%macro_exists.sas` macro that searches for pre-compiled macros and all
autocall libraries.

### References
1. Langston, R. (2013): ["A macro to verify a macro exists"](http://support.sas.com/resources/papers/proceedings13/339-2013.pdf).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).
3. ["How to determine whether a macro exists within a SAS session"](http://support.sas.com/kb/36/360.html).

### See also
[%macro_execute](@ref sas_macro_execute),
[SYSMACEXIST](http://support.sas.com/documentation/cdl/en/mcrolref/62978/HTML/default/viewer.htm#n0xwysoo8i2j3kn13ls4thkn3xbp.htm).
*/ /** \cond */

%macro macro_exist(macroname
				, _ans_=
				, verb=no
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _ans
		DEBUG;
	%let _ans=;
	%local DEBUG; /* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 		%let DEBUG=&G_PING_DEBUG;
	%else									%let DEBUG=0;

   	%if %macro_isblank(macroname) /*(%superq(macroname) eq )*/ %then %goto exit;
   	%let fullname=&macroname;
   	%let macroname=%scan(&macroname, 1, %str(%());

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	%check_session_min93:
 	%if %sysevalf(&SYSVER >= 9.3) %then %do;
		/* is the macro pre-compiled in work.sasmacr (or work.sasmac1, work.sasmac2, etc) */
	   	%if (%sysmacexist(&macroname)) %then %do;
	      	%if %upcase("&verb")="YES" %then %put SYSMACEXIST: &macroname;
			%let _ans=1;
	      	%goto quit;
	   	%end;
	%end;
        
 	%check_store:
  	/* is SASMSTORE active?  If so, is the macro pre-compiled there? 
   	* assume the SASMSTORE catalog name is sasmacr */
   	%let option_mstored   = %sysfunc(getoption(MSTORED));
   	%let option_sasmstore = %sysfunc(getoption(SASMSTORE));
   	%if (&DEBUG) %then %put &=option_sasmstore &=option_mstored;
   	%if ((&option_mstored eq MSTORED) and (%length(&option_sasmstore) gt 0)) %then %do;
      	%if (%sysfunc(cexist(&option_sasmstore..sasmacr.&macroname..MACRO))) %then %do;
         	%if %upcase("&verb")="YES" %then %put SASMSTORE: %upcase(&option_sasmstore..&macroname..MACRO);
	 		%let _ans=2;
     		%goto quit;
      	%end;
   	%end;

  	%check_autocall:
  	/* is it an AUTOCALL macro? */
   	%let rx1=%sysfunc(prxparse(/^\%str(%()(.*)\%str(%))$/));  %* remove leading and trailing parentheses ;
   	%let rx2=%sysfunc(prxparse(/('.*?'|".*?"|\S+)/));  %* return single|double-quoted string, or non-space tokens ;
   	%if (&DEBUG) %then 	%put &=rx1 &=rx2;

   	/* get SASAUTOS setting */
   	%let sasautos=%sysfunc(strip(%sysfunc(getoption(SASAUTOS))));
   	%if (&DEBUG) %then 	%put &=sasautos;

   	/* remove leading and trailing parentheses if present */
   	%if (%sysfunc(prxmatch(&rx1,%superq(sasautos)))) %then %let sasautos=%sysfunc(prxposn(&rx1,1,%superq(sasautos)));
   	%if (&DEBUG) %then 	%put &=sasautos;

    /* now parse the sasautos setting */
   	%let start=1;
   	%let stop=%length(%superq(sasautos));
   	%let position=0;
   	%let length=0;
   	%syscall prxnext(rx2, start, stop, sasautos, position, length);
   	%if (&DEBUG) %then 	%put &=start &=stop &=position &=length;

   	%do %while (&position gt 0);
      	%let found = %substr(%superq(sasautos), &position, &length);
      	%if (&DEBUG) %then 	%put &=found &=position &=length;

      	%if (%superq(found) eq %str(,)) %then %goto skip;

      	/* if a physical pathname then allocate a temporary fileref 
      	* if a fileref then just use that one */
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
            	%if %upcase("&verb")="YES" %then %put SASAUTOS: %sysfunc(pathname(&fileref))/&macroname..sas;
		 		%let _ans=3;
            	%goto cleanup;
         	%end;
         	%let rc=%sysfunc(dclose(&dir_handle));
         	%if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));
      	%end;

      	/* next token */
      	%skip:
      	%syscall prxnext(rx2, start, stop, sasautos, position, length);      
   	%end;

   	%cleanup: 
   	%if (&mem_handle ne 0) %then %let rc=%sysfunc(fclose(&mem_handle));
   	%if (&dir_handle ne 0) %then %let rc=%sysfunc(dclose(&dir_handle));
   	%if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));

   	%syscall prxfree(rx1);
   	%syscall prxfree(rx2);

	%if not %macro_isblank(_ans) %then 	%goto quit;

	%check_session_max92:
 	%if %sysevalf(&SYSVER < 9.3) %then %do;
	 	/*	data macros;
	  		set sashelp.vcatalg;
	  		where libname='WORK' and memname='SASMAC1'
	    	and memtype='CATALOG' and objtype='MACRO';
		run; */
		%macro _macro_exist_insession(macro_name, _ans_=);  
			%local _tmp;
			%let _tmp=TMP&sysmacroname;
			PROC CATALOG cat=	%if %nrbquote(&sysscp)=%nrbquote(WIN) and %sysfunc(cexist(WORK.SASMACR)) %then %do;
									WORK.SASMACR
								%end;
								%else %if %sysfunc(cexist(WORK.SASMAC1)) %then %do;
									WORK.SASMAC1 /* hum... we may get into trouble here if another digit is used instead... */
								%end;
								; 
			 	CONTENTS out=&_tmp(keep=name);                                                                                                           
			run;                                                                                                                                                                                                                                                                         
			DATA _null_;                                                                                                                           
			  	SET &_tmp;                                                                                                                              
			  	if upcase(name) = "%upcase(&macro_name)" then do;                                                                                          
			 		call symput("&_ans_", 1);                                                                                                          
			     	stop;                                                                                                                              
			  	end;                                                                                                                                 
			  	else call symput("&_ans_", 0);                                                                                                        
			run;  
			%work_clean(&_tmp);
		%mend _macro_exist_insession;  
		%_macro_exist_insession(&macroname, _ans_=_ans);   
	    /*%if &_ans=1 %then		%goto quit; */
	%end;

	%quit:
	%if %macro_isblank(_ans) %then 	%let _ans=0;
	data _null_;
		call symput("&_ans_","&_ans");
	run;

	%exit:
%mend;


%macro _example_macro_exist;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ans;

	%put;
	%put (i) Test a dummy macro;
	%macro_exist(DUMMY,_ans_=ans);
	%if &ans=0 %then 	%put OK: TEST PASSED - Non-existing macro detected: errcode 0;
	%else 				%put ERROR: TEST FAILED - Non-existing macro found: errcode &ans;
	
	%macro DUMMY;
		%put DUMMY;
	%mend DUMMY;

	%put;
	%put (ii) Test a macro compiled for this session; 
	%macro_exist(DUMMY,_ans_=ans);
	%if &ans=1 %then 	%put OK: TEST PASSED - Non-existing macro detected: errcode 1;
	%else 				%put ERROR: TEST FAILED - Non-existing macro found: errcode &ans;

	/* clean a bit (in case you need to run this test again, DUMMY should not be set!)... */
	PROC CATALOG cat=	%if %nrbquote(&sysscp)=%nrbquote(WIN) and %sysfunc(cexist(WORK.SASMACR)) %then %do;
									WORK.SASMACR
								%end;
								%else %if %sysfunc(cexist(WORK.SASMAC1)) %then %do;
									WORK.SASMAC1 /* hum... we may get into trouble here if another digit is used instead... */
								%end;
								;
		delete DUMMY / entrytype=macro;
	quit;

	%if %sysevalf(&SYSVER < 9.3) and %sysfunc(getoption(sasmstore))^=_tmplib %then %do; 
		/* why? the reason is that when you assign a library for saving macros, it is locked 
		* until the SAS session is closed (at least with SAS EG). 
		* see http://denversug.org/presentations/2013CODay/Simpson_Debugging2013pptx.pdf */
		libname _tmplib "&G_PING_TESTDB";
	%end;
	options mstored sasmstore=_tmplib;
	%macro DUMMY / store;
		%put DUMMY;
	%mend DUMMY;

	%put;
	%put (iii) Test a macro compiled for this session; 
	%macro_exist(DUMMY,_ans_=ans);
	%if &ans=2 %then 	%put OK: TEST PASSED - Non-existing macro detected: errcode 2;
	%else 				%put ERROR: TEST FAILED - Non-existing macro found: errcode &ans;

	PROC CATALOG cat=_tmplib.SASMACR;
		delete DUMMY / entrytype=macro;
	quit;

 	%if %sysevalf(&SYSVER >= 9.3) %then %do;
		%sysmstoreclear;
	%end;
	%else %do;
		options nomstored; /* so as to free the reference to _tmplib */
		run;
		/*libname _tmplib clear;
		run;*/
	%end;

	%put;
	%put (iv) Test a standard macro from the PING library (in autocall);
	%macro_exist(error_handle, _ans_=ans);
	%if &ans=3 %then 	%put OK: TEST PASSED - Macro error_handle detected: errcode 3;
	%else 				%put ERROR: TEST FAILED - Macro error_handle found: errcode &ans;


	%put;
%mend _example_macro_exist;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_macro_exist; 
*/

%macro _langston_macro_exist(macro_name);

	/* given a fileref and a memname and memtype, we attempt to open the member of the 
	* directory (catalog or file system directory). We set &member_found to 1 if it can be 
	* opened, 0 if not. */
	%macro member_exist(fileref, memname, memtype, _member_found_=);
		DATA _null_;
			* open the directory and proceed if it can be opened;
			handle = dopen("&fileref.");
			if handle ne 0;
			* open the member and set the macro variable based on result;
			mem_handle = mopen(handle,"&memname..&memtype.",'i');
			call symputx('_member_found_',mem_handle ne 0);
			* close the member if it were opened successfully;
			if mem_handle then
				rc = fclose(mem_handle);
			* close the directory;
			rc = dclose(handle);
		run;
	%mend member_exist;

	/* given a macro name, we determine if it has already been compiled. We first look in 
	* work.sasmacr, then in the sasmacr referenced by sasmstore (if given) and then in 
	* sashelp.sasmacr. */
	%macro compiled_exist(macro_name, _member_found_=);
		/* try work.sasmacr first to see if the compiled macro is there */
		filename maclib catalog "work.sasmacr";
		%member_exist(maclib, &macro_name., macro, _member_found_=&_member_found_);
		filename maclib clear;
		%if &&&_member_found_ %then
			%goto exit;
		/* try sasmacr referenced by sasmstore if it were specified */
		%let sasmstore_option = %sysfunc(getoption(sasmstore));
		%if %sysfunc(getoption(mstored))=MSTORED and %length(&sasmstore_option) > 0 %then
			%do;
				filename maclib catalog "&sasmstore_option..sasmacr";
				%member_exist(maclib, &macro_name., macro, _member_found_=&_member_found_);
			%end;
		%if &&&_member_found_ %then
			%goto exit;
		/* try sashelp.sasmacr last */
		filename maclib catalog "sashelp.sasmacr";
		%member_exist(maclib, &macro_name., macro, _member_found_=&_member_found_);
		%exit:
	%mend compiled_exist;

	%local _member_found;
	%let _member_found=0;
	/* see if the macro already exists in compiled form */
	%compiled_exist(&macro_name.,_member_found_=_member_found);

	%if &_member_found %then
		%goto done;

	/* if the macro does not exist in compiled form, we need to search for it in each of the 
	* autocall directories until it is found. The sasautos option contains a parenthesized 
	* list of pathnames (quoted) and filerefs (not quoted). For a pathname, we have to make a
	* fileref for it. We use the %member_exists macro for the fileref and the macro name with 
	* the .sas extension. Note that this is all generated as part of a macro definition so that 
	* we can %goto around the rest of the code once a member is found. */
	filename &sascode_fileref. temp;

	data _null_;
		file &sascode_fileref.;

		/* macro definition */
		put '%macro ' "&process_sasautos_name." ';';
		put '%global _member_found;';

		/* get SASAUTOS option and blank out the parentheses */
		text=getoption('sasautos');
		if substr(text,1,1)='(' then	substr(text,1,1)=' ';
		l=length(text);
		if substr(text,l,1)=')' then	substr(text,l,1)=' ';

		/* loop through all the tokens in SASAUTOS */
		i=0;
		do while(1);
			i+1;
			/* read a quoted token (pathname) or non-quoted token (fileref) */
			x=scan(text,i,' "''','q');
			if x=' ' then	leave;
			/* change double-quoted to single-quoted to avoid macro substitution */
			if substr(x,1,1)='"' then
				do;
					substr(x,length(x),1)=' ';
					substr(x,1,1)=' ';
					x=tranwrd(x,'""','"');
					x=tranwrd(x,"'","''");
					x="'"||substr(x,2,length(x)-1)||"'";
				end;
			/* use FILENAME statement to create fileref if needed */
			length fileref $8;
			if x=:"'" then
				do;
					fileref="&myautos_fileref.";
					put 'filename ' "&myautos_fileref. " x ';';
					do_clear=1;
				end;
			else
				do;
					fileref=x;
					do_clear=0;
				end;
			/* issue macro code to handle the fileref */
			put '%member_exist(' fileref ',' "&macro_name." ',sas, _member_found_=_member_found);';
			put '%if &_member_found %then %do;';
			put '%include ' fileref "(&macro_name.)" '/source2; run;';

			if
				do_clear then put 'filename ' fileref ' clear;';
				put '%compiled_exist' "(&macro_name.)" ', _member_found_=_member_found);';
				put '%goto done_looking;';
				put '%end;';
		end;
		/* complete the macro definition */
		put '%done_looking:;';
		put '%mend ' "&process_sasautos_name" ';';
	run;
	/* include the generated code to define the macro */
	%include &sascode_fileref./source2;
	run;
	filename &sascode_fileref. clear;
	/* now invoke the macro */
	%&process_sasautos_name.;
	%done:;
%mend _langston_macro_exist;


/** \endcond */
