## sql_clause_by {#sas_sql_clause_by}
Generate a quoted text that can be interpreted by the `BY` clause of a SQL procedure.

	%sql_clause_by(dsn, var, _varby_=, lib=);

### Arguments
* `dsn` :
* `var` :
* `lib` :

### Returns
`_varby_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var=a b z h;
	%let varby=;
	%sql_clause_by(_dstest6, a b z h, _varby_=varby);

returns `varby=a, b, h` since variable `z` is not present in `_dstest6`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_as](@ref sas_sql_clause_as), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_where](@ref sas_sql_clause_where)
