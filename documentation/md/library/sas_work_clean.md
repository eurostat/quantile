## work_clean {#sas_work_clean}
Clean the working directory.

	%work_clean(ds, ...);

### Arguments
`ds` : (_option_) datasets in the `WORK`ing directory to clean; parameters are passed as `parmbuff`,
	_i.e._ comma-separated arguments; If `ds` is not set (or simply not passed), all datasets present
	in the `WORK` directory are 'cleaned'.
	
### Notes
1. The instruction to "clean" (delete) two datasets `ds1` and `ds2` from your  `WORK`ing directory is:

       %work_clean(ds1, ds2);
while the instruction to clean all the `WORK`ing directory is:

    %work_clean;	
2. Use `kill` or `delete` depending whether a dataset is passed or not (again, in the latter case, 
the whole `WORK`ing directory is deleted).
