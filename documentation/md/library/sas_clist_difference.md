## clist_difference {#sas_clist_difference}
Calculate the (asymmetric) difference between two parentheses-enclosed, comma-separated and/or 
quote-enhanced lists of char.

	%let diff=%clist_difference(clist1, clist2, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of formatted (_e.g._, parentheses-enclosed, comma-separated 
	quote-enhanced) strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists need to differ;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input lists; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ `clist1` and `clist2` 
	are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`diff` : output concatenated list of characters, namely the list of (comma-separated) strings in between 
	quotes obtained as the asymmetric difference: `clist1 - clist2`.

### Examples

	%let clist1=("A","B","C","D","E","F");
	%let clist2=("A","B","C");
	%let diff=%clist_difference(&clist1, &clist2);
	
returns: `diff=("D","E","F")`, while:

	%let diff=%clist_difference(&clist2, &clist1);
	
returns: `diff=()`.
 
Run macro `%%_example_clist_difference` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_difference](@ref sas_list_difference), [%clist_compare](@ref sas_clist_compare), [%clist_append](@ref sas_clist_append), 
[%clist_unquote](@ref sas_clist_unquote), [%list_quote](@ref sas_list_quote).
