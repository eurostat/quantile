## var_to_list {#sas_var_to_list}
Extract the values of a given variable in a dataset into an unformatted (_i.e._, unquoted 
and blank-separated) list.

	%var_to_list(dsn, var, _varlst_=, distinct=no, na_rm=yes, sep=%str( ), lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : either a field name, or the position of a field name in, in `dsn`, whose values (observations) 
	will be converted into a list;
* `distinct` : (_option_) boolean flag (`yes/no`) set to return in the list only distinct values
	from `var` variable; in practice, runs a SQL `SELECT DISTINCT` process prior to the values'
	extraction; default: `no`, _i.e._ all values are returned;
* `sep` : (_option_) character/string separator in output list; default: `%%str( )`, _i.e._ `sep` 
	is blank;
* `na_rm` : (_option_) boolean flag (`yes/no`) set to remove missing (NA) values from the observations;
	default: `na_rm=yes`, therefore all missing (`.` or ' ') values will be discarded in the output
	list;
* `lib` : (_option_) output library; default: `lib` is set	to `WORK`.

### Returns
`_varlst_` : name of the macro variable used to store the output list, _i.e._ the (blank-separated) list 
	of (possibly non-missing) observations in `var`.

### Examples
Let us consider the test dataset #28 in `WORK.dsn`:
geo | value 
----|-------
 AT |  1    
 '' |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  4 
then the following call to the macro:

	%let ctry=;
	%var_to_list(_dstest28, geo, _varlst_=ctry);
	%var_to_list(_dstest28,   1, _varlst_=ctry);
	
will both return: `ctry=AT BG FR IT`, while:

	%let val=;
	%var_to_list(_dstest28, value, distinct=yes, _varlst_=val);

will return: `val=1 2 3 4`, and:

	%var_to_list(_dstest28, value, distinct=yes, _varlst_=val, na_rm=no);
	%var_to_list(_dstest28,     2, distinct=yes, _varlst_=val, na_rm=no);

will both return: `val=1 . 2 3 . 4`.

Run macro `%%_example_var_to_list` for more examples.

### Note
1. In short, this macro runs, when `distinct=yes`, and `na_rm=yes`:

       PROC SQL noprint;
			SELECT DISTINCT	&_var 
			INTO: &_varlst_  SEPARATED BY "&sep" 
			FROM &lib..&dsn
			WHERE not missing(&_var);
		quit;
2. For empty variables (_i.e._ with no observation, or missing data while default `na_rm=no`), an empty 
list is returned. 
3. On data conversion, format and informat: 
	* <http://support.sas.com/publishing/pubcat/chaps/59498.pdf>,
	* <http://www.sys-seminar.com/EE/Files/Converting%20Numeric%20and%20Character%20Data.pdf>.

## References
1. Satchi, T. (2002): ["Using the magical keyword "INTO:" in PROC SQL"](http://www2.sas.com/proceedings/sugi27/p071-27.pdf).
2. Rozhetskin, D. (2010): ["Choosing the best way to store and manipulate lists in SAS"](http://www.wuss.org/proceedings10/coders/2972_9_COD-Rozhetskin.pdf).

### See also
[%list_to_var](@ref sas_list_to_var), [%var_to_clist](@ref sas_var_to_clist), [%var_count](@ref sas_var_count), 
[%var_info](@ref sas_var_info).
