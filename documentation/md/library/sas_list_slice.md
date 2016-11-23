## list_slice {#sas_list_slice}
Slice a given list, _i.e._ extract a sequence of items from the beginning and/or ending positions and/or 
matching items.

	%let res=%list_slice(list, beg=, ibeg=, end=, iend=, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `beg` : (_option_) item to look for in the input list; the slicing will 'begin' from the
	first occurrence of `beg`; if not found, an empty list is returned;
* `end` : (_option_) ibid, the slicing will 'end' at the first occurrence of `end`; if not found, 
	the slicing is done till the last item;
* `ibeg` : (_option_) position of the first item to look for in the input list; must be a numeric
	value >0; if the value is > length of the input list, an empty list is returned; incompatible
	with `beg` option (see above); if neither `beg` nor `ibeg` is passed, `ibeg` is set to 1; 
* `iend` : (_option_) ibid, position of the last item; must be a numeric value >0; in the case 
	`iend<iend`, an empty list is returned; in the case, `iend=ibeg` then the item `beg` (in position 
	`ibeg`) is returned; incompatible with `end` option (see above); if neither `end` nor `iend` is 
	passed, `iend` is set to the length of `list`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`res` : output list defined as the sequence of items extract from the input list `list` from the 
	`ibeg`-th position or the first occurrence of `beg`, till the `iend`-th position or the first 
	occurrence of `end` (after the `ibeg`-th position).

### Examples

	%let list=a bb ccc dddd bb fffff;
	%let res=%list_slice(&list, beg=bb, iend=4);
	
returns: `res=bb ccc`, while
 
	%let res=%list_slice(&list, beg=ccc);
	%let res2=%list_slice(&list, ibeg=bb, end=bb);
	%let res3=%list_slice(&list, beg=ccc, iend=3);
	
return respectively: `res=bb ccc dddd bb fffff`, `res2=bb ccc dddd` and `res3=ccc`.

Run macro `%%_example_list_slice` for more examples.

### Note
1. The first occurrence of `end` is necessarily searched for in `list` after the `ibeg`-th position 
(or first occurrence of `beg`).
2. The item at position `iend` (or first occurrence of `end`) is not inserted in the output `res` list.

### See also
[%list_index](@ref sas_list_index), [%list_compare](@ref sas_list_compare), [%list_count](@ref sas_list_count), 
[%list_remove](@ref sas_list_remove),  [%list_append](@ref sas_list_append).
