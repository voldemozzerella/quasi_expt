
library(foreign)

demo <- read.xport("DEMO_D.xpt")

#names(demo)


## Choose Age: RIDAGEYR, Gender: RIAGENDR, Race: RIDRETH1
##		Proverty, Income Ratio: INDFMPIR

demo_vars <- c("SEQN", "RIDAGEYR", "RIAGENDR", "RIDRETH1", "DMDEDUC2") #"INDFMPIR", 

demo <- demo[,demo_vars]

names(demo)
colnames(demo) <- c("SEQN", "Age", "Sex", "Race", "Edu")	#"PIR", 


### Smoking data
sm <- read.xport("SMQ_D.xpt")  ## 12 years and over

## Choose	SMQ020: - Smoked at least 100 cigarettes in life (2==no)
##	  	SMQ040: - Do you now smoke cigarettes (1 for SMQ020, and 1 == everyday)
##		SMD070: - # cigarettes smoked per day now

sm_vars <- c("SEQN", "SMQ020", "SMQ040", "SMD070")

sm <- sm[,sm_vars]

## Cotinine and homocystine data
cot <- read.xport("COT_D.xpt")
names(cot) <- c("SEQN", "Cot")

hcy <- read.xport("hcy_D.xpt")
names(hcy) <- c("SEQN", "Hcy")


library(plyr)

## a sanity check 
nrow(demo[demo$Age>=20,])
sum(!is.na(sm$SMQ020))
#nrow(cot)



## Join all data into one data frame
data <- join(demo, sm) 

data <- join(data, cot)

data <- join(data, hcy)

rownames(data) <- data$SEQN

colnames(data)

## code smoking and non-smoking
data$smoker <- (data$SMQ020==1) & (data$SMQ040==1)	## Not allowing for 'some days', 'refused' or 'not at all'
data$nonsmoker <- (data$SMQ020==2)		## Not allowing for refused ot don't know


nrow(data)
nrow(data[data$Age>=20,])
nrow(data[data$Age>=20 & (data$smoker | data$nonsmoker),])
nrow(data[data$Age>=20 & (data$smoker | data$nonsmoker) & (!is.na(data$Cot)) & (!is.na(data$Hcy)), ])


#nrow(data)
#nrow(data[data$SEQN %in% sm$SEQN[!is.na(sm$SMQ020)],])
#nrow(data[(data$SEQN %in% sm$SEQN[!is.na(sm$SMQ020)]) & (data$smoker | data$nonsmoker),])
#nrow(data[(data$SEQN %in% sm$SEQN[!is.na(sm$SMQ020)]) & (data$smoker | data$nonsmoker) & (!is.na(data$Cot)) & (!is.na(data$Hcy)), ])



### Subseted data
## Selection criterion: Are>=20, smoker or nonsmoker and smoking status info not missing, cotinine and homocysteine level not missing
data_screened <- data; nrow(data_screened)
data_screened <- data_screened[(data_screened$Age >= 20),]; nrow(data_screened)
data_screened <- data_screened[(data_screened$smoker | data_screened$nonsmoker) & !is.na(data_screened$nonsmoker+data_screened$nonsmoker),]; nrow(data_screened)
data_screened <- data_screened[(!is.na(data_screened$Cot)) & (!is.na(data_screened$Hcy)), ]; nrow(data_screened)


## Recode treatment: 1=smoker, 2=nonsmoker
data_screened$smoking_status = 1*data_screened$smoker + 2*data_screened$nonsmoker

#### Recode covariates
##	Three covariates: Agegp, Sex, Race, Education
##		Stratify on the first two, match on the other two

## Recode Age as Agegp

data_screened$Agegp <- NA
data_screened$Agegp[data_screened$Age %in% seq(20,29, 1)] <- "20-29"
data_screened$Agegp[data_screened$Age %in% seq(30,39, 1)] <- "30-39"
data_screened$Agegp[data_screened$Age %in% seq(40,49, 1)] <- "40-49"
data_screened$Agegp[data_screened$Age %in% seq(50,59, 1)] <- "50-59"
data_screened$Agegp[data_screened$Age %in% seq(60,69, 1)] <- "60-69"
data_screened$Agegp[data_screened$Age %in% seq(70,79, 1)] <- "70-79"
data_screened$Agegp[data_screened$Age >= 80] <- "80-"

#head(data_screened$Agegp)
data_screened$Agegp <- factor(data_screened$Agegp)
#head(data_screened$Agegp)

## Recode Sex with the names "Male/Female"
data_screened$Sexn <- NA
data_screened$Sexn[data_screened$Sex==1] = "Male"
data_screened$Sexn[data_screened$Sex==2] = "Female"

#head(data_screened$Sexn)
data_screened$Sexn <- factor(data_screened$Sexn) #levels <- "Female","Male"
#head(data_screened$Sexn)


## Stratification on Agegp and Sexn
data_screened$Strata <- data_screened$Agegp:data_screened$Sexn



## Recode Race as Racegp:  Hispanic=Maxican or other hispanic, Black=non-hispanic black, white=non-hispanic white and other race
## No missing data on Race
data_screened$Racegp <- NA
data_screened$Racegp[data_screened$Race %in% c(1,2)] = 'Hispanic'
data_screened$Racegp[data_screened$Race == 4] = 'Black'
data_screened$Racegp[data_screened$Race %in% c(3,5)] = 'White.Other'

data_screened$Racegp <- factor(data_screened$Racegp, levels=c("White.Other", "Hispanic", "Black"))

## 
## No missing information on education 
## Should you remove the three people with 'Don't know' or 'Refused' response?
data_screened1 <- data_screened[data_screened$Edu <=5,]; nrow(data_screened1)

data_screened1$Edugp <- factor(data_screened1$Edu, levels=1:5, labels = c('less than ninethth', 'nineth_eleventh', 'High school_GED', 
												'Some College', 'College Grad'))


### Create the indicators of the categorical covariates Edugp and Racegp

vars <- c('Edugp', 'Racegp')

for(v in vars){
	vlevels <- levels(data_screened1[,v])

	for(vl in vlevels[-1]){			
		vlname <- gsub(" ",".", vl)
		eval( parse(text=paste0('data_screened1$',vlname,'<- data_screened1$',v,'== "',vl,'"') ))
	}
}

rm(v, vars, vl, vlevels, vlname)

names(data_screened1)
