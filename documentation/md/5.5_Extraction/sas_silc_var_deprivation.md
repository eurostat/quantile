## silc_var_deprivation {#sas_silc_var_deprivation}
Compute common EU-SILC material deprivation variables for longitudinal dataset. 

	% silc_var_deprivation(survey, geo, time, odsn, 
					idir=, olib=, n=3, n_sev=4, n_ext=5, 
					cds_transxyear=&G_PING_TRANSMISSIONxYEAR, clib=&G_PING_LIBCFG);
 
### Arguments
* `survey` : type of the survey; this can be any of the character values defined through the 
	global variable `G_PING_SURVEYTYPES`, _i.e._:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `geo` 	: countries list;
* `time` 	: year  list;
* `odsn` 	: (_option_) name of output dataset;
* `n` 		: (_option_) number of items used as threshold for deprived condition; by default, 
	`n` is set to the value of the global variable `G_PING_DEPR_N` (_i.e._, `n=3`);
* `n_sev` 	: (_option_) number of items used as threshold for severe deprived condition; by 
	default, `n_sev` is set to the value of the global variable `G_PING_DEPR_N_SEV` (_i.e._, 
	`n_sev=4`);
* `n_ext`	: (_option_) number of items used as threshold for extreme deprived condition; by 
	default, `n_ext` is set to the value of the global variable `G_PING_DEPR_N_EXT` (_i.e._, 
	`n_ext=5`);
* `olib`    : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used.

### Returns
In dataset `dsn`, the variables `deprived`, `sev_dep` and `ext_dep` defined over the population 
as follows:
+ for material deprivation `deprived`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived|	lack <  `n` item(s)     |
|	1	| deprived    |	lack >= `n` item(s)     |

+ for severe material deprivation `sev_dep`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived|	lack <  `n_sev` item(s) |
|	1	| deprived    | lack >= `n_sev` item(s) |
		
+ for extreme material deprivation  `ext_dep`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived| lack <  `n_ext` item(s) |
|	1	| deprived    |	lack >= `n_ext` item(s) |
		
### Examples
We can run the macro `%%silc_var_deprivation` with:

    %let geo=AT;
    %let time=2010;
    %silc_var_deprivation(dsn, &geo, &time);

returns in `dsn` the following values for the `deprived`, `sev_sep` and `ext_dep` variables:
| HB010 | HB020 | HB030 | deprived | sev_dep | ext_dep|
|-------|-------|-------|----------|---------|--------| 
| 2010  |  AT   |2658500|	0      |   	0    |   0    |
| 2010  |  AT   |2658700|   1      |    0    |   0    |
| ...   |  ..   |  ...  |  ...     |   ...   |  ...   |  
Similarly, we can run the macro with:

	%let geo=AT BE;
	%let time=2013;
	%let n_ext=8;
	%silc_var_deprivation(dsn, &geo, &time, n_ext=&n_ext);

returns in `dsn` the following values for the `deprived`, `sev_sep` and `ext_dep` variables:
| HB010 | HB020 | HB030 | deprived | sev_dep | ext_dep|
|-------|-------|-------|----------|---------|--------| 
| 2010  |  AT   |2658500|	0      |   	0    |   0    |
| 2010  |  BE   |4924400|   0      |    0    |   0    |
| 2011  |  AT   |2658500|	0      |   	0    |   0    |
| 2011  |  BE   |4924400|   0      |    0    |   0    |
| ...   |  ..   |  ...  |  ...     |   ...   |  ...   |  

Run `%%_example_silc_var_deprivation` for more examples.

### See also
[%ds_check](@ref sas_ds_check), [%macro_isblank](@ref sas_macro_isblank).
