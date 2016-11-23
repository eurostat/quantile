# Author: Mészáros Mátyás Tamás 2016 
###############################################################################

#STARTDOC
### data_extract {#r_data_extract}
#Extract data from pdb files.
#
#    > data_extract(year, ctry, start_folder, out_format)
#
#### Arguments 
#* `year` : the number of years after 2000;
#* `ctry` : a list of characters with the two letter country codes to extract;
#* `start_folder` : (_option_) a string with the path to the folder where the pdb files are, if not provided the current working directory is used `(getwd())`; the folders should be divided by the "/" character and should end with "/" character.;
#* `out_format` : (_option_) character `_c_`, `_l_`, or `_r_` what type of data shall be in the output data frame; it takes the value `_r_` if it is missing.
#
#### Returns
# It provides a list of 4 data frames containing the data from the `d`, `h`, `p`, and `r` SAS data files.
#
#### Examples
#
#    > data_extract(14,c("AT","DE","EL"),"z:/pdb/","r")
#    > data_extract(9,c("AT","DE","EL","CH","UK"),"y:/pdb/","c")
#ENDDOC


library(data.table)
library(haven)
#year<-14
#ctry<-c("AT","BE","EL","CH", "UK")
#start_folder<-"y:/pdb/"

		
data_extract<-function(year, ctry, start_folder, out_format){
	if (year<10) {year2d<-paste0("0",year)}else{year2d<-year} 
	if (missing(out_format)){out_format<-"r"}
	if ("UK" %in% ctry & out_format=="r"){stop("For UK it is impossible to generate reconciled file, because the cross-sectional and longitudinal sample have diffrent sources. Call the function without the UK.")}
	if (nchar(start_folder)==0){
		start_folder<-getwd()
	} else if (!file.exists(substr(start_folder,1,nchar(start_folder)-1))){
		stop("Invalid directory.")
	}  

	if (out_format=="r"){
		if (file.exists(paste0(start_folder,"r",year,"d.sas7bdat"))) { #check if pdb file exist in the folder
			dfile<-paste0(start_folder,"r",year2d,"d.sas7bdat")
			hfile<-paste0(start_folder,"r",year2d,"h.sas7bdat")
			pfile<-paste0(start_folder,"r",year2d,"p.sas7bdat")
			rfile<-paste0(start_folder,"r",year2d,"r.sas7bdat")
			# open d file and filter out countries
			dadatr<-read_sas(dfile)
			dadatr<-dadatr[dadatr$DB020 %in% ctry,]
			dbin<-gc()
			cnobs<-aggregate(dadatr[dadatr$DB010==2000+year,1]~dadatr$DB020[dadatr$DB010==2000+year],FUN=length)
			setnames(cnobs,c("ctry","nobs"))
			# check if the r file contains only l data
			if (file.exists(paste0(start_folder,"c",year2d,"d.sas7bdat"))){
				dfilec<-paste0(start_folder,"c",year2d,"d.sas7bdat")
				dadatc<-read_sas(dfilec)
				dadatc<-dadatc[,grepl("D.*",colnames(dadatc),perl=T)]
				dadatc<-dadatc[dadatc$DB020 %in% ctry,]
				cnobs2<-aggregate(dadatc[,1]~dadatc$DB020,FUN=length)
				rm(dadatc)
				setnames(cnobs2,c("ctry","nobs2"))
				cnobs_all<-merge(cnobs,cnobs2,by="ctry",all.x=T)
				fctry<-setdiff(ctry,cnobs_all$ctry[cnobs_all$nobs!=cnobs_all$nobs2])
				dadatr<-dadatr[dadatr$DB020 %in% fctry,]
				dbin<-gc()
			}	
			ctry_done<-unique(dadatr$DB020)
			if (length(ctry_done)<length(ctry)){ # check if all country are in the pdb file
				msng_ctry<-sort(setdiff(ctry,ctry_done))
				cat("For the following countries there is no or partial (only longitudinal) data in the reconciled file:",msng_ctry,"\n")	
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled h-file\n")
			hadatr<-read_sas(hfile)
			hadatr<-hadatr[hadatr$HB020 %in% fctry,]
			dbin<-gc()
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled p-file\n")
			padatr<-read_sas(pfile)
			padatr<-padatr[padatr$PB020 %in% fctry,]
			dbin<-gc()
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled r-file\n")
			radatr<-read_sas(rfile)
			radatr<-radatr[radatr$RB020 %in% fctry,]
			dbin<-gc()
			cat("The output reconciled data extracted for the following countries:",fctry,"\n")
			return(list(ddata=dadatr,hdata=hadatr,pdata=padatr,rdata=radatr))
			
			
		} else {stop(paste("There is no reconciled file for",2000+year,"in",start_folder,"!"))}
	} else if (out_format=="c"){
		if (file.exists(paste0(start_folder,"r",year2d,"d.sas7bdat"))) { #check if pdb file exist in the folder
			dfile<-paste0(start_folder,"r",year2d,"d.sas7bdat")
			hfile<-paste0(start_folder,"r",year2d,"h.sas7bdat")
			pfile<-paste0(start_folder,"r",year2d,"p.sas7bdat")
			rfile<-paste0(start_folder,"r",year2d,"r.sas7bdat")
			# open d file and filter out countries
			dadatr<-read_sas(dfile)
			dadatr<-dadatr[dadatr$DB020 %in% ctry,]
			dbin<-gc()
			cnobs<-aggregate(dadatr[dadatr$DB010==2000+year,1]~dadatr$DB020[dadatr$DB010==2000+year],FUN=length)
			setnames(cnobs,c("ctry","nobs"))
			# check if the r file contains only l data
			fctry<-unique(dadatr$DB020)
			if (file.exists(paste0(start_folder,"c",year2d,"d.sas7bdat"))){
				dfilec<-paste0(start_folder,"c",year2d,"d.sas7bdat")
				dadatc<-read_sas(dfilec)
				dadatc<-dadatc[,grepl("D.*",colnames(dadatc),perl=T)]
				dadatc<-dadatc[dadatc$DB020 %in% ctry,]
				cnobs2<-aggregate(dadatc[,1]~dadatc$DB020,FUN=length)
				setnames(cnobs2,c("ctry","nobs2"))
				cnobs_all<-merge(cnobs,cnobs2,by="ctry",all.x=T)
				fctry<-setdiff(ctry,cnobs_all$ctry[cnobs_all$nobs!=cnobs_all$nobs2])
				dadatr<-dadatr[dadatr$DB020 %in% fctry & dadatr$DB010==2000+year,]
				dbin<-gc()
				fctryc<-setdiff(ctry,unique(dadatr$DB020)) # check for the remaining countries in the c file
				dadatc<-dadatc[dadatc$DB020 %in% fctryc,]
				rcol<-colnames(dadatr) #check if the r files and the c files have the same number of columns, if not synchronize by inputing NA
				ccol<-colnames(dadatc)
				if (length(setdiff(ccol,rcol))>0) {dadatr[,setdiff(ccol,rcol)]<-NA}
				if (length(setdiff(rcol,ccol))>0) {dadatc[,setdiff(rcol,ccol)]<-NA}
				dadatc<-rbind(dadatr,dadatc)
				rm(dadatr)
				dbin<-gc()
			} else {
				dadatc<-dadatr
				rm(dadatr)
				dbin<-gc()
			}
			if (exists("fctryc")) {
				if (length(fctryc)>0){rdc=T}else{rdc=F}
			} else {rdc=F}
			ctry_done<-unique(dadatc$DB020)
			if (length(ctry_done)<length(ctry)){ # check if all country are in the pdb file
				msng_ctry<-sort(setdiff(ctry,ctry_done))
				cat("For the follwoing countries there is no or partial (only longitudinal) data in the reconciled and cross-sectional files:",msng_ctry,"\n")	
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled h-file\n")
			hadatr<-read_sas(hfile)
			hadatr<-hadatr[hadatr$HB020 %in% fctry & hadatr$HB010==2000+year,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional h-file\n")
				hfilec<-paste0(start_folder,"c",year2d,"h.sas7bdat")
				hadatc<-read_sas(hfilec)
				hadatc<-hadatc[,grepl("H.*",colnames(hadatc),perl=T)]
				hadatc<-hadatc[hadatc$HB020 %in% fctryc,]
				dbin<-gc()
				rcol<-colnames(hadatr) #check if the r files and the c files have the same number of columns, if not synchronize by inputing NA
				ccol<-colnames(hadatc)
				if (length(setdiff(ccol,rcol))>0) {hadatr[,setdiff(ccol,rcol)]<-NA}
				if (length(setdiff(rcol,ccol))>0) {hadatc[,setdiff(rcol,ccol)]<-NA}
				hadatc<-rbind(hadatr,hadatc)
				rm(hadatr)
				dbin<-gc()
			} else {
				hadatc<-hadatr
				rm(hadatr)
				dbin<-gc()
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled p-file\n")
			padatr<-read_sas(pfile)
			padatr<-padatr[padatr$PB020 %in% fctry & padatr$PB010==2000+year,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional p-file\n")
				pfilec<-paste0(start_folder,"c",year2d,"p.sas7bdat")
				padatc<-read_sas(pfilec)
				padatc<-padatc[,grepl("P.*",colnames(padatc),perl=T)]
				padatc<-padatc[padatc$PB020 %in% fctryc,]
				dbin<-gc()
				rcol<-colnames(padatr) #check if the r files and the c files have the same number of columns, if not synchronize by inputing NA
				ccol<-colnames(padatc)
				if (length(setdiff(ccol,rcol))>0) {padatr[,setdiff(ccol,rcol)]<-NA}
				if (length(setdiff(rcol,ccol))>0) {padatc[,setdiff(rcol,ccol)]<-NA}
				padatc<-rbind(padatr,padatc)
				rm(padatr)
				dbin<-gc()
			} else {
				padatc<-padatr
				rm(padatr)
				dbin<-gc()
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled r-file\n")
			radatr<-read_sas(rfile)
			radatr<-radatr[radatr$RB020 %in% fctry & radatr$RB010==2000+year,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional r-file\n")
				rfilec<-paste0(start_folder,"c",year2d,"r.sas7bdat")
				radatc<-read_sas(rfilec)
				radatc<-radatc[,grepl("R.*",colnames(radatc),perl=T)]
				radatc<-radatc[radatc$RB020 %in% fctryc,]
				dbin<-gc()
				rcol<-colnames(radatr) #check if the r files and the c files have the same number of columns, if not synchronize by inputing NA
				ccol<-colnames(radatc)
				if (length(setdiff(ccol,rcol))>0) {radatr[,setdiff(ccol,rcol)]<-NA}
				if (length(setdiff(rcol,ccol))>0) {radatc[,setdiff(rcol,ccol)]<-NA}
				radatc<-rbind(radatr,radatc)
				rm(radatr)
				dbin<-gc()
			} else {
				radatc<-radatr
				rm(radatr)
				dbin<-gc()
			}
			
			cat("The output cross-sectional data extracted for the following countries:",fctry,"\n")
			
			return(list(ddata=dadatc,hdata=hadatc,pdata=padatc,rdata=radatc))
		} else { #if there is no r-file for the given year
			if (file.exists(paste0(start_folder,"c",year2d,"d.sas7bdat"))){
				dfilec<-paste0(start_folder,"c",year2d,"d.sas7bdat")
				dadatc<-read_sas(dfilec)
				dadatc<-dadatc[,grepl("D.*",colnames(dadatc),perl=T)]
				dadatc<-dadatc[dadatc$DB020 %in% ctry,]
			}	
			fctryc<-unique(dadatc$DB020)
			if (length(fctryc)<length(ctry)){ # check if all country are in the pdb file
				msng_ctry<-sort(setdiff(ctry,fctryc))
				cat("For the follwoing countries there is no data in the cross-sectional files:",msng_ctry,"\n")	
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional h-file\n")
			hfilec<-paste0(start_folder,"c",year2d,"h.sas7bdat")
			hadatc<-read_sas(hfilec)
			hadatc<-hadatc[,grepl("H.*",colnames(hadatc),perl=T)]
			hadatc<-hadatc[hadatc$HB020 %in% fctryc,]
			dbin<-gc()
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional p-file\n")
			pfilec<-paste0(start_folder,"c",year2d,"p.sas7bdat")
			padatc<-read_sas(pfilec)
			padatc<-padatc[,grepl("P.*",colnames(padatc),perl=T)]
			padatc<-padatc[padatc$PB020 %in% fctryc,]
			dbin<-gc()
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional r-file\n")
			rfilec<-paste0(start_folder,"c",year2d,"r.sas7bdat")
			radatc<-read_sas(rfilec)
			radatc<-radatc[,grepl("R.*",colnames(radatc),perl=T)]
			radatc<-radatc[radatc$RB020 %in% fctryc,]
			dbin<-gc()
			cat("The output cross-sectional data extracted for the following countries:",fctryc,"\n")
			
			return(list(ddata=dadatc,hdata=hadatc,pdata=padatc,rdata=radatc))
		}
	}  else if (out_format=="l"){	
		if (file.exists(paste0(start_folder,"r",year2d,"d.sas7bdat"))) { #check if pdb file exist in the folder
			dfile<-paste0(start_folder,"r",year2d,"d.sas7bdat")
			hfile<-paste0(start_folder,"r",year2d,"h.sas7bdat")
			pfile<-paste0(start_folder,"r",year2d,"p.sas7bdat")
			rfile<-paste0(start_folder,"r",year2d,"r.sas7bdat")
			# open d file and filter out countries
			dadatr<-read_sas(dfile)
			dadatr<-dadatr[dadatr$DB020 %in% ctry,]
			dadatr<-dadatr[!(dadatr$DB110==9 & dadatr$DB010==2000+yr),]
			dbin<-gc()
			ctry_done<-unique(dadatc$DB020)
			fctry<-ctry_done
			if (length(ctry_done)<length(ctry)){ # check if all country are in the pdb file
				msng_ctry<-sort(setdiff(ctry,ctry_done))
				cat("For the follwoing countries there is no data in the reconciled files:",msng_ctry,"\n")	
			}
			if (file.exists(paste0(start_folder,"l",year2d,"d.sas7bdat")) & (length(ctry_done)<length(ctry))){
				dfilel<-paste0(start_folder,"l",year2d,"d.sas7bdat")
				dadatl<-read_sas(dfilel)
				dadatl<-dadatl[,grepl("D.*",colnames(dadatl),perl=T)]
				dadatl<-dadatl[dadatl$DB020 %in% msng_ctry,]
				ectry<-setdiff(msng_ctry,unique(dadatl$DB020))
				fctry<-c(ctry_done,ectry)
				dbin<-gc()
				rcol<-colnames(dadatr) #check if the r files and the l files have the same number of columns, if not synchronize by inputing NA
				lcol<-colnames(dadatl)
				if (length(setdiff(lcol,rcol))>0) {dadatr[,setdiff(lcol,rcol)]<-NA}
				if (length(setdiff(rcol,lcol))>0) {dadatl[,setdiff(rcol,lcol)]<-NA}
				dadatl<-rbind(dadatr,dadatl)
			}	else { 
				dadatl<-dadatr
				rm(dadatr)
				dbin<-gc()
			}
			if (exists("ectry")) {
				if (length(ectry)>0){rdc=T}else{rdc=F}
			} else {rdc=F}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled h-file\n")
			hadatr<-read_sas(hfile)
			hadatr<-hadatr[hadatr$HB020 %in% ctry & hadatr$HB030 %in% dadatl$DB030,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional h-file\n")
				hfilel<-paste0(start_folder,"l",year2d,"h.sas7bdat")
				hadatl<-read_sas(hfilel)
				hadatl<-hadatl[,grepl("H.*",colnames(hadatl),perl=T)]
				hadatl<-hadatl[hadatl$HB020 %in% ectry,]
				dbin<-gc()
				rcol<-colnames(hadatr) #check if the r files and the l files have the same number of columns, if not synchronize by inputing NA
				lcol<-colnames(hadatl)
				if (length(setdiff(lcol,rcol))>0) {hadatr[,setdiff(lcol,rcol)]<-NA}
				if (length(setdiff(rcol,lcol))>0) {hadatl[,setdiff(rcol,lcol)]<-NA}
				hadatl<-rbind(hadatr,hadatl)
				rm(hadatr)
				dbin<-gc()
			} else {
				hadatl<-hadatr
				rm(hadatr)
				dbin<-gc()
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled r-file\n")
			radatr<-read_sas(rfile)
			radatr<-radatr[radatr$RB020 %in% ctry & radatr$RB040 %in% dadatl$DB030,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional r-file\n")
				rfilel<-paste0(start_folder,"l",year2d,"r.sas7bdat")
				radatl<-read_sas(rfilel)
				radatl<-radatl[,grepl("R.*",colnames(radatl),perl=T)]
				radatl<-radatl[radatl$RB020 %in% ectry,]
				dbin<-gc()
				rcol<-colnames(radatr) #check if the r files and the l files have the same number of columns, if not synchronize by inputing NA
				lcol<-colnames(radatl)
				if (length(setdiff(lcol,rcol))>0) {radatr[,setdiff(lcol,rcol)]<-NA}
				if (length(setdiff(rcol,lcol))>0) {radatl[,setdiff(rcol,lcol)]<-NA}
				radatl<-rbind(radatr,radatl)
				rm(radatr)
				dbin<-gc()
			} else {
				radatl<-radatr
				rm(radatr)
				dbin<-gc()
			}
			cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading reconciled p-file\n")
			padatr<-read_sas(pfile)
			padatr<-padatr[padatr$PB020 %in% ctry & padatr$PB030 %in% radatl$RB030,]
			dbin<-gc()
			if (rdc){
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading cross-sectional p-file\n")
				pfilel<-paste0(start_folder,"l",year2d,"p.sas7bdat")
				padatl<-read_sas(pfilel)
				padatl<-padatl[,grepl("P.*",colnames(padatl),perl=T)]
				padatl<-padatl[padatl$PB020 %in% ectry,]
				dbin<-gc()
				rcol<-colnames(padatr) #check if the r files and the l files have the same number of columns, if not synchronize by inputing NA
				lcol<-colnames(padatl)
				if (length(setdiff(lcol,rcol))>0) {padatr[,setdiff(lcol,rcol)]<-NA}
				if (length(setdiff(rcol,lcol))>0) {padatl[,setdiff(rcol,lcol)]<-NA}
				padatl<-rbind(padatr,padatl)
				rm(padatr)
				dbin<-gc()
			} else {
				padatl<-padatr
				rm(padatr)
				dbin<-gc()
			}
			
			cat("The output longitudinal data extracted for the following countries:",fctry,"\n")
			
			return(list(ddata=dadatl,hdata=hadatl,pdata=padatl,rdata=radatl))
		} else{  #if there is no r-file for the given year
			if (file.exists(paste0(start_folder,"l",year2d,"d.sas7bdat"))){
				dfilel<-paste0(start_folder,"l",year2d,"d.sas7bdat")
				dadatl<-read_sas(dfilel)
				dadatl<-dadatl[,grepl("D.*",colnames(dadatl),perl=T)]
				dadatl<-dadatl[dadatl$DB020 %in% ctry,]
				fctry<-unique(dadatl$DB020)
				dbin<-gc()
				
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading longitudinal h-file\n")
				hfilel<-paste0(start_folder,"l",year2d,"h.sas7bdat")
				hadatl<-read_sas(hfilel)
				hadatl<-hadatl[,grepl("H.*",colnames(hadatl),perl=T)]
				hadatl<-hadatl[hadatl$HB020 %in% ctry,]
				dbin<-gc()
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading longitudinal r-file\n")
				rfilel<-paste0(start_folder,"l",year2d,"r.sas7bdat")
				radatl<-read_sas(rfilel)
				radatl<-radatl[,grepl("R.*",colnames(radatl),perl=T)]
				radatl<-radatl[radatl$RB020 %in% ctry,]
				dbin<-gc()
				cat(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),"reading longitudinal p-file\n")
				pfilel<-paste0(start_folder,"l",year2d,"p.sas7bdat")
				padatl<-read_sas(pfilel)
				padatl<-padatl[,grepl("P.*",colnames(padatl),perl=T)]
				padatl<-padatl[padatl$PB020 %in% ctry,]
				dbin<-gc()
				cat("The output longitudinal data extracted for the following countries:",fctry,"\n")
			
				return(list(ddata=dadatl,hdata=hadatl,pdata=padatl,rdata=radatl))
			}
		}
		
	} else { stop("Invalid out_format.")}
	
}
