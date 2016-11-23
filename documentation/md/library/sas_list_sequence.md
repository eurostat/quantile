## list_sequence {#sas_list_sequence}
Generate a list of linearly spaced NUMERIC values as an arithmetic progression.

	%let seq=%list_sequence(len=, start=, step=, end=, sep=%quote( ));

### Arguments
* `len` : (_option_) lenght of the output generated list; it can be omitted if and only if all 
	other options below (_e.g._, `start`, `end` and `step`) are present, and then it is set to 
	`floor[(end - start)/ step + 1]`;
* `start` : (_option_) starting value of the generated list, _i.e._ the first element in the 
	output list will be `start`; default: `start=1`; when omitted, it is set to:
			+ `end - step * (len-1)` when all other options are present,
			+ `1` otherwise;
* `step` : (_option_) "step" between the items in the generated list, _i.e._ the difference/space 
	between two consecutive items in the output list will be equal to `step`; step must be non-zero; 
	when omitted, it is set to:
			+ `(end-start)/(len-1)` when all other options are present,
			+ `1` otherwise;
	further note that `step` is "forced" to 1 when `start` and `end` are passed, but `len` is not;
* `end` : (_option_) ending value of the generated list; note that depending on the other settings 
	(_e.g._, `len`, `start` and `step`), the last element in the output list will not necessary be 
	equal to `end`; when omitted, it is set to: `start + (len - 1) * step`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`seq` : output arithmetic list of evenly spaced items of lenght `len` and of the form 
	`start start+step start+2*step ...`. 

### Examples
The following examples:

	%let seq1=%list_sequence(len=10);
	%let seq2=%list_sequence(len=10, start=10);
	%let seq3=%list_sequence(len=10, end=20, step=2);
	
return `seq1=1 2 3 4 5 6 7 8 9 10`, `seq2=10 12 13 14 15 16 17 18 19 20`, and 
`seq3=2 4 6 8 10 12 14 16 18 20`, respectively, while:

	%let seq4=%list_sequence(len=10, start=10, step=-1);
	%let seq5=%list_sequence(len=10, end=10, step=-1);

return `seq1=10 9 8 7 6 5 4 3 2 1` and `seq2=19 18 17 16 15 14 13 12 11 10`. Note also that:

	%let seq6=%list_sequence(start=1, end=20, step=3);

will return `seq1=1 4 7 10 13 16 19`, hence excluding 20 from the list.

Run macro `%%_example_list_sequence` for examples.

### Notes
1. When `step` is positive (resp. negative), the last element in the output list is the largest
value `start + i * step` that is less (resp. greater) than or equal to `end`.
2. This macro is obviously inspired by the [`linspace`](http://nl.mathworks.com/help/matlab/ref/linspace.html) 
and [`colon, :`](http://nl.mathworks.com/help/matlab/ref/colon.html) operators in Matlab, and 
[`xrange`](https://docs.python.org/2/library/functions.html#range) operator in Python. 

### See also
[%list_permutation](@ref sas_list_permutation), [%list_length](@ref sas_list_length), 
[%list_count](@ref sas_list_count).
