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
