## par_check {#sas_par_check}
Perform simple logical/acceptance test on a given NUMERIC or CHAR (list of) parameter(s).

	%let ans=%par_check(par, type=, range=, norange=, set=, noset=, casense=no);

### Arguments
* `par` : (list of) parameter(s) to test; can be either of NUMERIC or CHAR type;
* `type` : (_option_) flag set to check whether the input parameter is `NUMERIC`, `INTEGER` or `CHAR`; 
	in the case `type=INTEGER`, and `par` is actually `NUMERIC`, it is further tested whether `par` is 
	an integer or not; default: empty, _i.e._ the type of `par` is not tested;
* `range` : (_option_) range of acceptance values for the input parameter; this is a list of length <=2 
	of the form `min max` representing the minimum and maximum values of the range `]min, max[` to be 
	tested against `par` in the case it is `NUMERIC`; in the case the length of `range` is 1, then only
	the minimum value is tested, _i.e._ it is regarded as `range=min`; this option is incompatible with
	`type` when `type` is set to `CHAR`; default: empty, _i.e._ no range is tested;
* `norange` : (_option_) ibid for the exlusion range for the input parameter, _i.e._ the range `]min, max[`
	of values to which `par` should not belong; in the case the length of `range` is 1, then only the 
	maximum value is tested, _i.e._ it is regarded as `norange=max` default: empty, _i.e._ no range is 
	tested;
* `set` : (_option_) list supporting the set of acceptance values for the input parameter which will
	be tested against all the values in it; default: empty, _i.e._ no values are tested;
* `noset` : (_option_) ibid for the list of exluded values for the input parameter; default: empty, _i.e._ 
	no values are tested;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive checking when the input
	parameter tested is CHAR; default: `casense=no`, _i.e._ the checking does not take into account the
	cases.

### Returns
`ans` : (list of) error codes of the test (hence of same length as `par`) where for each item in `par`
the corresponding item in `ans` is set to:
		+ `0` if the item verifies all the conditions expressed by `type`, `range`, `norange`, `set`, 
			and/or `noset`,
    	+ `1` if the item does not verify the conditions on `type` and/or (in the case `par` is of
			`NUMERIC` type and `type=INTEGER` is tested) it is also an integer, 
		+ `2` if the item does not verify the value conditions on `noset` (_e.g._, `par` is `NUMERIC`
			and is listed in `noset`),
		+ `3` if the item does not verify the conditions on `range` and/or `norange` (_e.g._, `par` is 
			`NUMERIC` and does not lie in the range `range`).

### Examples
Simples checks can be ran over NUMERIC parameters, for instance we can test whether a parameter is a 
strictly positive or negative integer, _e.g._:

	%let ans=%par_check(1, type=INTEGER, range=0);
	%let ans=%par_check(-1, type=INTEGER, norange=0);

will both return `ans=0`. More practically, we can also test whether a given parameter `par` is within 
the range ]0,10[, _e.g._ using:

	%let par=9.5;
	%let ans=%par_check(&par, range=0 10);

then we will have `ans=2`; we may also want to test whether that same parameter is in the range `[0 10]` 
(_i.e._ including the bounds) using:

	%let ans=%par_check(&par, range=0 10, set=0 10);

which returns `ans=0`; finally, we can test whether it is an integer:

	%let ans=%par_check(&par, type=INTEGER, range=0 10, set=0 10);

which will return `ans=1` this time. To test whether it is a positive or nul value, we can simply run:

	%let ans=%par_check(&par, type=NUMERIC, range=0, set=0);

which aims in fact at testing whether `par` is in the range `]0,+inf[` or equal to `{0}`, and returns 
`ans=0`. It is then possible to test several parameters together, _e.g._:

	%let par=1 a 10 9.5 2;
	%let ans=%par_check(&par, type=INTEGER, range=0 10);

which returns `ans=0 1 2 1 0` since it checks the items in the list `par` are integers in the range 
]0,0[. As for CHAR parameters, the test consists simply in checking the inclusion of the `par` string 
into the set formed by `set`, _e.g._:

	%let par=at;
	%let ans=%par_check(&par, type=CHAR, set=DE FR AT SE);

will return `ans=0` (since `casense=no` by default).

Run `%%_example_par_check` for more examples.

### Notes
1. As in the examples above, whenever you want to test whether a NUMERIC value is an Integer in a closed 
range `[&a,&b]`, you shall run:

    %let ans=%par_check(&par, type=INTEGER, range=&a &b, set=&a &b);
so as to test in practice whether it is in the union: `]&a,&b[ U {&a,&b}`. Note that the order in `set`
does not matter, _i.e._ `set=&b &a` is also accepted.
2. More generally, for NUMERIC parameters `par`, the following command:

       %let ans=%par_check(&par, type=INTEGER, range=&a &b, set=&c, norange=&x &y, noset=&z);
tests whether `par` is in the set represented by `(]&a,&b[ U {&c}) \ (]&x,&y[ U {&z})`.

### Reference
Wilson, S.A. (2011): ["The validator: A macro to validate parameters"](http://support.sas.com/resources/papers/proceedings11/015-2011.pdf).

### See also
[%macro_isblank](@ref sas_macro_isblank).
