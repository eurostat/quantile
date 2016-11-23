/** 
## sql_operation_count {#sas_sql_operation_count}
Generate the expression used to calculate the number of missing (or not) items of a series of 
variables for each observation in a SQL procedure.

	%let expr=%sql_operation_count(var=, calcvar=, missing=no);

### Arguments
* `var` : (_option_) variable(s) for which the number of missing (or non-missing) items will be 
	returned; the variable(s) listed in `var` must be already present (_i.e._, originally coded 
	in the processed table);
* `calcvar` : (_option_) ibid, however the variable(s) listed in `calcvar` refer to previously 
	calculated variables (_e.g._ , within the same `SELECT` statement);
* `missing` : (_option_) boolean flag (`yes/no`) set to count missing items for given observation;
	default: `missing=no`, _i.e._ non missing items are counted.

### Returns
`expr` : expression for calculating the number of missing (or non-missing) items of a series of 
	variables, to be used within a SQL procedure.

### Examples
Let us consider the following table `dsn1`:
  a  |  b 
----:|----:
 -1	 |   .
  .	 |   .
  .	 | 102
 -4	 | 103
 -5	 |   .

Then it is only necessary to run the following SQL procedure:

	PROC SQL;
	  CREATE TABLE dsn2 as
	  SELECT a, b,
		sql_operation_count(var=a b, missing=yes) as miss,
	  	%sql_operation_count(var=a b) as nomiss
	  FROM dsn1;
	quit; 

so as to create the following table `dsn2`:
  a  |  b  | miss | nomiss 
----:|----:|-----:|------:
 -1	 |   . |  1   |	  1
  .	 |   . |  2   |	  0
  .	 | 102 |  1   |	  1
 -4	 | 103 |  0   |	  2
 -5	 |   . |  1   |	  1
since the calls to macros `%%sql_operation_count`: 

	%let expr1=%sql_operation_count(var=a b, missing=yes);
	%let expr2=%sql_operation_count(var=a b);

return respectively the expressions: 
	* `expr1=(missing(a))+(missing(b))`, and 
	* `expr2=(not missing(a))+(not missing(b))`.

### Note
1. **The macro `%%sql_operation_count` is  a wrapper to L. Joseph's original `%%NOf` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/MeanOf.html>.
2. In case the considered parameters are empty, the convention is that the macro returns a 
missing value (`.`).

### See also
[%sql_operation_mean](@ref sas_sql_operation_mean), [%sql_operation_any](@ref sas_sql_operation_any), 
[%sql_operation_sum](@ref sas_sql_operation_sum), [%ds_count](@ref sas_ds_count).
*/ /** \cond */

%macro sql_operation_count(var=		/* List of original variables to count 				(OPT) */
						, calcvar=	/* List of previously calculated variables to count (OPT) */
						, missing=	/* Boolean flag set to count missing items */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local op;
	%let op=;

	%if %macro_isblank(missing) %then 	%let missing=NO;
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&missing), type=CHAR, set=YES NO) NE 0, mac=&_mac,
			txt=%quote(!!! Parameter MISSING is a boolean flag (YES/NO) !!!)) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local dim 
		_i 
		v 
		mv 
		mc 
		n
		calculated 
		allvar;
	%let SEP=%str( );
	%let calculated=0;

	%let mv = %list_length(&var);
	%let mc = %list_length(&calcvar);
	%let n = %eval(&mv + &mc);

    %if &n EQ 0 %then %do;
        %let op=.; /* this will be missing */
		%goto exit;
    %end;

	%let allvar = &var.&SEP.&calcvar;

	%do _i = 1 %to &n;
		%if &_i GT &mv %then 	%let calculated = 1;
		%let v = %scan(&allvar, &_i, &SEP);
		%if &calculated %then 	%let v=calculated &v;

		%if &_i GT 1 %then %do;
			%let op=&op.+;
		%end;
		%if %upcase("&missing")="YES" %then %do;
			 %let op=&op.(missing(&v));
		%end;
		%else %do;
			 %let op=&op.(not missing(&v));
		%end;
	%end;
	%let op=%sysfunc(trim(&op));

	%exit:
	&op
%mend sql_operation_count;

%macro _example_sql_operation_count;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _dsn op1 op2;
	%let _dsn=TMP&sysmacroname;

	%put;
	%put (i) Run a dummy test where the variable is missing;
	%if %quote(%sql_operation_count(var=)) EQ %quote(.) %then 	%put OK: TEST PASSED - Returns: %quote(.);
	%else 														%put ERROR: TEST FAILED - Wrong expression returned;

	DATA &_dsn.1;
		a=-1; 	b=.; 	output;
		a=.; 	b=.; 	output;
		a=.; 	b=102; 	output;
		a=-4; 	b=103; 	output;
		a=-5; 	b=.; 	output;
	run;
	%ds_print(&_dsn.1);

	%put;
	%put (ii) Run a simple test with the mean operation;
	PROC SQL;
	  CREATE TABLE &_dsn.2 as
	  SELECT a, 
	  	abs(a) as absa,
	  	%sql_operation_count(var=a b, missing=yes) as miss,
	  	%sql_operation_count(var=a b) as nomiss
	  FROM &_dsn.1;
	quit; 

	%let op1=(missing(a))+(missing(b)); 
	%if %quote(%sql_operation_count(var=a b, missing=yes)) EQ %quote(&op1) %then 			
		%put OK: TEST PASSED - Returns expression: %quote(&op1);
	%else 																	
		%put ERROR: TEST FAILED - Wrong expression returned;
	%let op2=(not missing(a))+(not missing(b));
	%if %quote(%sql_operation_count(var=a b)) EQ %quote(&op2) %then 
		%put OK: TEST PASSED - Returns expression: %quote(&op2);
	%else 																	
		%put ERROR: TEST FAILED - Wrong expression returned;
	%ds_print(&_dsn.2);

	%put;
	
	%*work_clean(&_dsn.1, &_dsn.2);
%mend _example_sql_operation_count;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_operation_count; 
*/
%_example_sql_operation_count; 

/** \endcond */
