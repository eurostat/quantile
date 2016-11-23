## list_sort {#sas_list_sort}
Sort a list of numeric values in ascending or descending order.

	%list_sort(list, _list_=, order=asc, sep=%quote( ));

### Arguments
* `list` : list of numeric items that will be sorted;
* `order` : (_option_) string defining ascending (`asc`) or descending (`desc`) order; default: 
	`order=asc`; 
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`_list_` : output ordered list.

### Example
let us consider the following simple example:

	%let list=4.5 21 1 -1 0.2 -8 65 7.8;
	%let olist=;
	%list_sort(&list, _list_=olist);

it will return `olist=-8 -1 0.2 1 4.5 7.8 21 65`.

Run macro `%%_example_list_sort` for examples.

### Note
In short, this macro runs, in the case `order=asc`, the following operations:

	%list_to_var(&list, tmpval, tmpdsn, fmt=best32., sep=&sep);
	%ds_sort(tmpdsn, asc=tmpval);
	%var_to_list(tmpdsn, tmpval, _varlst_=&_list_, sep=&sep);

### See also
[%ds_sort](@ref sas_ds_sort), [%list_permutation](@ref sas_list_permutation), 
[%list_to_var](@ref sas_list_to_var), [%var_to_list](@ref sas_var_to_list).
