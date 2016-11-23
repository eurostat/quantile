## clist_ones {#sas_clist_ones}
Create a simple list of replicated items with given length.

	%let clist=%clist_ones(len, item=, sep=%str(,), mark=%str(%"));

### Arguments
* `len` : desired length of the output list;
* `item` : (_option_) item to replicate in the list; default: `item=1`, _i.e._ the list 
	will be composed of 1 only;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`list` : output list where `item` is replicated and concatenated `len` times.

### Examples
Simple examples like:

	%let res1= %clist_ones(5);
	%let res2= %clist_ones(3, a);

return `res1=("1","1","1","1","1")` and `res2=("a","a","a")` respectively, while it is also possible:

	%let x=1 2 3;
	%let res1=%clist_ones(5, item=&x);

returns `res1=("1","2","3","1","2","3","1","2","3","1","2","3","1","2","3")`.

Run macro `%%_example_clist_ones` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_ones](@ref sas_list_ones), [%list_append](@ref sas_list_append), [%list_index](@ref sas_list_index).
