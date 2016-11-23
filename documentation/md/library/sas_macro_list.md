## macro_list {#sas_macro_list}
List all macros made available to a SAS session through SASAUTOS.

	%macro_list(work=no, dsn=, _maclst_=, lib=WORK, print=no);

### Argument
* `work` : (_option_) boolean flag (`yes/no`) set to list `WORK.SASMACR` entries; default: `work=no`.
* `lib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used;
* `print` : (_option_) boolean flag (`yes/no`) set to print the output on the log page; default:
	`print=no`.

### Returns
* `dsn` : (_option_) output dataset created in `lib` library; this dataset contains five fields, respectively:
		+ `path` for the absolute path of macro location (path separator is slash '/'), and 
		+ `member` for the macro/file name, and
		+ `catalog` for the name of the catalog the macro maypossibly be stored in (empty otherwise), and 
		+ `type` for the type of the macro (_e.g._, `.sas` for filenames, or `macro` for macros in catalog), 
		and
		+ `order` indicating the search order SAS uses;

 If intead your require the output to be stored in a file, use `print=no` above together with a `PROC PRINTTO` 
to reroute the output appropriately.
* `_maclst_` : (_option_) name of the macro variable where the list of SAS macro names as they appear in 
	 `member` (_i.e._, without extension)will be stored.

### Notes
1. **The macro `%%macro_list` is  a wrapper to H. Droogendyk's original `%%list_sasautos` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.stratia.ca/papers/list_sasautos.sas>. See reference below.
2. This macro prints the `.sas` member names of the various directories and filerefs returned by the 
`GETOPTION(SASAUTOS)` and `PATHNAME(SASAUTOS)` functions.  Also examines `WORK.SASMACR` and the 
`SASMACR` catalog referenced by the `PATHNAME(GETOPTION(SASMSTORE))`.
3. This macro may generate the following accepted warning:

       WARNING: Variable member has different lengths on BASE and DATA files

### Reference
Droogendyk, H. (2009): ["Which SASAUTOS macros are available to my SAS session?"](http://support.sas.com/resources/papers/proceedings09/076-2009.pdf)
([presentation](http://www.sas.com/content/dam/SAS/en_ca/User%20Group%20Presentations/TASS/Droogendyk-AvailableSASAUTOSMacros.pdf)).

### See also
[%macro_exist](@ref sas_macro_exist),
[%list_sasautos][http://www.stratia.ca/papers/list_sasautos.sas].
