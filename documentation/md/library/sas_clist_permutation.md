## clist_permutation {#sas_clist_permutation}
Perform a pseudo-random permutation of either the elements of a list or a sequence of integers.

	%clist_permutation(par, _clist_=, seed=, mark=%str(%"), sep=%quote(,));

### Arguments
* `par` : input parameter; this can be:
		+ either a positive INTEGER defining the desired length of the output list,
		+ or a list whose items will be permuted/shuffled;
* `seed` : (_option_) seed of the pseudo-random numbers generator; if seed<=0, the time of day 
	is used to initialize the seed stream; default: `seed=0`; see [%ranuni](@ref sas_ranuni);
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`_clist_` : output sequenced list, _i.e._ the length of the considered list (calculated as the number of 
	strings separated by `sep`).

### Examples
Using a fixed seed, it is possible to retrieve pseudo-random lists (sequence) of INTEGER values, _e.g._:

	%let olist=;
	%let seed=1;
	%let par=10;
	%list_permutation(&par, _list_=olist, seed=&seed);
	
(always) returns `olist=9 10 1 4 3 8 7 5 6 2`, while using the same seed over some lists of NUMERIC or CHAR 
lists enables us to permute the items of the lists, _e.g._:

	%let par=a b c d e f g h i j;
	%list_permutation(&par, _list_=olist, seed=&seed);
	%let alist=;
	%let par=-2 105 43 56 89 0.5 8.2 10 1 0;
	%list_permutation(&par, _list_=alist, seed=&seed);

return always the same lists `olist=i j a d c h g e f b` and `alist=1 0 -2 56 43 10 8.2 89 0.5 105`.

Run macro `%%_example_list_permutation` for examples.

### Notes
1. In the example above, one can simply check that `%%list_compare(&par, &olist)=0` holds.
2. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%ranuni](@ref sas_ranuni), [%list_sequence](@ref sas_list_sequence).
