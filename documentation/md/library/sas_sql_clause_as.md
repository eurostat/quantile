## sql_clause_as {#sas_sql_clause_as}
Generate a quoted text that can be interpreted by the `AS` clause of a SQL procedure.

	%sql_clause_as(dsn, var, _varas_=, as=, op=, lib=);

### Arguments
* `dsn` :
* `var` :
* `as` :
* `op` :
* `lib` :

### Returns
`_varas_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var= 	a 		b 		h
	%let as= 	ma 		B 		mh
	%let op= 	max 	_ID_ 	min
	%let varas=;
	%sql_clause_as(_dstest6, &var, as=&as, op=&op, _varas_=varas);

returns `varas=max(a) AS ma, b, min(h) AS mh`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_add](@ref sas_sql_clause_add), [%sql_clause_by](@ref sas_sql_clause_by), 
[%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_where](@ref sas_sql_clause_where)
