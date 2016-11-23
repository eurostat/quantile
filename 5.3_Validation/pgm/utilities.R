# Author: Mészáros Mátyás Tamás 2016 
###############################################################################

#STARTDOC
### utilities {#r_utilities}
#Provide some tool to install the necessary packages like `haven` under R using the internet proxy access or copy the files to the common directory.   
#ENDDOC
		
usrnev <- readline(prompt="Username: ")
jlszo <- readline(prompt="Internet password: ")
setInternet2(FALSE)
Sys.setenv(http_proxy="http://psbru.ec.europa.eu:8012")
Sys.setenv(http_proxy_user=paste0(usrnev,":",jlszo))

install.packages()


trgtfldr<-"//s-isis/0eusilc/5.3_Validation"
srcfldr<-"//s-iseult/1eusilc/2.Personal_folders/Matyi/git/SILC_QR/QR"

generate_docs(srcfldr)

fajllist<-sort(dir(srcfldr,pattern=".R",recursive=F),decreasing=F)
fajllist<-gsub(".R","",fajllist)
for (i in 1:length(fajllist)){
	file.copy(paste0(srcfldr,"/",fajllist[i],".R"),paste0(trgtfldr,"/pgm/",fajllist[i],".R"),overwrite=T)
	file.copy(paste0(srcfldr,"/doc/",fajllist[i],".md"),paste0(trgtfldr,"/doc/",fajllist[i],".md"),overwrite=T)
}


#generate_docs("//s-iseult/1eusilc/2.Personal_folders/Matyi/git/SILC_QR/QR")
#generate_docs("Z:/2.Personal_folders/Matyi/git/SILC_QR/QR")
