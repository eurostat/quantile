## clist_slice {#sas_clist_slice}
Slice a list, _i.e._ extract a sequence of items from the beginning and/or ending positionsand/or 
matching items.

	%let res=%clist_slice(clist, beg=, ibeg=, end=, iend=, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `beg` : (_option_) item to look for in the input list; the slicing will 'begin' from the
	first occurrence of `beg` (with quotes); if not found, an empty list is returned;
* `end` : (_option_) ibid, the slicing will 'end' at the first occurrence of `end`; if not found, 
	the slicing is done till the last item;
* `ibeg` : (_option_) position of the first item to look for in the input list; must be a numeric
	value >0; if the value is > length of the input list, an empty list is returned; incompatible
	with `beg` option (see above); if neither `beg` nor `ibeg` is passed, `ibeg` is set to 1; 
* `iend` : (_option_) ibid, position of the last item; must be a numeric value >0; in the case 
	`iend<iend`, an empty list is returned; in the case, `iend=ibeg` then the item `beg` (in position 
	`ibeg`) is returned; incompatible with `end` option (see above); if neither `end` nor `iend` is 
	passed, `iend` is set to the length of `list`;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`res` : output list defined as the sequence of items extract from the input list `list` from the `ibeg`-th 
	position or the first occurrence of `beg`, till the `iend`-th position or the first occurrence of `end` 
	(after the `ibeg`-th position).

### Examples

	%let clist=("a","bb","ccc","dddd","bb","fffff");
	%let res=%clist_slice(&clist, beg=bb, iend=4);
	
returns: `res=("bb","ccc")`, while
 
	%let res=%clist_slice(&list, beg=ccc);
	%let res2=%clist_slice(&list, ibeg=bb, end=bb);
	%let res3=%clist_slice(&list, beg=ccc, iend=3);
	
return respectively: `res=("bb","ccc","dddd","bb","fffff")`, `res2=("bb","ccc","dddd")` and `res3=("ccc")`.

Run macro `%%_example_clist_slice` for more examples.

### Notes
1. The parameters `beg` and `end` shall be passed without the quotes ".
2. The first occurrence of `end` is necessarily searched for in `list` after the `ibeg`-th position (or first occurrence of `beg`).
3. The item at position `iend` (or first occurrence of `end`) is not inserted in the output `res` list.
4. The macro returns an empty list `res=` instead of () when there is no match.
5. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_slice](@ref sas_list_slice), [%clist_compare](@ref sas_clist_compare), [%clist_append](@ref sas_clist_append), 
[%clist_unquote](@ref sas_clist_unquote).
