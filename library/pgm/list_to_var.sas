/** 
## list_to_var {#sas_list_to_var}
Insert into a (possibly already existing) dataset a variable passed as an unformatted
(_i.e._, unquoted and blank-separated) list of values.

	%list_to_var(varlst, var, dsn, fmt=, sep=%quote( ), lib=WORK);

### Arguments
* `varlst` : unformatted (_i.e._, unquoted and blank-separated) list of strings;
* `var` : name of the variable to use in the dataset;
* `fmt` : (_option_) string used to specify the format of the variable, as accepted by 
	`ATTRIB`, _e.g._ something like `$10.` for a CHAR variable; by default, `fmt` is not 
	set, the variable will be stored as a CHAR variable;
* `sep` : (_option_) character/string separator in output list; default: `%%quote( )`, _i.e._ 
	`sep` is blank;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`dsn` : output dataset; if the dataset already exists, then observations with missing
	values everywhere except for the variable `&var` (possibly not present in dsn) will 
	be appended to the dataset. 

### Examples

	%let varlst=DE UK SE IT PL AT;
 	%list_to_var(&varlst, geo, dsn);	 

returns in `WORK.dsn` the following table:
	Obs|geo
	---|---
	 1 | DE
	 2 | UK
	 3 | SE
	 4 | IT
	 5 | PL
	 6 | AT
	 
Run macro `%%_example_list_to_var` for more examples.

### Note
If the dataset already exists and there is either no numeric, or no character variables  
in it, then the following warning will be issued:

    WARNING: Defining an array with zero elements.

This message is not an error.

### References
1. Carpenter, A.L. (1997): ["Resolving and using &&var&i macro variables"](http://www2.sas.com/proceedings/sugi22/CODERS/PAPER77.PDF).
2. Tsykalov, E. (2003): ["Processing large lists of parameters and variables with SAS arrays and macro language"](http://analytics.ncsu.edu/sesug/2003/CC08-Tsykalov.pdf).
3. Carpenter, A.L. (2005): ["Storing and using a list of values in a macro variable"](http://www2.sas.com/proceedings/sugi30/028-30.pdf).

### See also
[%var_to_list](@ref sas_var_to_list), [%clist_to_var](@ref sas_clist_to_var). 
*/ /** \cond */

%macro list_to_var(varlst	/* Name of the input list of observations to store 	(REQ) */
				, _var 		/* Name of the variable in the output dataset 		(REQ) */
				, dsn		/* Output dataset 									(REQ) */
				, fmt=		/* Format of the variable							(OPT) */
				, sep=		/* Character/string used as list separator 			(OPT) */
				, lib=		/* Output library 									(OPT) */		
				);

 	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/* internal dummy variables */
	%local _METHOD_ 					/* arbitrary choice for calculation method */	
		_SOMETHING_I_DONT_UNDERSTAND_; 	/* as it says... */
	%let _METHOD_=0; /* 1; */
	%let _SOMETHING_I_DONT_UNDERSTAND_=0;

	/* create or append the new observations */
	DATA &lib..&dsn;

		%if %ds_check(&dsn, lib=&lib) EQ 0 %then %do;
			/* output the original dataset */
			%let _SOMETHING_I_DONT_UNDERSTAND_=1;
			SET	&lib..&dsn end=eof;
			OUTPUT;
		%end;
		%else %do;
			%if not %macro_isblank(fmt) %then %do;
				ATTRIB &_var FORMAT=&fmt;
			%end;
			/* create a 'fake' eof variable when the dataset is created from scratch */
			eof=2;
		%end;

		/* what happens here? the test "if eof=1" alone does not work to exclude the case
		* were the table is created from scratch... why? 
		* we introduce the macro variable SOMETHING_I_DONT_UNDERSTAND so as to cheat... */
		%if &_SOMETHING_I_DONT_UNDERSTAND_=1 %then %do;
		/* do some cleansing: in case we write at the end of an existing dataset, we force
		 * all existing variables to be missing (.), so as to add observations wich will be
		 * indeed also missing everywhere except for the variable &var we provide */
			if eof=1 then do;
		     	array allnum _numeric_ ;
		     	array allchar _character_ ;
			 	do over allnum; allnum=.; end;
			 	do over allchar; allchar=.; end;
		     	/*a variant:
				array allnum {*} _numeric_ ;
		     	array allchar {*} _character_ ;
			    do j=1 to dim(allnum); allnum{j}=.; end;
		     	do j=1 to dim(allchar); allchar{j}=' '; end;
				drop j;
				*/
			end;
		%end;

		/* now actually create the desired observations from the list */
		if eof then do; /* e.g., eof is 1 or 2 */
			%if &_METHOD_=0 %then %do;
				/* method 1: use "do while" data loop 
				 * see for instance http://analytics.ncsu.edu/sesug/2003/CC08-Tsykalov.pdf */
				i=1;
				do while (scan("&varlst",i,"&sep") ne "");
					&_var=scan("&varlst",i,"&sep");
					output;
					i + 1;
				end;
				drop i;
			%end;

			%else %if &_METHOD_=1 %then  %do;
				/* method 2: use "%do %while" macro loop 
				 * see fo instance: http://www2.sas.com/proceedings/sugi30/028-30.pdf */
				%local i;
				%let i=1;
				%do %while (%scan(&varlst,&i,&sep) ne %str());
					&_var ="%scan(&varlst,&i,&sep)";
					output;
					%let i=%eval(&i+1);
				%end;
			%end;
		end;

		/* drop the eof variable that was create when the dataset was created from scratch */
		if eof=2 then do;
		 	drop eof;
		end;
   	run; 

%mend list_to_var;


%macro _example_list_to_var;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let dsn=_tmp_example_list_to_var;

	%let varlst=DE UK SE IT PL AT ;	

	%put;
	%put (i) Create a dataset &dsn from the list GEO=&varlst ...;
	%list_to_var(&varlst, geo, &dsn);
	%ds_print(&dsn); 

	%_dstest32;
	%ds_print(_dstest32);
		
	%put;
	%put (ii) Append to an existing dataset _dstest32 from the list GEO=&varlst ...;
	%list_to_var( &varlst, geo, _dstest32);
	%ds_print(_dstest32); 

	%put;

	/* clean your shit... */
	%work_clean(_dstest32);	
	%work_clean(&dsn);	
%mend _example_list_to_var;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_to_var; 
*/

/** \endcond */
