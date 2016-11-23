## sql_clause_modify {#sas_sql_clause_modify}
Generate a statement (text) that can be interpreted by the `MODIFY` clause of a SQL procedure.

	%sql_clause_modify(dsn, var, _varmod_=, fmt=, len=, lab=, lib=);

### Arguments
* `dsn` :
* `var` :
* `fmt` : 
* `len` : 
* `lab` : 
* `lib` :

### Returns
`_varmod_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var=	d  		e;
    %let len=	20 		8;
	%let fmt=	$20. 	10.2; 
    %let lab=	d2 		e2;
	%let varmod=;
	%sql_clause_modify(_dstest6, &var, fmt=&fmt, lab=&lab, len=&len, _varmod_=varmod);

returns `varmod=d FORMAT=$20. LENGTH=20 LABEL='d2', e FORMAT=10.2 LENGTH=8 LABEL='e2'`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_add](@ref sas_sql_clause_add), [%sql_clause_as](@ref sas_sql_clause_as),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_where](@ref sas_sql_clause_where),
[MODIFY](https://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/viewer.htm#n0g9jfr4x5hgsfn17gtma5547lt1.htm).
