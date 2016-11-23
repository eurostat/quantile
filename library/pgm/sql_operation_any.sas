/** 
## sql_operation_any {#sas_sql_operation_any}
Generate the expression used to define whether any series of variables fills a specified criterion
in a SQL procedure.

	%let val=%sql_operation_any(var=, calcvar=, cond=);

### Arguments
* `var` : (_option_) variable(s) for which the test is operated; the variable(s) listed in
	`var` must be already present (_i.e._, originally coded in the processed table);
* `calcvar` : (_option_) ibid, however the variable(s) listed in `calcvar` refer to previously 
	calculated variables (_e.g._ , within the same `SELECT` statement).

### Returns
`val` : a boolean flag (0/1) set to 1 for observations for which the expression `cond` holds.

### Examples
Let us consider the following table `dsn1`:
|  a  | 
|----:|
| -1  | 
| -2  | 
| -3  | 
| -4  | 
| -5  | 

Then it is only necessary to run the following SQL procedure:

	%let cond=%quote(GT 2);
	PROC SQL;
	  CREATE TABLE dsn2 as
	  SELECT abs(a) as absa,
	  	%sql_operation_any(var=a, cond=&cond) as conda,
	  	%sql_operation_any(calcvar=absa, cond=&cond) as condabsa
	  FROM dsn1;
	quit; 

so as to create the following table `dsn2`:
 absa | conda | condabsa 
-----:|------:|---------:
  1   |   0   |    0
  2   |   0   |    0
  3   |   0   |    1
  4   |   0   |    1
  5   |   0   |    1
since the calls to macros `%%sql_operation_sum`: 

	%let expr1=%sql_operation_any(var=a, cond=&cond);
	%let expr2=%sql_operation_any(calcvar=absa, cond=&cond);

return respectively the expressions: 
	* `expr1=a GT 2`, and 
	* `expr2=calculated absa GT 2`.

### Note
**The macro `%%sql_operation_any` is  a wrapper to L. Joseph's original `%%AnyOf` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/MeanOf.html>.

### See also
[%sql_operation_mean](@ref sas_sql_operation_mean), [%sql_operation_sum](@ref sas_sql_operation_sum), 
[%sql_operation_count](@ref sas_sql_operation_count), [%ds_iscond](@ref sas_ds_iscond).
*/ /** \cond */

%macro sql_operation_any(var=		/* List of original variables to test 				(OPT) */
						, calcvar=	/* List of previously calculated variables to test 	(OPT) */
						, cond= 	/* Expression used for condition					(OPT) */
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
		_i 
		mv 
		mc 
		n
		_var
		allvar;
	%let op=;
	%let SEP=%str( );

	%let mv = %list_length(&var);
	%let mc = %list_length(&calcvar);
	%let n = %eval(&mv + &mc);

	%let allvar = &var.&SEP.&calcvar;

	%do _i = 1 %to &n;
		%let _var = %scan(&allvar, &_i, &SEP);

		%if &_i GT 1 %then %do;
			%let op=&op.&SEP.or;
		%end;
		%if &_i GT &mv %then %do;
			%let op=&op.&SEP.calculated;
		%end;
		%let op=&op.&SEP.&_var.&SEP.&cond;
	%end;
	%let op=%sysfunc(trim(&op));

	%exit:
	&op
%mend sql_operation_any;

%macro _example_sql_operation_any;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _dsn op1 op2;
	%let _dsn=TMP&sysmacroname;

	DATA &_dsn.1;
		a=-1; 	output;
		a=-2; 	output;
		a=-3; 	output;
		a=-4; 	output;
		a=-5; 	output;
	run;
	%ds_print(&_dsn.1);

	%let cond=%quote(GT 2);
	%put;
	%put (i) Run a simple test with the conditional operation using cond=&cond;
	PROC SQL;
	  CREATE TABLE &_dsn.2 as
	  SELECT a, 
	  	abs(a) as absa,
	  	%sql_operation_any(var=a, cond=&cond) as conda,
	  	%sql_operation_any(calcvar=absa, cond=&cond) as condabsa
	  FROM &_dsn.1;
	quit; 

	%let op1=a GT 2; 
	%if %quote(%sql_operation_any(var=a, cond=&cond)) EQ %quote(&op1) %then 
		%put OK: TEST PASSED - Returns expression: %quote(&op1);
	%else 																	
		%put ERROR: TEST FAILED - Wrong expression returned;
	%let op2=calculated absa GT 2;
	%if %quote(%sql_operation_any(calcvar=absa, cond=&cond)) EQ %quote(&op2) %then 
		%put OK: TEST PASSED - Returns expression: %quote(&op2);
	%else 																			
		%put ERROR: TEST FAILED - Wrong expression returned;
	%ds_print(&_dsn.2);

	%put;
	
	%work_clean(&_dsn.1, &_dsn.2);
%mend _example_sql_operation_any;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_operation_any; 
*/

/** \endcond */
