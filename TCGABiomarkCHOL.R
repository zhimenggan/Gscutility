##########################################################################################################################
###################################### Introduction and Usage  #########################################################
##########################################################################################################################

# this code is for differential methylation region detection
# Oct/17/2016

##########################################################################################################################
###################################### Function and Package Load #########################################################
##########################################################################################################################

PairTtestPValue<-function(data,x1,x2,pair=FALSE){
  data<-data.matrix(data)
  output<-matrix(NA,dim(data)[1],6)   # set output matrix ()
  for(i in 1:dim(data)[1]){
    out<-data.frame()
    if(pair==TRUE){
      Valid<-nrow(na.omit(data.frame(data[i,x1],data[i,x2])))
    }else{
      Valid<-100
    }
    if( sum(!is.na(data[i,x1]))>=3 & sum(!is.na(data[i,x2]))>=3 & Valid>3){ 
      tmp1<-try(t.test((data[i,x1]),(data[i,x2]),paired=pair, na.action=na.omit))
      output[i,1]<-format(tmp1$p.value, scientific=TRUE)
      output[i,2]<-round(mean((data[i,x1]))-mean((data[i,x2])),3)
      output[i,3]<-round(mean((data[i,x1])),3)
      output[i,4]<-round(mean((data[i,x2])),3)
      output[i,5]<-round(sd(data[i,x1]),3)
      output[i,6]<-round(sd(data[i,x2]),3)
      print(i)
    }
  }
  rownames(output)<-rownames(data)
  output
}


##########################################################################################################################
###################################### Working Pipeline ##################################################################
##########################################################################################################################

setwd(getwd())
system("gdc-client download -m gdc_manifest.2016-10-17T22-20-50.162580-ESCA.tsv")
system("mv ./*/*.txt ./")

library("stringr")
file<-list.files(pattern="jhu*")
data<-c()
for(i in file){
  tmp<-read.table(i,head=T,skip=1,row.names=1,sep="\t",check.names = FALSE,as.is=T)
  data<-cbind(data,tmp[,1])
  print(i)
}

#load("PancancerMethMatrix_March2016.RData")
#load("PancancerMethMatrix_March2016.Test.RData")
# colnames(data)<-unlist(lapply(colnames(data),function(x) gsub("[.]","-",x)))
rownames(data)<-rownames(tmp)
idv<-unique(as.array(str_extract(file,"TCGA-[0-9|a-z|A-Z]*-[0-9|a-z|A-Z]*-[0-9]*")))
colnames(data)<-idv
cancertype<-unique(unlist(lapply(file,function(x) unlist(strsplit(x,"_|.Human"))[2])))
save(data,file=paste(cancertype,"meth.RData",sep="."))

CANCER<-c()
sta<-c()
result<-c()
P<-c()

# Identify Paired Tumor-Adjacent Samples(01/11) 
pairidv<-c()
for (i in 1:length(idv)){
  t1<-paste(idv[i],"-01",sep="") 
  t2<-paste(idv[i],"-11",sep="")
  if(all(any(grepl(t1,file)),any(grepl(t2,file)))){
    pairidv<-c(pairidv,t1,t2)
  }
}

# Pair-wise DMS test
if(length(pairidv)>3){
  newdata<-data[,match(pairidv,colnames(data))]
  newdata<-newdata+matrix(rnorm(nrow(newdata)*ncol(newdata),0.0001,0.0001),dim(newdata)[1],dim(newdata)[2])   # row=gene, col=inv
  type<-substr(colnames(newdata),14,15)
  x1<-which(type==names(table(type))[1])   # type 1, cancer or sensitive
  x2<-which(type==names(table(type))[2])   # type 2, normal or resistant
  Rlt1<-PairTtestPValue(newdata,x1,x2,pair=TRUE)
}

# non-pair-wise DMS test
  newdata<-data+matrix(rnorm(nrow(data)*ncol(data),0.0001,0.0001),dim(data)[1],dim(data)[2])   # row=gene, col=inv
  type<-substr(colnames(data),14,15)
#  x1<-which(type==names(table(type))[1])   # type 1, cancer or sensitive (not stable since 06,09 will be existed in filename)
#  x2<-which(type==names(table(type))[2])   # type 2, normal or resistant (not stable since 06,09 will be existed in filename)
  x1<-which(type=="01")   # type 1, cancer or sensitive
  x2<-which(type=="11")   # type 2, normal or resistant
  Rlt2<-PairTtestPValue(newdata,x1,x2,pair=F)
  
# merge two result  
  FDRPair<-p.adjust(Rlt1[,1],method="fdr")
  FDRSingle<-p.adjust(Rlt2[,1],method="fdr")
  Rlt<-data.frame(Rlt1,format(FDRPair, scientific=TRUE),Rlt2,format(FDRSingle, scientific=TRUE))
  colnames(Rlt)<-paste(c("Pvalue","Statistic","mean1","mean2","SD1","SD2","FDR"),rep(c("pair","single"),each=7),sep=".")
  rownames(Rlt)<-rownames(Rlt1)
  Rlt<-data.frame(sapply(Rlt,function(x) as.numeric(as.character(x))))
  rownames(Rlt)<-rownames(Rlt1)
  RRlt<-subset(Rlt,Pvalue.pair<10^-4 & Pvalue.single<10^-4 & Statistic.pair>0.15)
  # remove PBMC hypermethylated regions
  pbmc<-read.table("/media/NAS3_volume2/shg047/HM450/TCGA/Normal.PBMC.GEO.HM450K.Beta.txt",sep="\t",row.names=1,head=T,check.names=F)
  PBMC<-pbmc[match(rownames(RRlt),rownames(pbmc)),]
  PBMCSubset<-subset(PBMC,mean<0.15 & median<0.15)
  dim(PBMCSubset)
  target<-RRlt[match(rownames(PBMCSubset),rownames(RRlt)),]
##########################################################################################################################
###################################### Annotation and Plot################################################################
##########################################################################################################################
# Annotation 
  hm450anno<-read.table("/media/Home_Raid1/shg047/NAS3/HM450/TCGA/GPL13534.map")
  result<-data.frame(target,hm450anno[match(rownames(target),hm450anno[,4]),])
  outputfile=paste("TCGA-",cancertype,".DMS.txt",sep="")
  write.table(result,file=outputfile,col.names=T,row.names=F,sep="\t",quote=F)
  
