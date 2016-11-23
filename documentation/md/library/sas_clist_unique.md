## clist_unique {#sas_clist_unique}
Trim a given formatted list from its duplicated elements and return the list of unique items.

	%let cluni=%clist_unique(clist, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive representation; default:
	`casense=no`, _i.e._ lower- and upper-case versions of the same strings are considered as equal;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`cluni` : output formatted list of unique elements present in the input list `clist`; when the case 
	unsentiveness is set (through `casense=no`), `cluni` is returned as a list of upper case elements.

### Examples

	%let clist=("A","B","b","b","c","C","D","E","e","F","F","A","B","E","D");
	%let cluni=%clist_unique(&clist, casense=yes);
	
returns: `cluni=("A","B","b","c","C","D","E","e","F")`, while:

	%let cluni=%clist_unique(&clist);
	
returns: `cluni=("A","B","C","D","E","F")`.

Run macro `%%_example_clist_unique` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_unique](@ref sas_list_unique), [%list_slice](@ref sas_list_slice), [%clist_compare](@ref sas_clist_compare), 
[%clist_append](@ref sas_clist_append), [%clist_unquote](@ref sas_clist_unquote).
