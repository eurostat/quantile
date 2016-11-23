## list_to_var {#sas_list_to_var}
Insert into a (possibly already existing) dataset a variable passed as an unformatted
(_i.e._, unquoted and blank-separated) list of values.

	%list_to_var(varlst, var, dsn, fmt=, sep=%quote( ), lib=WORK);

### Arguments
* `varlst` : unformatted (_i.e._, unquoted and blank-separated) list of strings;
* `var` : name of the variable to use in the dataset;
* `fmt` : (_option_) string used to specify the format of the variable, as accepted by 
	`ATTRIB`, _e.g._ something like `$10.` for a CHAR variable; by default, `fmt` is not 
	set, the variable will be stored as a CHAR variable;
* `sep` : (_option_) character/string separator in output list; default: `%%quote( )`, _i.e._ 
	`sep` is blank;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`dsn` : output dataset; if the dataset already exists, then observations with missing
	values everywhere except for the variable `&var` (possibly not present in dsn) will 
	be appended to the dataset. 

### Examples

	%let varlst=DE UK SE IT PL AT;
 	%list_to_var(&varlst, geo, dsn);	 

returns in `WORK.dsn` the following table:
	Obs|geo
	---|---
	 1 | DE
	 2 | UK
	 3 | SE
	 4 | IT
	 5 | PL
	 6 | AT
	 
Run macro `%%_example_list_to_var` for more examples.

### Note
If the dataset already exists and there is either no numeric, or no character variables  
in it, then the following warning will be issued:

    WARNING: Defining an array with zero elements.

This message is not an error.

### References
1. Carpenter, A.L. (1997): ["Resolving and using &&var&i macro variables"](http://www2.sas.com/proceedings/sugi22/CODERS/PAPER77.PDF).
2. Tsykalov, E. (2003): ["Processing large lists of parameters and variables with SAS arrays and macro language"](http://analytics.ncsu.edu/sesug/2003/CC08-Tsykalov.pdf).
3. Carpenter, A.L. (2005): ["Storing and using a list of values in a macro variable"](http://www2.sas.com/proceedings/sugi30/028-30.pdf).

### See also
[%var_to_list](@ref sas_var_to_list), [%clist_to_var](@ref sas_clist_to_var). 
