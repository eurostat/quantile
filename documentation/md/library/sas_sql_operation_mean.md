## sql_operation_mean {#sas_sql_operation_mean}
Generate the expression used to calculate the arithmetic mean of a series of variables for 
each observation in a SQL procedure.

	%let expr=%sql_operation_mean(var=, calcvar=);

### Arguments
* `var` : (_option_) variable(s) for which the mean will be returned; the variable(s) listed in
	`var` must be already present (_i.e._, originally coded in the processed table);
* `calcvar` : (_option_) ibid, however the variable(s) listed in `calcvar` refer to previously calculated 
	variables (_e.g._ , within the same `SELECT` statement).

### Returns
`expr` : expression for calculating the arithmetic mean of a series of variables, to be used 
	within a SQL procedure.

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
	  	%sql_operation_mean(var=a b) as mean1,
	  	%sql_operation_mean(var=a, calcvar=absa) as mean2
	  FROM dsn1;
	quit; 

so as to create the following table `dsn2`:
 absa | mean1 | mean2 
-----:|------:|------:
  1	  | 49.5  |  0
  2	  | 49.5  |  0
  3	  | 49.5  |  0
  4	  | 49.5  |  0
  5   | 49.5  |  0
since the calls to macros `%%sql_operation_mean`: 

	%let expr1=%sql_operation_mean(var=a b);
	%let expr2=%sql_operation_mean(var=a, calcvar=absa);

return respectively the expressions: 
	* `expr1=ifn(not missing(a) or not missing(b), (coalesce(a,0)+coalesce(b,0)) / ((not missing(a))+(not missing(b))), .)`, and 
	* `expr2=ifn(not missing(a) or not missing(calculated absa), (coalesce(a,0)+coalesce(calculated absa,0)) / ((not missing(a))+(not missing(calculated absa))), .)`.

### Note
1. **The macro `%%sql_operation_mean` is  a wrapper to L. Joseph's original `%%MeanOf` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/MeanOf.html>.
2. In case the considered parameters are empty, the convention is that the macro returns a 
missing value (`.`).

### See also
[%sql_operation_sum](@ref sas_sql_operation_sum), [%sql_operation_any](@ref sas_sql_operation_any), 
[%sql_operation_count](@ref sas_sql_operation_count).
