## R {#r_quantile_assign}
[//]: # (Divide a given sample, possibly weighted, into a certain number of slices of equal size, with units ranked according to a variable of interest.)

    > quantile_assign(data = NULL, x, w = NULL, s, name_s = NULL)

### Arguments
* `data`: (_option_) the name of the dataframe;
* `x`: numeric vector representing the variable of interest (_e.g._ income or wealth);
* `s`: number of slices;
* `w`: (_option_) the weights (in case of a survey for instance); it has to be a numeric vector; default: `w=1`;
* `name_s`: (_option_) name of the output variable in the data frame `data`; default is `name_s=var`_s.

### Returns
* If `x` is a vector, a vector of same lenght containing for each unit `i` the number associated to the slice.
* If `x` is a variable of the data frame `data`, the data frame including a variable named `name_s` containing 
for each unit `i` the number associated to the slice.

### Examples

Run function `> _example_quantile_assign` for examples.

### See also
[SAS version](@ref sas_quantile_assign).


