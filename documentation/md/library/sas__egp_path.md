## _egp_path {#sas__egp_path}
This macro retrieves either the name of the client SAS EG project (without its extension) 
it is launched in or the path of where it is located.

	%let p=%_egp_path(path=base, dashreplace=no, parent=no);
  
### Arguments
* `path` : (_option_) flag set to `base/path/drive` when respectively the 
 	project's name/path/drive path shall be returned; default: `path=path`, _i.e._ the 
	path of the current project directory is returned;
* `dashreplace` : (_option_) boolean flag set to `yes` when the `-` in the path needs
	to be trimmed (_i.e._, replaced with a blank); this is used only when `path=base`, 	
	_e.g._ to produce automatically tables whose names are derived from the program used 
	to generate them; default to `no`;
* `parent` : (_option_) boolean flag set to yes when the path of the parent directory of
	the current project shall be returned; this is used only when `path=path` or `drive`; 
	default to `no`.

### Returns
`p` : depending on `path` value:
	+ the name of the current project (the one the command is launched in), without its 
		`egp` extension,
	+ the path or full path,
	+ the path of the parent directory.

### Examples
Imagine the name of the program running this function is `test-01.egp` and is located in 
the directory `Z:\main\test`, then:

	%let p=%_egp_path(path=base);

returns: `p=test-01`.

	%let p=%_egp_path(path=base, dashreplace=yes);

returns: `p=test01`.

	%let p=%_egp_path(path=path); 

returns: `p=Z:/main/test`

	%let p=%_egp_path(path=drive); 
	
returns: `p=/main/test`.

	%let p=%_egp_path(path=path, parent=yes); 
	
returns: `p=Z:/main`.

Run macro `%%_example__egp_path` for examples.

### Notes
1. This macro works only with SAS ENTERPRISE GUIDE since it uses the predefined macro variables 
`_CLIENTPROJECTNAME` and `_CLIENTPROJECTPATH`.
2. Note that whether you are running in local or not (_e.g._, `SASMain`), the path returned with 
option `path=base` or (drive)path is always formatted as a local path, hence there is no 
difference.

### References
Hemedinger, C.: [Special automatic macro variables available in SAS Enterprise Guide](http://blogs.sas.com/content/sasdummy/2012/10/09/special-macro-vars-in-eg).

### See also
[%_egp_prompt](@ref sas__egp_prompt).
