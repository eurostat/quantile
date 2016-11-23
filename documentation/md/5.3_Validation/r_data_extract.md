## data_extract {#r_data_extract}
Extract data from pdb files.

    > data_extract(year, ctry, start_folder, out_format)

### Arguments 
* `year` : the number of years after 2000;
* `ctry` : a list of characters with the two letter country codes to extract;
* `start_folder` : (_option_) a string with the path to the folder where the pdb files are, if not provided the current working directory is used `(getwd())`; the folders should be divided by the "/" character and should end with "/" character.;
* `out_format` : (_option_) character `_c_`, `_l_`, or `_r_` what type of data shall be in the output data frame; it takes the value `_r_` if it is missing.

### Returns
 It provides a list of 4 data frames containing the data from the `d`, `h`, `p`, and `r` SAS data files.

### Examples

    > data_extract(14,c("AT","DE","EL"),"z:/pdb/","r")
    > data_extract(9,c("AT","DE","EL","CH","UK"),"y:/pdb/","c")
