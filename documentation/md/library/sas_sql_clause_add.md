## sql_clause_add {#sas_sql_clause_add}
Generate a quoted statement that can be interpreted by the `ADD` clause of a SQL procedure.

	%sql_clause_add(dsn, var, typ=, _varadd_=, lib=);

### Arguments
* `dsn` :
* `var` :
* `typ` : 
* `lib` :

### Returns
`_varadd_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var=a b y z h;
	%let typ=char;
	%let varadd=;
	%sql_clause_add(_dstest6, &var, typ=&typ, _varadd_=varadd);

returns `varadd=y char, z char` since variables `y` and `z` are the only ones not already present 
in `_dstest6`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_as](@ref sas_sql_clause_as),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_where](@ref sas_sql_clause_where).
