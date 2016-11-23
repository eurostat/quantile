## clist_index {#sas_clist_index}
Extract elements from a formatted list at given position(s).

	%let res=%clist_index(clist, index, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a formatted (_e.g._, parentheses-enclosed, comma-separated quote-enhanced) list;
* `index` : a list of numeric indexes providing with the positions of items to extract from `list`; 
	must that the values of items in `index` should be < length of the list and >0; 
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`res` : output list defined as the sequence of elements extract from the input list `list` so that:
		+ the `i`-th element in `res` is equal to the `j`-th element of `list` where the position `j` 
		is given by the `i`-th element of `index`.

### Examples

	%let index = 3 5 2 100 4 1;
	%let list=("a","bb","ccc","dddd","bb","fffff");
	%let res=%list_index(&list, &index);
	
returns: `res=("ccc","bb","bb","dddd","a")` since the index 100 is ignored.
 
Run macro `%%_example_clist_index` for more examples.

### Notes
1. Indexes larger than the length of the input list `clist` are ignored, while whenever one index is <0,
and error is generated.
2. For wrongly typed indexes (_e.g._ non numeric index), an error is also generated.
3. In general case of error, the output `res` returned is empty (_i.e._ `res=`).
4. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_index](@ref sas_list_index), [%clist_slice](@ref sas_clist_slice), [%clist_compare](@ref sas_clist_compare), 
[%clist_append](@ref sas_clist_append),
[%INDEX](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000543562.htm).
