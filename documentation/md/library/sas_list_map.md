## list_map {#sas_list_map}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

	%list_map(map, list, _maplst_=, var=, casense=no, sep=%quote( ), lib=WORK);

### Arguments
* `map` : input mapping table, _i.e._ dataset storing the lookup correspondance;
* `list` : list of unformatted strings;
* `var` : (_option_) fields of the `map` table used as origin and destination (in this order)
	of the mapping; default: `var=1 2`, _i.e._ the first and second fields (in `varnum` order)
	are used as origin and destination respectively;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive comparison/matching; 
	default: `casense=no`, _i.e._ upper-case items in `list` and the origin variable are matched;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items;
* `lib` : (_option_) input library where `map` is stored; default: `lib` is set	to `WORK`.
 
### Returns
`_maplst_` : name of the variable storing the output list built as the list of items obtained through
	the transform defined by the variables `var` of the table `map`, namely: assuming all elements
	in `list` can be found in the (unique) observations of the origin variable, the element in the `i`-th 
	position of the output list is the `j`-th element of the destination variable when `j` is the position
	of the `i`-th element of `list` in the origin variable. 

### Example
Given test dataset `_dstest32`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5
used as a mapping table, running the simple operation:

	%let list=FR LU BG;
	%let maplst=
	%list_map(_dstest32, &list, _maplst_=maplst, var=1 2);

returns: `maplst=0.4 0.3 0.2`.	

Run macro `%%_example_list_map` for more examples.

### Note
It is not checked that the values in the origin variable are unique. 

### See also
[%var_to_list](@ref sas_var_to_list), [%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index),
[%ds_select](@ref sas_ds_select).
