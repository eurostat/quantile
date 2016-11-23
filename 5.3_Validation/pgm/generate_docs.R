# Author: Mészáros Mátyás Tamás 2016 
###############################################################################

#STARTDOC
### generate_docs {#r_generate_docs}
#Extract the documentation part from the R source files and generates Markdown files and documentation in a given format.
#
#	> generate_docs(start_folder, subdir, out_format)
#
#### Arguments 
#* `start_folder` : (_option_) a string with the path to the folder where the R files containing the documentation can be found, 
#	if not provided the current working directory is used `(getwd())`;
#* `subdir` : (_option_) a boolean, if the provided folder should be searched recursively for .R files, default value is `TRUE`;
#* `out_format` : (_option_) a string with the type of output format as avaialble for the `rmarkdown()` function (_e.g._ pdf_document, 
#	html_document), it requires installed pandoc and MikTex.
#
#### Returns
# It creates in the doc folder the `.md` files from the text placed between the \#`STARTDOC` and \#`ENDDOC` part of the `.R` files.
#
#### Example
#
#	> generate_docs("Z:/main",FALSE)
#This would search for R files with file extension `.R` in the folder `Z:\main` excluding the subfolders and extracts from each file 
#the part which is placed between the \#`STARTDOC` and \#`ENDDOC` marks.
#The output files would be placed in the folder `Z:\main\doc` with the same file name as the R file with the extension `.md`; if the 
#`doc` folder does not exist, then it will be created. 
#ENDDOC

library(rmarkdown)
generate_docs<-function(start_folder,subdir,out_format) {
	if (nchar(start_folder)==0){
		start_folder=getwd()
	} else if (!file.exists(start_folder)){
		stop("Invalid directory.")
	}  
	if (missing(subdir)){
		subdir=T
	}
	if (!missing(out_format)){
		if (!grepl("pdf_document|html_document",out_format,perl=T)){
			stop("Not valid rmarkdown output_format")
		}
	}
	
	setwd(start_folder)
	file_list<-sort(dir(start_folder,pattern=".R",recursive=subdir),decreasing=F)
	
	for (i in 1:length(file_list)){
		fi <- file(paste0(start_folder,"/",file_list[i]),"rt")
		fc <- readLines(fi)
		fc <- fc[(grep("^#STARTDOC",fc,perl=T)[1]+1):(grep("^#ENDDOC",fc,perl=T)[1]-1)]
		fc <- gsub("^#","",fc,perl=T)
#		fc <- paste(fc, collapse="\n")
#		fo <- file(paste0(start_folder,"/doc/",sub(".R",".md",file_list[i],perl=T)),"wt")
#		if (isOpen(fo)) {flush(fo)}
		if (!dir.exists(paste0(start_folder,"/doc/"))) {dir.create(paste0(start_folder,"/doc/"))}
		if (file.exists(paste0(start_folder,"/doc/",sub(".R",".md",file_list[i],perl=T)))) {file.remove(paste0(start_folder,"/doc/",sub(".R",".md",file_list[i],perl=T)))}
		fo <- file(paste0(start_folder,"/doc/",sub(".R",".md",file_list[i],perl=T)),"wt")
		cat(fc, file=fo, sep="\n" )
		close(fi)
		close(fo)
		if (!missing(out_format)){
			render(paste0(start_folder,"/doc/",sub(".R",".md",file_list[i],perl=T)),out_format)
		}
		
	}
	
	
}
