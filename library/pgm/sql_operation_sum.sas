/** 
## sql_operation_sum {#sas_sql_operation_sum}
Generate the expression used to calculate the sum of a series of variables for each 
observation in a SQL procedure.

	%let expr=%sql_operation_sum(var=, calcvar=);

### Arguments
* `var` : (_option_) variable(s) for which the sum will be returned; the variable(s) listed in
	`var` must be already present (_i.e._, originally coded in the processed table);
* `calcvar` : (_option_) ibid, however the variable(s) listed in `calcvar` refer to previously 
	calculated variables (_e.g._ , within the same `SELECT` statement).

### Returns
`expr` : expression for calculating the sum of a series of variables, to be used within a SQL 
	procedure.

### Examples
Let us consider the following table `dsn1`:
  a  |  b 
----:|----:
 -1	 | 100
 -2	 | 101
 -3	 | 102
 -4	 | 103
 -5	 | 104

Then it is only necessary to run the following SQL procedure:

	PROC SQL;
	  CREATE TABLE dsn2 as
	  SELECT abs(a) as absa,
	  	%sql_operation_sum(var=a b) as sum1,
	  	%sql_operation_sum(var=a, calcvar=absa) as sum2
	  FROM dsn1;
	quit; 

so as to create the following table `dsn2`:
 absa | sum1 | sum2 
-----:|-----:|------:
  1	  |  99	 |  0
  2	  |  99	 |  0
  3	  |  99	 |  0
  4	  |  99	 |  0
  5	  |  99	 |  0
since the calls to macros `%%sql_operation_sum`: 

	%let expr1=%sql_operation_sum(var=a b);
	%let expr2=%sql_operation_sum(var=a, calcvar=absa);

return respectively the expressions: 
	* `expr1=ifn(not missing(a) or not missing(b), (coalesce(a,0)+coalesce(b,0)), .)`, and 
	* `expr2=ifn(not missing(a) or not missing(calculated absa), (coalesce(a,0)+coalesce(calculated absa,0)), .) missing(calculated absa))), .)`.

### Note
1. **The macro `%%sql_operation_sum` is  a wrapper to L. Joseph's original `%%SumOf` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/MeanOf.html>.
2. In case the considered parameters are empty, the convention is that the macro returns a 
missing value (`.`).

### See also
[%sql_operation_mean](@ref sas_sql_operation_mean), [%sql_operation_any](@ref sas_sql_operation_any), 
[%sql_operation_count](@ref sas_sql_operation_count).
*/ /** \cond */

%macro sql_operation_sum(var=		/* List of original variables to sum 				(OPT) */
						, calcvar=	/* List of previously calculated variables to sum 	(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* nothing: we do not check for instance the existence of the VAR variables */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local op
		dim 
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
	%let op=ifn(;

	%do dim = 0 %to 1;
		/*dim = 0 for condition, 1 for numerator */
		%let calculated = 0;

		%do _i = 1 %to &n;
			%if &_i GT &mv %then 	%let calculated = 1;
			%let v = %scan(&allvar, &_i, &SEP);
			%if &calculated %then 	%let v=calculated &v;

			%if &_i GT 1 %then %do;
				%if &dim EQ 0 %then %do;
					%let op=&op.&SEP.or&SEP.;
				%end;
				%else %do;
					%let op=&op.+;
				%end;
			%end;

			%if &dim EQ 0 %then %do;
				%let op=&op.not missing(&v);
			%end;
			%else %do;
				%let op=&op.coalesce(&v,0);
			%end;
		%end;

		%if &dim EQ 0 %then %do;
				%let op=&op., (;
		%end;
		%else %do;
			%let op=&op.);
		%end;
	%end;
	%let op=&op., .);
	%let op=%sysfunc(trim(&op));

	%exit:
	&op
%mend sql_operation_sum;

%macro _example_sql_operation_sum;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _dsn op1 op2;
	%let _dsn=TMP&sysmacroname;

	%put;
	%put (i) Run a dummy test where the variable is missing;
	%if %quote(%sql_operation_sum(var=)) EQ %quote(.) %then 	%put OK: TEST PASSED - Returns: %quote(.);
	%else 														%put ERROR: TEST FAILED - Wrong expression returned;

	DATA &_dsn.1;
		a=-1; 	b=100; 	output;
		a=-2; 	b=101; 	output;
		a=-3; 	b=102; 	output;
		a=-4; 	b=103; 	output;
		a=-5; 	b=104; 	output;
	run;
	%ds_print(&_dsn.1);

	%put;
	%put (ii) Run a simple test with the mean operation;
	PROC SQL;
	  CREATE TABLE &_dsn.2 as
	  SELECT a, 
	  	abs(a) as absa,
	  	%sql_operation_sum(var=a b) as sum1,
	  	%sql_operation_sum(var=a, calcvar=absa) as sum2
	  FROM &_dsn.1;
	quit; 

	%let op1=ifn(not missing(a) or not missing(b), (coalesce(a,0)+coalesce(b,0)), .); 
	%if %quote(%sql_operation_sum(var=a b)) EQ %quote(&op1) %then 			
		%put OK: TEST PASSED - Returns expression: %quote(&op1);
	%else 																	
		%put ERROR: TEST FAILED - Wrong expression returned;
	%let op2=ifn(not missing(a) or not missing(calculated absa), (coalesce(a,0)+coalesce(calculated absa,0)), .);
	%if %quote(%sql_operation_sum(var=a, calcvar=absa)) EQ %quote(&op2) %then 
		%put OK: TEST PASSED - Returns expression: %quote(&op2);
	%else 																	
		%put ERROR: TEST FAILED - Wrong expression returned;
	%ds_print(&_dsn.2);

	%put;
	
	%work_clean(&_dsn.1, &_dsn.2);
%mend _example_sql_operation_sum;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_operation_sum; 
*/

/** \endcond */
