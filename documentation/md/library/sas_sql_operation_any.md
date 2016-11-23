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
