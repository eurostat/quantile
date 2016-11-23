## list_ones {#sas_list_ones}
Create a simple list of replicated items with given length.

	%let list=%list_ones(len, item=, sep=%quote( ));

### Arguments
* `len` : desired length of the output list;
* `item` : (_option_) item to replicate in the list; default: `item=1`, _i.e._ the list 
	will be composed of 1 only;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`.
 
### Returns
`list` : output list where `item` is replicated and concatenated `len` times.

### Examples
Simple examples like:

	%let res1= %list_ones(5);
	%let res2= %list_ones(3, a);

return `res1=1 1 1 1 1` and `res2=a a a` respectively, while it is also possible:

	%let x=1 2 3;
	%let res1=%list_ones(5, item=&x);

returns `res1=1 2 3 1 2 3 1 2 3 1 2 3 1 2 3`.

Run macro `%%_example_list_ones` for more examples.

### See also
[%list_append](@ref sas_list_append), [%list_index](@ref sas_list_index).
