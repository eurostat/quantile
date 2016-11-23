/** 
## ds_select {#sas_ds_select}
Select variables from a given dataset using the SQL-based `SELECT` method.

	%ds_select(idsn, odsn, 
			var=, varas=, varop=, 
			where=, groupby=, having=, orderby=, 
			_proc_=, distinct=no, all=no, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : name of the output dataset; 
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; default:
	`var` is empty and all variables are selected; note that (see below):
		+ the operation of `varop` (see below) will operate on	these variables only,
		+ all other variables in the dataset can also be selected using the option `all=yes`;
* `varas` : (_option_) list of alias (`AS`) to use for the variables in `var`; if not empty, then should
	 be of same length as `var`; default: empty, _i.e._ the names of the variables are retained;
* `varop` : (_option_) list of unary operations (_e.g._, `min`, `max`, ...) to run (separately) over the 
	list of variables in `var`; if not empty, then should be of same length as `var`; note that the string 
	`_ID_` (see also variable `G_PING_IDOP`) is used for the identity operation (_i.e._, no operation); default: 
	empty, _i.e._ `_ID_` is ran over all variables;
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be passed with 
	`%%str`; default: empty;
* `groupby` : (_option_) list of variables of `idsn` used to group data (`GROUP BY` option); default:
	empty;
* `having` : (_option_) expression used to refine the selection (`HAVING` option); should be passed with 
	`%%str`; default: empty;
* `orderby` : (_option_) list of variables of `idsn` used to group data (`ORDER BY` option); default:
	empty;
* `all` : (_option_) boolean flag (`yes/no`) set to keep all variables from input dataset `idsn`; in 
	practice, a `*` is added to the list of variables in `var` into the `SELECT` operation; default:
	`all=no`, _i.e._ only the variables in `var` are present in the output dataset;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.
  
### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection operated on the 
	original dataset;
* `_proc_` : (_option_) name of a variable containing the `PROC SQL` procedure; when passed, or when the 
	debug mode is set, the operation is not actually ran, but it is returned (as a string) in this variable.

### Examples
Let us consider the test dataset #35:
geo | time | EQ_INC20 | RB050a
----|------|---------:|------:
 BE | 2009 |    10    |   10 
 BE | 2010 |    50    |   10
 BE | 2011 |    60    |   10
 BE | 2012 |    20    |   20
 BE | 2013 |    10    |   20
 BE | 2014 |    30    |   20
 BE | 2015 |    40    |   20
 IT | 2009 |    10    |   10
 IT | 2010 |    50    |   10
 IT | 2011 |    50    |   10
 IT | 2012 |    30    |   20
 IT | 2013 |    30    |   20
 IT | 2014 |    20    |   20
 IT | 2015 |    50    |   20

and run the following:
	
	%let var=   geo  time EQ_INC20 RB050a;
	%let varas= _ID_ _ID_ income   weight;
	%let varop= _ID_ _ID_ _ID_     min;
	%let where= %str(EQ_INC20>20);
	%let groupby= geo;
	%_dstest35;
	%ds_select(_dstest35, TMP, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby);

to create the output table `TMP`:
geo | time | income | weight
----|------|-------:|-------:
BE  | 2014 |   30   |   10
BE  | 2011 |   60   |   10
BE  | 2010 |   50   |   10
BE  | 2015 |   40   |   10
IT  | 2012 |   30   |   10
IT  | 2011 |   50   |   10
IT  | 2010 |   50   |   10
IT  | 2015 |   50   |   10
IT  | 2013 |   30   |   10
while  in debug mode:

	%let proc=;
	%ds_select(_dstest35, TMP, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby, _proc_=proc);

does not actually run the operation, but instead returns in `proc` the following string that describes the 
implemented procedure:

	PROC SQL noprint; CREATE TABLE WORK.TMP AS SELECT geo, EQ_INC20 AS income, 
		min(RB050a) AS weight FROM WORK._dstest35 WHERE EQ_INC20>20 GROUP BY geo; quit;

Run macro `%%_example_ds_select` for examples.

### Notes
1. In short, when only one variable `var` only is passed (as well as one `varas` identifier and one 
operation `varop` at most), and with `distinct=yes, all=yes`, the macro runs the following `PROC SQL` 
procedure:

	PROC SQL noprint;
		CREATE TABLE &olib..&odsn AS
		SELECT DISTINCT &varop(&var) AS &varas, *
		FROM &ilib..&idsn 
		WHERE &where
		GROUP BY &groupby
		HAVING &having
		ORDER BY &orderby
		;
	quit;
2. In debug mode, or when `_proc_` is set, the macro is used to defines the procedure instructions:

	   %let proc=;
	   %ds_select( ... , _proc_=proc);
so that `proc` is set to the procedure that launches the operation (see above), and while the actual 
operation is actually not ran. Further note that in the case the variable `G_PING_DEBUG` is not defined 
in your environment, and `_proc_` is not set, debug mode is ignored (_i.e._, by default the operation 
is ran).
3. For options/clause `where`, `groupby` and `having`, do not specify the corresponding keywords (_i.e._,
`WHERE`, `GROUP BY` and `HAVING` respectively). Ibid, for the `varas` option, do no use the `AS` keyword
in the list of names.
4. Note that while clauses `where` and `having` should be passed using the `%%str` string macro when 
running the process, `%%bquote` should be preferred when running in debug mode.
5. Remember the following differences between the `HAVING` and `WHERE` clauses:

	   DATA test;
	      a = 5; b = 6;
	   RUN;
	   PROC SQL;
		   CREATE TABLE test1 AS
			   SELECT (case when a=5 then 6
		  		   else 7 end) as a, 
			   COUNT(*) AS dummy
		   FROM test
		   GROUP BY a
		   HAVING a=5;
		   CREATE TABLE test2 AS
			   SELECT (case when a=5 then 6
		  		   else 7 end) as a, 
			   COUNT(*) AS dummy
		   FROM test
		   WHERE a=5
		   GROUP BY a;
	   quit;
create respectively `test1` as:
| a | dummy |  
|---|-------|
|   |       |
and `test2` as:
| a | dummy |  
|---|-------|
| 6 |   1   |


### References
1. Williams, C.S. (1999): ["PROC SQL for DATA step die-hards"](http://www.ats.ucla.edu/stat/sas/library/nesug99/ad121.pdf).
2. Dickstein, C. and Pass, R. (2004): ["DATA step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
3. Williams, C.S. (2008): ["PROC SQL for DATA step die-hards"](http://www.albany.edu/~msz03/epi697/ho/williams.pdf).
4. Marcella, S.P. and Jorgensen, G. (2009): ["PROC SQL: Tips and translations for DATA step users"](http://www.lexjansen.com/nesug/nesug09/bb/BB03.pdf).
5. Bennet, J. and Ross, B. (2015): ["PROC SQL for SQL die-hards"](http://www.pharmasug.org/proceedings/2015/QT/PharmaSUG-2015-QT06.pdf).

### See also
[%ds_append](@ref sas_ds_append), [%ds_isempty](@ref sas_ds_isempty), [%ds_check](@ref sas_ds_check),
[SELECT ](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473678.htm).
*/ /** \cond */

