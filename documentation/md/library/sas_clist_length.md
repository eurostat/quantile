## clist_length {#sas_clist_length}
Compute the length of a formatted (_i.e._, comma-separated and quota-enhanced) list of strings. 

	%let len=%clist_length(clist, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist` : a list of formatted (_e.g._, comma-separated quote-enhanced) strings;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`len` : output length, _i.e._ the length of the  considered list (say it otherwise, the number 
	of strings separated by `mark`).

### Examples

	%let clist=("DE","AT","BE","NL","UK","SE");
	%let len=%clist_length(&clist);
	
returns `len=6`.

Run macro `%%_example_clist_length` for more examples.

### Notes
1. Note the "special" treatment of empty items, _e.g._

       %let clist=("DE",,,,"UK");
       %let len=%clist_length(&clist);
will return `len=2`, _i.e._ the comma-separated empty items are not taken into
account in the counting.
2. See note of [%list_length](@ref sas_list_length).
3. The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_length](@ref sas_list_length), [%clist_unquote](@ref sas_clist_unquote).
