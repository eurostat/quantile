## list_unique {#sas_list_unique}
Trim a given list from its duplicated elements and return the list of unique items.

	%let luni=%list_unique(list, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive representation; default:
	`casense=no`, _i.e._ lower- and upper-case versions of the same strings are regarded as repeated 
	elements and one only shall be kept;
* `sep` : (_option_) character/string used as a separator in the input list; default: `sep=%%quote( )`, 
	_i.e._ the input `list` is blank-separated lists of items.
 
### Returns
`luni` : output list of unique elements present in the input list `list`; when the case unsentiveness is
	set (through `casense=no`), `luni` is returned as a list of upper case elements.

### Examples
We show some simple examples of use, namely: 

	%let list=A B b b c C D E e F F A B E D;
	%let luni=%list_unique(&list, casense=yes);
	
returns: `luni=A B b c C D E e F`, while:

	%let luni=%list_unique(&list);
	
returns: `luni=A B C D E F`.

Run macro `%%_example_list_unique` for more examples.

### See also
[%clist_unique](@ref sas_clist_unique), [%list_difference](@ref sas_list_difference), [%list_compare](@ref sas_list_compare), 
[%list_append](@ref sas_list_append), [%list_find](@ref sas_list_find), [%list_count](@ref sas_list_count).