%macro ds_select(idsn			/* Input dataset 														(REQ) */
				, odsn 			/* Output dataset 														(REQ) */ 
			    , var=			/* List of variables to operate the selection on 						(OPT) */
				, varas=		/* List of replacement names for the list of variables 					(OPT) */
				, varop=		/* List of operations to perform separately over the list of variables 	(OPT) */
				, where=		/* WHERE clause 														(OPT) */
				, groupby=		/* GROUP BY clause 														(OPT) */
				, orderby=		/* ORDER BY clause														(OPT) */
				, having=		/* HAVING clause 														(OPT) */
				, distinct=no 	/* DISTINCT clause 														(OPT) */
				, ilib=			/* Name of the input library 											(OPT) */
				, olib=			/* Name of the output library 											(OPT) */
				, all=no		/* Boolean flag used to select all variables from the input dataset 	(OPT) */
				, _proc_=		/* SQL procedure expressed as SAS expression							(OPT) */	
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local DEBUG; /* boolean flag used for debug mode */
	%if not %macro_isblank(_proc_) %then		%let DEBUG=1;
	%else %if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else										%let DEBUG=0;

	/* check  the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* check the input parameter
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(odsn) EQ 1,		
			txt=!!! No input dataset %upcase(&odsn) passed !!!) %then
		%goto exit; */

	/* set the default output dataset */
	%if %macro_isblank(olib) %then 	%let olib=WORK/*&ilib*/;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced!, 
			verb=warn) %then
		%goto warning1;
	%warning1:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local nvar 		/* list of variables used in the PROC SQL */
		ngrpby	/* list of GROUPBY variables used in the PROC SQL */
		nordby; 	/* list of ORDERBY variables used in the PROC SQL */
	%let SEP=%str( );
	%let REP=%str(,);

	/* VAROP/VARAS: check the compatibility of the parameters with VAR */
	%if %macro_isblank(var) %then %do;
		/* check that both VAROP and VARAS are blank */
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(varas) EQ 0 or %macro_isblank(varop) EQ 0, mac=&_mac,		
				txt=!!! Parameters VARAS and VAROP incompatible with empty VAR !!!) %then
			%goto exit;
		/* set to all variables in the dataset */
		%ds_contents(&idsn, _varlst_=var, varnum=yes, lib=&ilib);
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* VAR: check that the variables actually exist in the dataset */
	%let nvar=; 
	%sql_clause_as(&idsn, &var, as=&varas, op=&varop, _varas_=nvar, lib=&ilib);
	%let var=&nvar;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! No variables selected from %upcase(&var) !!!)) %then
		%goto exit;

	/* GROUPBY: check that the variables actually exist in the dataset */
	%if not %macro_isblank(groupby) %then %do;
		%let ngrpby=; 
		%sql_clause_by(&idsn, &groupby, _varby_=ngrpby, lib=&ilib);
		%let groupby=&ngrpby;
	%end;

	/* ORDERBY: check that the variables actually exist in the dataset */
	%if not %macro_isblank(orderby) %then %do;
		%let nordby=; 
		%sql_clause_by(&idsn, &orderby, _varby_=nordby, lib=&ilib);
		%let orderby=&nordby;
	%end;

	%if &DEBUG=1 %then 
		%goto print;
 
	/* run the procedure */
	PROC SQL noprint 
		%if %upcase("&all")="YES" %then %do;
			nowarn
		%end;
		;
		CREATE TABLE &olib..&odsn AS
		SELECT 
		%if %upcase("&distinct")="YES" %then %do;
			DISTINCT
		%end;
		&var
		%if %upcase("&all")="YES" %then %do;
			, *
		%end;
		FROM &ilib..&idsn 
		%if not %macro_isblank(where) %then %do;
			WHERE &where
		%end;
		%if not %macro_isblank(groupby) %then %do;
			GROUP BY &groupby
		%end;
		%if not %macro_isblank(having) %then %do;
			HAVING &having
		%end;
		%if not %macro_isblank(orderby) %then %do;
			ORDER BY &orderby
		%end;
		;
	quit;
	%goto exit;

	%print:
	/* debug option: we reproduce hereby the code for the SQL procedure that otherwise appears 
	* below; not very elegant, but that's it... */
	%local _proc;
	%macro_put(&_mac, txt=3, debug=1);
	/* we build the PROC string */			%let _proc=%str(PROC SQL noprint;);
											%let _proc=&_proc.%str( CREATE TABLE &olib..&odsn AS SELECT);
	%if %upcase(&distinct)=YES %then 		%let _proc=&_proc.%str( DISTINCT);
											%let _proc=&_proc.%str( &var);
	%if %upcase(&all)=YES %then 			%let _proc=&_proc.%str(, *);
											%let _proc=&_proc.%str( FROM &ilib..&idsn);
	%if not %macro_isblank(where) %then 	%let _proc=&_proc.%str( WHERE &where); 
	%if not %macro_isblank(groupby) %then 	%let _proc=&_proc.%str( GROUP BY &groupby);
	%if not %macro_isblank(having) %then 	%let _proc=&_proc.%str( HAVING &having);
	%if not %macro_isblank(orderby) %then 	%let _proc=&_proc.%str( ORDER BY &orderby);
											%let _proc=&_proc.%str(; quit;);

	/* we return this string for debug */
	%if not %macro_isblank(_proc_) %then %do;
		data _null_;
			call symput("&_proc_", "&_proc");
		run;
	%end;
	%else %do;
		%macro_put(&_mac, txt=%quote(Run procedure: &_proc), debug=1);
	%end;		

	%exit:
