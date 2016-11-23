## clist_append {#sas_clist_append}
Append (_i.e._, concatenate) a comma-separated quote-enhanced (char or numeric) list to another, 
possibly interleaving the items in the lists.

	%let conc=%clist_append(clist1, clist2, zip=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `zip` : (_option_) a boolean flag (`yes/no`) set to interleave the lists; when `zip=yes`, 
	the i-th element from each of the lists are appended together and put into the 2*i-1 element 
	of the output list; the returned list is truncated in length to the length of the shortest list; 
	default: `zip=no`, _i.e._ lists are simply appended;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist1` and
	`clist2` are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`conc` : output concatenated list of characters, _e.g._ the list of comma-separated (if `sep=%%quote(,)`) 
	items in between quotes (if `mark=%%str(%")`) obtained as the union/concatenation of the input lists
	`clist1` and `clist2`.

### Examples

	%let clist1=("A","B","C","D","E");
	%let clist2=("F","G","H","I","J"); 
	%let conc=%clist_append(&clist1, &clist2) 
	
returns: `conc=("A","B","C","D","E","F","G","H","I","J")`. 

	%let clist0=("1","2","3");
	%let conc=%clist_append(&clist0, &clist1, zip=yes) 
	
returns: `conc=("1","A","2","B","3","C")`. 

Run macro `%%_example_clist_append` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%clist_append](@ref sas_clist_append), [%clist_difference](@ref sas_clist_difference), [%clist_unquote](@ref sas_clist_unquote), [%list_quote](@ref sas_list_quote).
