## var_dummy {#sas_var_dummy}
Create dummy variables in a dataset, _i.e._ variables with labels used to describe 
membership in a category with binary coding.

   %var_dummy(idsn, var, odsn=, prefix=, base=, format=, fullrank=yes, ilib=, olib=);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : (_option_) name of the output dataset; 
* `prefix` : (_option_) prefix(s) used to create the names of dummy variables; the
	default is 'D_'; you can give one or more strings, in an order corresponding to the 
	`var` variables; note that `prefix=_VARNAME_`, which will use the name of the
	corresponding variable followed by an underscore, or `prefix=_BLANK_`, which will make 
	the prefix a null string (similar to specifying a null string in the macro argument) 
	are also accepted; 
* `name` : (_option_) if `name=_VAL_`, the dummy variables are named by appending the value 
	of the `var` variables to the prefix, otherwise, the dummy variables are named by 
	appending numbers, 1, 2, ... to the prefix; note that the resulting name must be 8 
	characters or less.; default: `name=_VAL_`;
* `base` :(_option_) indicates the level of the baseline category, which is given values 
	of 0 on all the dummy variables; you can give one or more strings, in an order 
	corresponding to the `var` variables; parameters `base=_FIRST_` or `base=_LOW_` specify
	that the lowest value of the VAR= variable is the baseline group; `base=_LAST_` or 
	`base=_HIGH_` specify the highest value of the variable; otherwise, you can specify 
	`base=<value>` to make a different value the baseline group; for a character variable, 
	you must enclose the value in quotes, _e.g._, `base=`'M'; 
* `format` : (_option_) user formats may be used for two purposes:  
		+ to name the dummy variables, and 
		+ to create dummy variables which are indicators for ranges of the input variable; 
	variables using the format option must be listed first in the`var` list.
* `fullrank` : (_option_) boolean flag (`yes/no`), set to `yes` to indicate that the indicator 
	for the `base` category is eliminated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also 
	used.

### Returns
if not specified, the new
           variables are appended to the input dataset
 
### Examples
With the input data set:
 y | group | sex
:-:|:------|:----
10 |   A   |  M 
12 |   A   |  F 
13 |   A   |  M  
18 |   B   |  M 
19 |   B   |  M 
16 |   C   |  F 
21 |   C   |  M 
19 |   C   |  F  
the macro statement:

	%var_dummy(test, group) ;

produces two new variables, `D_A` and `D_B` in the table `test`:  
 y | group | sex | D_A | D_B
:-:|:------|:----|----:|-----:			
10 |   A   |  M  |  1  |   0
12 |   A   |  F  |  1  |   0
13 |   A   |  M  |  1  |   0
18 |   B   |  M  |  0  |   1
19 |   B   |  M  |  0  |   1
16 |   C   |  F  |  0  |   0
21 |   C   |  M  |  0  |   0
19 |   C   |  F  |  0  |   0
since group `C` is the baseline category (corresponding to `base=_LAST_`). With the input dataset:

  * proc format;
    *  value $sex 'M'='Male' 'F'='Female';
   %var_dummy(test, var =sex group, format=$sex, prefix=_BLANK_ _VARNAME_) ;

 produces a dummy for `sex` named FEMALE, and two dummies for `group`:
 y | group | sex | FEMALE | GROUP_A | GROUP_B
:-:|:------|:----|-------:|--------:|---------:			
10 |   A   |  M  |   0    |    1    |    0
12 |   A   |  F  |   1    |    1    |    0
13 |   A   |  M  |   0    |    1    |    0
18 |   B   |  M  |   0    |    1    |    1
19 |   B   |  M  |   0    |    1    |    1
16 |   C   |  F  |   1    |    1    |    0
21 |   C   |  M  |   0    |    1    |    0
19 |   C   |  F  |   1    |    1    |    0

### Notes
1. **The macro `%%var_dummy` is  a wrapper to M. Friendly's original `%%dummy` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html>. See 
resources available at [DataVis.ca](http://www.datavis.ca/sasmac/).
2. Given a character or discrete numerical variable, the `%%var_dummy` macro creates
dummy (0/1) variables to represent the levels of the original variable.  If the original 
variable has `c` levels, then `(c-1)` new variables are produced (or `c` variables, if 
`fullrank=yes`).

 When the original variable is missing, all dummy variables will be 
 missing (V7+ only).


http://www.math.yorku.ca/SCS/sasmac/dummy.html

### See also
[DUMMY](http://www.datavis.ca/sas/vcd/macros/dummy.sas).
=*/
 
%macro var_dummy(idsn    		/* Name of input dataset                  				(REQ) */
