## silcx_ind_create {#sas_silcx_ind_create}
Create an indicator table from a common variable template and a list of additional labels.

	%silcx_ind_create(dsn, dim=, var=, cds_ind_con=, cds_var_dim=, lib=);
  
### Arguments
* `dsn` : name of the output (created) dataset;
* `dim` : (_option_) names of the (additional, Eurobase compatible) dimensions present in 
	the generated dataset, _i.e._ used as breadowns for the indicator; `dim` is incompatible 
	with `var` parameter (see below); default: `dim` is empty, _i.e._ the common template alone 
	is used (see `cds_ind_con` below);
* `var` : (_option_) when `dim` is not passed, it is possible to provide with the names of 
	the EU-SILC source variables used as breadowns for the indicator; then, corresponding 
	dimensions will be searched for in the configuration file that stores the correspondance 
	table between EU-SILC variable and Eurobase dimensions (see `cds_var_dim` below); `var` 
	is incompatible with `dim` parameter (see above); by default, `var` is empty and `dim` is
	used;
* `cds_ind_con` : (_option_) configuration file storing the template for the indicator, _i.e._
	generic variables common to EU-SILC indicators; by default,	it is named after the value 
	`&G_PING_INDICATOR_CONTENTS` (_e.g._, `INDICATOR_CONTENTS`); for further description, 
	see [%_indicator_contents](@ref cfg_indicator_contents);
* `cds_var_dim` : (_option_) configuration file storing the correspondance table between EU-SILC
	variables and Eurobase dimensions; by default,	it is named after the value 
	`&G_PING_VARIABLE_DIMENSION` (_e.g._, `VARIABLE_DIMENSION`); for further description, 
	see [%_variable_dimension](@ref cfg_variable_dimension);
* `lib` : (_option_) name of the output library where `dsn` shall be stored; by default: 
	empty, _i.e._ `WORK` is used;
* `clib` : (_option_) name of the library where the configuration files are stored; default to 
	the value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
In `dsn`, an empty dataset where the (list of) variable(s) provided in `dim` has(ve) been added 
to the following template table: 
| geo | time | unit | ivalue | iflag | unrel | n | nwgh |ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|---|------|-----|---------|--------|----------|
|     |      |      |        |       |       |   |      |     |         |        |          |
In practice, the variable(s) in `dim` is(are) added in between `unrel` and `n` variables of the
template.

### Examples
Running for instance

	%let dims=A B C;
	%silcx_ind_create(dsn, dim=&dims, type=CHAR, length=15);

creates the table `dsn` in the `WORK`ing library as:
| geo | time | unit | ivalue | iflag | unrel | A | B | C | n | nwgh | ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|---|---|---|---|------|------|---------|--------|----------|
|     |      |      |        |       |       |   |   |   |   |      |      |         |        |          |
where all dimensions `A, B, C` are of type `CHAR` and length 15. 

Run macro `%%_example_silcx_ind_create` for examples.

### Notes
1. The common variables in the template dataset `cds_ind_con` are defined by default. However, 
they may be parameterised since their names derived from the following global variables:
|        |                     |
|--------|---------------------|
| geo    | `G_PING_LAB_GEO`    |
| time   | `G_PING_LAB_TIME`   |
| unit   | `G_PING_LAB_UNIT`   |
| ivalue | `G_PING_LAB_VALUE`  |
| iflag  | `G_PING_LAB_IFLAG`  |
| unrel  | `G_PING_LAB_UNREL`  |
| n      | `G_PING_LAB_N`      |
| nwgh   | `G_PING_LAB_NWGH`   |
| ntot   | `G_PING_LAB_NTOT`   |
|ntotwgh | `G_PING_LAB_TOTWGH` |
2. Since the type and length of the variables to insert are searched for in configuration dataset
`cds_var_dim` (that stores the correspondance table between EU-SILC variables and Eurobase dimensions), 
either variablse `var` or dimensions `dim` must exist in the configuration file. 

### See also
[%_variable_dimension](@ref cfg_variable_dimension), [%_indicator_contents](@ref cfg_indicator_contents),
[%ds_create](@ref sas_ds_create).
