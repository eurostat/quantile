## list_append {#sas_list_append}
Append (_i.e._, concatenate) a unformatted (char or numeric) list to another, possibly 
interleaving the elements in the lists.

	%let conc=%list_append(list1, list2, zip=no, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of unformatted of numeric/strings;
* `zip` : (_option_) a boolean flag (`yes/no`) or a character separator set to interleave the lists; 
	when `zip=yes`, the i-th element from each of the lists are appended together and put into the 2*i-1 
	element of the output list; the returned list is truncated in length to the length of the shortest 
	list; similarly, when `zip` is set to a special character, the lists are interleaved as before and 
	this character is used as a separator between the zipped elements; when `zip=_EMPTY_`, items are
	zipped without separation, while when `zip=_BLANK_`, they are zipped with a blank space; default: 
	`zip=no`, _i.e._ lists are simply appended;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`;
* `rep` : (_option_) replacement character/string separator in outptu list; default: `rep=&sep`.

### Returns
`conc` : output concatenated list of characters, _i.e._ the list obtained as the union/concatenation 
	of the input lists `list1` and `list2`, which is of the form: `a11&zip.a21&sep.a12&zip.a22&sep...`
	when `zip` is not a boolean flag, `a11 a21&sep.a12 a22&sep...` otherwise, where `a1i` is the `i`-th 
	element of the `list1`, ibid for `a2j`.

### Examples

	%let list1=A B C D E;
	%let list2=F G H I J; 
	%let conc=%list_append(&list1, &list2); 
	
returns: `conc=A B C D E F G H I J`. 

	%let list0=1 2 3;
	%let conc=%list_append(&list0, &list1, zip=yes);
	
returns: `conc=1 A 2 B 3 C`, while: 

	%let conc=%list_append(&list0, &list1, zip=%str(-));
	
returns: `conc=1 - A 2 - B 3 - C`, while: 

	%let conc=%list_append(&list0, &list1, zip=yes, rep=%str(, ));

returns: `conc=1 A, 2 B, 3 C`. 

Run macro `%%_example_list_append` for more examples.

### See also
[%clist_append](@ref sas_clist_append), [%clist_difference](@ref sas_clist_difference).
