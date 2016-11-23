## ds_create {#sas_ds_create}
Create a dataset/table from a common label template and a list of additional labels using a
`PROC SQL`.

	%ds_create(odsn, idsn=, var=, typ=, len=, idrop=, ilib=WORK, olib=WORK);
  
### Arguments
* `idsn` : (_option_) dataset storing the template of common dimensions; this table shall 
	contain, for each variable to be inserted in the output dataset, its type, length as well
	as its desired position; it is of the form: 
 variable | type | length | order
:--------:|:----:|-------:|-------:
 	 W    | num  |      8 |      1
	where the order is relative to the beginning (when >0) or the end of the table (when <0);
	default: `idsn` is not set and no template table will be used; 
* `var` : (_option_) dimensions, i.e. names of the (additional) fields/variables present in 
	the dataset; default: empty;
* `typ` : (_option_) types of the (additional) fields; must be the same length as `var`;
* `len` : (_option_) lengths of the (additional) fields; must be the same length as `var`; 
* `idrop` : (_option_) variable(s) from the input template dataset `idsn` to be dropped prior to 
	their insertion into `odsn`;
* `ilib` : (_option_) name of the library where the configuration file is stored; default to 
	the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) when not set;
* `olib` : (_option_) name of the output library where `dsn` shall be stored; by default: empty, 
	_i.e._ `WORK` is used.

### Returns
`odsn` : name of the final output dataset created. 

### Examples
Running for instance

	%let dimensions=A B C;
	%ds_create(odsn, var=&dimensions);

creates the table `odsn` as:
| A | B | C |
|---|---|---|
|   |   |   |  
where all fields `A, B, C` are of type `CHAR` and length 15.
Consider now the following table `TEMP` stored in the `WORK`ing library:
VARIABLE  | TYPE | LENGTH | ORDER
----------|------|-------:|-----:
	W     | num  |      8 | 1
	X     | num  |      8 | 2
	Y     | char |     15 | 3
	Z     | num  |      8 | -1
which impose to put the dimensions `W, X, Y` in the first three positions in the table, and `Z`
in the last position, then run the command:

	%ds_create(odsn, var=&dimensions, idsn=TEMP);

In output, the table `odsn` now looks like:
| W | X | Y | A | B | C | Z |
|---|---|---|---|---|---|---|
|   |   |   |   |   |   |   |
where the variables `W, X, Y, Z` types and lengths are taken from the `TEMP` table.

Run macro `%%_example_ds_create` for examples.

### Note
The dataset generated using the macro [%_indicator_contents](@ref cfg_indicator_contents) provides
a typical example of configuration table dataset.

### See also
[%ds_check](@ref sas_ds_check), [%silcx_ind_create](@ref sas_silcx_ind_create),
[%_indicator_contents](@ref cfg_indicator_contents).
