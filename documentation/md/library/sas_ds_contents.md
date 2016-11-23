## ds_contents {#sas_ds_contents}
Retrieve the list (possibly ordered by varnum) of variables/fields in a given dataset.

	%ds_contents(dsn, _varlst_=, _lenlst_=, _typlst_=, varnum=yes, lib=);

### Arguments
* `dsn` : a dataset reference;
* `varnum` : (_option_) boolean flag (`yes/no`) set to order the output list of variables
	by varnum, _i.e._ their actual position in the table; default: `varnum=yes` and the 
	variables returned in `_varlst_` (see below) are ordered;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
* `_varlst_` : name of the output macro variable where the list of variables/fields of the
	dataset `dsn` are stored;
* `_typlst_` : (_option_) name of the output macro variable storing the corresponding list of 
	variables/fields types; the output list shall be of the same length as `&_varlst_`; default: 
	it will not be returned;
* `_lenlst_` : (_option_) ibid with the variable lengths; default: it will not be returned.

### Examples
Consider the test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

One can retrieve the ordered list of variables in the dataset with the command:

	%let list=;
	%ds_contents(_dstest5, _varlst_=list);

which returns `list=f e d c b a`, while:

	%ds_contents(_dstest5, _varlst_=list, varnum=no);

returns `list=a b c d e f`. Similarly, we can also run it on our database, _e.g._:

	libname rdb "&G_PING_C_RDB"; 
	%let lens=;
	%let typs=;
	%ds_contents(PEPS01, _varlst_=list, _typlst_=typs, _lenlst_=lens, lib=rdb);

returns:
	* `list=geo time age sex unit ivalue iflag unrel n ntot totwgh lastup lastuser`,
	* `typs=  2    1   2   2    2      1     2     1 1    1      1      2        2`,
	* `lens=  5    8  13   3   13      8     1     8 8    8      8      7        7`.

Another useful use: we can retrieve data of interest from existing tables, _e.g._ the list of geographical 
zones in the EU:

	%let zones=;
	%ds_contents(&G_PING_COUNTRYxZONE, _varlst_=zones, lib=&G_PING_LIBCFG);
	%let zones=%list_slice(&zones, ibeg=2);

which will return: `zones=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU15 EU25 EU27 EU28 EFTA EU07 EU09 EU10 EU12`.

Run macro `%%_example_ds_contents` for more examples.

### Note
In short, the program runs (when `varnum=yes`):

	PROC CONTENTS DATA = &dsn 
		OUT = tmp(keep = name type length varnum);
	run;
	PROC SORT DATA = tmp 
		OUT = &tmp(keep = name type length);
     	BY varnum;
	run;
and retrieves the resulting `name`, `type` and `length` variables.

### References
1. Smith,, C.A. (2005): ["Documenting your data using the CONTENTS procedure"](http://www.lexjansen.com/wuss/2005/sas_solutions/sol_documenting_your_data.pdf).
2. Thompson, S.R. (2006): ["Putting SAS dataset variable names into a macro variable"](http://analytics.ncsu.edu/sesug/2006/CC01_06.PDF).
3. Mullins, L. (2014): ["Give me EVERYTHING! A macro to combine the CONTENTS procedure output and formats"](http://www.pharmasug.org/proceedings/2014/CC/PharmaSUG-2014-CC43.pdf).

### See also
[%var_to_list](@ref sas_var_to_list), [%ds_check](@ref sas_ds_check),
[CONTENTS](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000085766.htm).