%mend ds_select;

%macro _example_ds_select;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn var varas varop where having groupby proc oproc;

	/* temporary dataset */
	%let dsn=TMP%upcase(&sysmacroname);

	%let var = 		a 		z 		b;
	%let varas = 	vara 	varz 	varb;
	%_dstest5;
	%*ds_print(_dstest5);
	%put;
	%put (i) Test a simple selection procedure to run on test dataset #5;
	%let oproc = %str(PROC SQL noprint; CREATE TABLE WORK.TMP_EXAMPLE_DS_SELECT AS SELECT a AS vara, b AS varb FROM WORK._dstest5; quit;);
	%put %str( 	*) parameters used are:;
	%put %str(	        ) var=&var;
	%put %str(	        ) varas=&varas;
	%put %str( 	*) desired output is:;
	%put %str(	        ) &oproc;
	%put;
	%ds_select(_dstest5, &dsn, var=&var, varas=&varas, _proc_=proc);
	%if "&proc" = "&oproc" %then 	%put OK: TEST PASSED - Correct procedure implemented on _dstest5;
	%else 							%put ERROR: TEST FAILED - Wrong procedure implemented on _dstest5;
	%*ds_select(_dstest5, &dsn, var=&var, varas=&varas);

	%let var=	geo 	EFTA 	EFTA;
	%let varas= geo 	y_in  	y_out;
	%let varop= _ID_  	min   	max;
	%let where=%str(not missing(EFTA));
	%let having=%str((y_out>1990) & (y_in<=1990));
	%let groupby=geo;
	%put;
	%put (ii) Retrieve a given selection procedure on test dataset #10 using the "debug mode";
	%_dstest10;
	%*ds_print(_dstest10);
	%let oproc=%str(PROC SQL noprint; CREATE TABLE WORK.TMP_EXAMPLE_DS_SELECT AS SELECT DISTINCT geo, min(EFTA) AS y_in, max(EFTA) AS y_out FROM WORK._dstest10 WHERE not missing(EFTA) GROUP BY geo HAVING (y_out>1990) & (y_in<=1990); quit;);
	%put %str( 	*) parameters used are:;
	%put %str(	        ) var=&var;
	%put %str(	        ) varas=&varas;
	%put %str(	        ) varop=&varop;
	%put %str(	        ) where=&where;
	%put %str(	        ) groupby=&groupby;
	%put %str(	        ) having=&having;
	%put %str( 	*) desired output is:;
	%put %str(	        ) &oproc;
	%put;
	%ds_select(_dstest10, &dsn, var=&var, varop=&varop, varas=&varas, distinct=yes, where=&where, groupby=&groupby, having=&having, _proc_=proc);
	%if "&proc" = "&oproc" %then 	%put OK: TEST PASSED - Correct SELECT procedure implemented on _dstest10;
	%else 							%put ERROR: TEST FAILED - Wrong SELECT procedure implemented on _dstest10;

	%put;
	%put (iii) Actually run the selection on test dataset #10 and display the result;
	%ds_select(_dstest10, &dsn, var=&var, varop=&varop, varas=&varas, distinct=yes, where=&where, groupby=&groupby, having=&having);
	/*
	PROC SQL noprint; 
		CREATE TABLE WORK.TMP_EXAMPLE_DS_SELECT AS 
		SELECT DISTINCT geo, 
			min(EFTA) AS y_in, 
			max(EFTA) AS y_out 
		FROM WORK._dstest10 
		WHERE not missing(EFTA) 
		GROUP BY geo 
		HAVING (y_out>1990) & (y_in<=1990); 
	quit;
	*/	
	%ds_print(&dsn);

	%let var=   geo 	time 	EQ_INC20 	RB050a;
	%let varas= geo 	time 	income   	weight;
	%let varop= _ID_  	_ID_   	_ID_       	min;
	%let where=%str(EQ_INC20>20);
	%let groupby=geo;
	%put (iv) Retrieve a given selection procedure on test dataset #35;
	%_dstest35;
	%ds_print(_dstest35);
	%let oproc=%str(PROC SQL noprint; CREATE TABLE WORK.TMP_EXAMPLE_DS_SELECT AS SELECT geo, time, EQ_INC20 AS income, min(RB050a) AS weight FROM WORK._dstest35 WHERE EQ_INC20>20 GROUP BY geo; quit;);
	%put %str( 	*) parameters used are:;
	%put %str(	        ) var=&var;
	%put %str(	        ) varas=&varas;
	%put %str(	        ) varop=&varop;
	%put %str(	        ) where=&where;
	%put %str(	        ) groupby=&groupby;
	%put %str( 	*) desired output is:;
	%put %str(	        ) &oproc;
	%put;
	%ds_select(_dstest35, &dsn, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby, _proc_=proc);
	%if "&proc" = "&oproc" %then 	%put OK: TEST PASSED - Correct SELECT procedure implemented on _dstest35;
	%else 							%put ERROR: TEST FAILED - Wrong SELECT procedure implemented on _dstest35;

	%put;
	%put (iv) Actually run the selection on test dataset #35 and display the result;
	%ds_select(_dstest35, &dsn, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby);
	%ds_print(&dsn);

	%put;

	%work_clean(&dsn, _dstest5, _dstest10, _dstest35); 
%mend _example_ds_select;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_select; 
*/

/** \endcond */
