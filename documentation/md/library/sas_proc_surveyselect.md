## proc_surveyselect {#sas_proc_surveyselect}
Alternative sampling of a given dataset with same purpose as `PROC SURVEYSELECT` but a machine
independent implementation. 

	%proc_surveyselect(idsn, odsn, method, sampsize=, rep=, strata=, seed=0, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a reference input dataset;
* `method` : sampling method; only `SRS` (_i.e._ simple random sampling) and `URS` (_i.e._ unrestricted 
	random sampling, with replacement) are currently implemented;
* `sampsize, rep, seed, strata` : (_option_) same arguments as in `PROC SURVEYSELECT`; default:
	1, 1 (no repetition), 0 and '' respectively;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.

### Returns
`odsn` : name of the output table where the sampled data (of size `sampsize`, see above) will be stored. 

### Examples
Run macro `%%_example_proc_surveyselect` for examples.

### Notes
1. The current version of SAS (9.2 TS Level 2M3) on Solaris machines does not ensure the same output as 
SAS 9.3 and upper for the `PROC SURVEYSELECT`. The issue has been documented [here](http://support.sas.com/kb/53525). This macro provides with an alternative 
approach/algorithm that circumvents this problem for SRS and URS methods. In practice it enables the user 
to produce the same output whatever the SAS version used (see note 4 below). When running on different SAS versions, 
the sampled outputs generated from identical datasets with the same seed will also be identical.
2. In short, this is somehow equivalent to:

        PROC SURVEYSELECT DATA=&ilib..&dsn OUT=&olib..&odsn 
			METHOD = &method rep = &rep 
  			SAMPSIZE = &sampsize
  			SEED = &seed
 			ID &var;
	        STRATA &strata ;
		run;
with the parameters defined above. 
3. Following the implementation of PROC SURVEYSELECT, in case of stratified sampling, the algorithm will select by default 1 unit in each stratum. 
In case `sampsize` is set to one given number `*n*`, the algorithm will select `*n*` units in each stratum. 
Finally, in case `sampsize` designates the name of a dataset, this dataset is supposed to provide the stratum sample size in a variable named `_NSIZE_`.
4. The SYS method should also be implemented in a later version. 
5. This approach was implemented by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>).

### Reference
Fan, C.T., Muller, M.E., and Rezucha, I. (1962): ["Development of sampling plans by using sequential (item by item)
selection techniques and digital computers"](http://www.jstor.org/stable/2281647), JASA, 57(298):387-402, DOI: 10.2307/2281647.

### See also
[%ds_sample](@ref sas_ds_sample),
[SURVEYSELECT](https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#surveyselect_toc.htm).
