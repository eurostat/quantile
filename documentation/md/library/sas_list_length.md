## list_length {#sas_list_length}
Compute the length of an unformatted (_i.e._, blank separated) list of strings. 

	%let len=%list_length(list, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`len` : output length, _i.e._ the length of the considered list (calculated as the number of strings 
	separated by `sep`).

### Examples

	%let list=DE_UK_LU_AT_EL_IT;
	%let len=%list_length(&list, sep=_);
	
returns `len=6`.

Run macro `%%_example_list_length` for examples.

### Note
As kindly reported by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>, _a.k.a_ the "Base-Ball 
Equation Solver") in his own well-tempered language, this macro is mostly useless as one can check that 
running `%list_length(&list, &sep)` is essentially nothing else than:
	
	%sysfunc(countw(&list, &sep));

Still, we enjoyed recoding it (and so did the GSAST guys, though it seemed "complex"). Further note that
one could also use (in the case `sep=%%quote( )`):

	%eval(1 + %length(%sysfunc(compbl(&list))) - %length(%sysfunc(compress(&list))))

### See also
[%clist_length](@ref sas_clist_length), [%list_count](@ref sas_list_count), 
[LENGTH](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000218807.htm).
[COUNTW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002977495.htm).
