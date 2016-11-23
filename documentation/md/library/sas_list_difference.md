## list_difference {#sas_list_difference}
Calculate the (asymmetric) difference between two unformatted lists of char.

	%let diff=%list_difference(list1, list2, casense=no, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists need to differ;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`diff` : output concatenated list of characters, namely the list of strings obtained as the asymmetric 
	difference: `list1 - list2`.

### Examples

	%let list1=A B C D E F;
	%let list2=A B C;
	%let diff=%list_difference(&list1, &list2);
	
returns: `diff=D E F`, while:

	%let diff=%list_difference(&list2, &list1);
	
returns: `diff=`.
 
Run macro `%%_example_list_difference` for more examples.

### Note
This is a setwise operation to be understood as `list1 \ list2`.

### See also
[%list_intersection](@ref sas_list_intersection), [%clist_difference](@ref sas_clist_difference), [%list_compare](@ref sas_list_compare), 
[%list_append](@ref sas_list_append), [%list_find](@ref sas_list_find).
