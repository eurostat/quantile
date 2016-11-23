## ds_rename {#sas_ds_rename}
Rename one or more datasets in the same SAS library.

	%ds_rename(olddsn, newdsn, lib=WORK);

### Arguments
* `olddsn` : (list of) old name(s) of reference dataset(s);
* `newdsn` : (list of) new name(s); must be of the same length as `olddsn`;
* `lib` : (_option_) name of the library where the dataset(s) is (are) stored; default: `lib=WORK`.
	
### Note
In short, this macro runs:

	PROC DATASETS;
		%do i=1 %to %list_length(&olddsn);
			CHANGE %scan(&olddsn,&i)=%scan(&newdsn,&i);
		%end;
	quit;

### See also
[CHANGE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000247645.htm).
