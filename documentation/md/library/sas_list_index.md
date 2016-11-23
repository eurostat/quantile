## list_index {#sas_list_index}
Extract elements from a list at given position(s).

	%let res=%list_index(list, index, sep=%quote( ));

### Arguments
* `list` : a list of (_e.g._, blank separated) items;
* `index` : a list of numeric indexes providing with the positions of items to extract from `list`; 
	must that the values of items in `index` should be < length of the list and >0; 
* `sep` : (_option_) character/string separator in input list `list` (but not `index`); default: 
	`%%quote( )`, _i.e._ `sep` is blank.
 
### Returns
`res` : output list defined as the sequence of elements extract from the input list `list` so that:
		+ the `i`-th element in `res` is equal to the `j`-th element of `list` where the position `j` 
		is given by the `i`-th element of `index`.

### Examples

	%let index = 3 5 2 100 4 1;
	%let list=a bb ccc dddd bb fffff;
	%let res=%list_index(&list, &index);
	
returns: `res=ccc bb bb dddd a` since the index 100 is ignored.
 
Run macro `%%_example_list_index` for more examples.

### Notes
1. Indexes larger than the length of the input list `list` are ignored, while whenever one index is <0,
and error is generated.
2. For wrongly typed indexes (_e.g._ non numeric index), an error is also generated.
3. In general case of error, the output `res` returned is empty (_i.e._ `res=`).

### See also
[%clist_index](@ref sas_clist_index), [%list_slice](@ref sas_list_slice), [%list_compare](@ref sas_list_compare), 
[%list_count](@ref sas_list_count), [%list_remove](@ref sas_list_remove), [%list_append](@ref sas_list_append),
[%INDEX](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000543562.htm).
