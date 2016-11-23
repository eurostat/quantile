## generate_docs {#r_generate_docs}
Extract the documentation part from the R source files and generates Markdown files and documentation in a given format.

	> generate_docs(start_folder, subdir, out_format)

### Arguments 
* `start_folder` : (_option_) a string with the path to the folder where the R files containing the documentation can be found, 
	if not provided the current working directory is used `(getwd())`;
* `subdir` : (_option_) a boolean, if the provided folder should be searched recursively for .R files, default value is `TRUE`;
* `out_format` : (_option_) a string with the type of output format as avaialble for the `rmarkdown()` function (_e.g._ pdf_document, 
	html_document), it requires installed pandoc and MikTex.

### Returns
 It creates in the doc folder the `.md` files from the text placed between the \#`STARTDOC` and \#`ENDDOC` part of the `.R` files.

### Example

	> generate_docs("Z:/main",FALSE)
This would search for R files with file extension `.R` in the folder `Z:\main` excluding the subfolders and extracts from each file 
the part which is placed between the \#`STARTDOC` and \#`ENDDOC` marks.
The output files would be placed in the folder `Z:\main\doc` with the same file name as the R file with the extension `.md`; if the 
`doc` folder does not exist, then it will be created. 
