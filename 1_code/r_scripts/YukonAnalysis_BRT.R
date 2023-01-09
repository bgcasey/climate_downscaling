library(raster)
library(dismo)
library(gbm)
library(lme4)
library(dplyr)
sens <- read.csv("G:/My Drive/CFS_droughtrefugia/Yukon_exports/2022-07-29_sample-sensitivity-Yukon.csv")
soil <- read.csv("G:/My Drive/CFS_droughtrefugia/Yukon_exports/2022-08-08_sample-soil-Yukon.csv")
topo <- read.csv("G:/My Drive/CFS_droughtrefugia/Yukon_exports/2022-08-08_sample-topo-Yukon.csv")
veg <- read.csv("G:/My Drive/CFS_droughtrefugia/Yukon_exports/2022-08-08_sample-vegetation-Yukon.csv")
hydro <- read.csv("G:/My Drive/CFS_droughtrefugia/Yukon_exports/2022-08-02_sample-hydro-Yukon.csv")
dat <- inner_join(sens[,1:10],veg[,1:6], by="system.index")
dat <- inner_join(dat,topo[,c(1,5:12,14,17)],by="system.index")
dat <- inner_join(dat,soil[,c(1:2,6:9)],by="system.index")
dat <- inner_join(dat,hydro[,c(1:3,7:9)],by="system.index")
dat$land_cover <- as.factor(dat$land_cover)
dat$landforms_alos <- as.factor(dat$landforms_alos)
dat$distance_lake_gt_50_sq_km <- ifelse(is.na(dat$distance_lake_gt_50_sq_km),100000,dat$distance_lake_gt_50_sq_km)
dat$distance_water_lc <- ifelse(is.na(dat$distance_water_lc),10000,dat$distance_water_lc)
dat <- na.omit(dat)

w <- "G:/My Drive/CFS_droughtrefugia/Yukon_exports/"

metrics <- c("nbr12", "nbr3", "nbr5", "ndvi12", "ndvi3", "ndvi5")
ecozones <- unique(dat$ecozone)
ecoregions <- unique(dat$ecoregion)

#meansense <- aggregate(sens[,c(2:7)],by=list(sens$ecoregion),FUN="mean",na.action=na.omit)

meansens <- read.csv(paste0(w,"table_ecoregion_sensitivity.csv"))

# glmm.topo.nbr12 <- lmer(Abs_sens_NBR_ante12mo_p15_p85~chili_alos+hand_90_1000+landforms_alos+MaximalCurvature+MinimalCurvature+(1|ecozone),data=dat)
# drop1(glmm.topo.nbr12)
# AIC(glmm.topo.nbr12)
# 
# glmm.topo.ndvi12 <- lmer(Abs_sens_NDVI_ante12mo_p15_p85~chili_alos+hand_90_1000+landforms_alos+MaximalCurvature+MinimalCurvature+(1|ecozone),data=dat)
# drop1(glmm.topo.ndvi12)
# AIC(glmm.topo.ndvi12)
# 
# glmm.veg.nbr12 <- lmer(Abs_sens_NBR_ante12mo_p15_p85~chili_alos+hand_90_1000+landforms_alos+MaximalCurvature+MinimalCurvature+(1|ecozone),data=dat)
# drop1(glmm.topo.nbr12)
# AIC(glmm.topo.nbr12)
# 
# glmm.veg.ndvi12 <- lmer(Abs_sens_NDVI_ante12mo_p15_p85~chili_alos+hand_90_1000+landforms_alos+MaximalCurvature+MinimalCurvature+(1|ecozone),data=dat)
# drop1(glmm.topo.ndvi12)
# AIC(glmm.topo.ndvi12)

for (i in 1:length(ecozones)){
  eco <- dat[dat$ecozone == ecozones[i],]
  full.nbr12 <- gbm.step(eco,gbm.x=11:35,gbm.y=2,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  full.nbr3 <- gbm.step(eco,gbm.x=11:35,gbm.y=3,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  full.nbr5 <- gbm.step(eco,gbm.x=11:35,gbm.y=4,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  full.ndvi12 <- gbm.step(eco,gbm.x=11:35,gbm.y=5,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  full.ndvi3 <- gbm.step(eco,gbm.x=11:35,gbm.y=6,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  full.ndvi5 <- gbm.step(eco,gbm.x=11:35,gbm.y=7,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5)
  
  save(full.nbr12,file=paste(w,"yukon_eco",ecozones[i],"_brt_nbr12.R",sep=""))
  save(full.nbr3,file=paste(w,"yukon_eco",ecozones[i],"_brt_nbr3.R",sep=""))
  save(full.nbr5,file=paste(w,"yukon_eco",ecozones[i],"_brt_nbr5.R",sep=""))
  save(full.ndvi12,file=paste(w,"yukon_eco",ecozones[i],"_brt_ndvi12.R",sep=""))
  save(full.ndvi3,file=paste(w,"yukon_eco",ecozones[i],"_brt_ndvi3.R",sep=""))
  save(full.ndvi5,file=paste(w,"yukon_eco",ecozones[i],"_brt_ndvi5.R",sep=""))
  
  pdf(paste0(w,"yukon_eco",ecozones[i],"_partial_dependence_plots.pdf"))
    gbm.plot(full.nbr12,n.plots=12,smooth=TRUE)
    gbm.plot(full.nbr3,n.plots=12,smooth=TRUE)
    gbm.plot(full.nbr5,n.plots=12,smooth=TRUE)
    gbm.plot(full.ndvi12,n.plots=12,smooth=TRUE)
    gbm.plot(full.ndvi3,n.plots=12,smooth=TRUE)
    gbm.plot(full.ndvi5,n.plots=12,smooth=TRUE)
  dev.off()
  
  varimp.nbr12 <- as.data.frame(full.nbr12$contributions)
  names(varimp.nbr12)[2] <- "nbr12"
  cvstats.nbr12 <- as.data.frame(full.nbr12$cv.statistics[c(1,3)])
  cvstats.nbr12$deviance.null <- full.nbr12$self.statistics$mean.null
  cvstats.nbr12$deviance.exp <- (cvstats.nbr12$deviance.null-cvstats.nbr12$deviance.mean)/cvstats.nbr12$deviance.null

  varimp.nbr3 <- as.data.frame(full.nbr3$contributions)
  names(varimp.nbr3)[2] <- "nbr3"
  cvstats.nbr3 <- as.data.frame(full.nbr3$cv.statistics[c(1,3)])
  cvstats.nbr3$deviance.null <- full.nbr3$self.statistics$mean.null
  cvstats.nbr3$deviance.exp <- (cvstats.nbr3$deviance.null-cvstats.nbr3$deviance.mean)/cvstats.nbr3$deviance.null
  
  varimp.nbr5 <- as.data.frame(full.nbr5$contributions)
  names(varimp.nbr5)[2] <- "nbr5"
  cvstats.nbr5 <- as.data.frame(full.nbr5$cv.statistics[c(1,3)])
  cvstats.nbr5$deviance.null <- full.nbr5$self.statistics$mean.null
  cvstats.nbr5$deviance.exp <- (cvstats.nbr5$deviance.null-cvstats.nbr5$deviance.mean)/cvstats.nbr5$deviance.null
  
  varimp.ndvi12 <- as.data.frame(full.ndvi12$contributions)
  names(varimp.ndvi12)[2] <- "ndvi12"
  cvstats.ndvi12 <- as.data.frame(full.ndvi12$cv.statistics[c(1,3)])
  cvstats.ndvi12$deviance.null <- full.ndvi12$self.statistics$mean.null
  cvstats.ndvi12$deviance.exp <- (cvstats.ndvi12$deviance.null-cvstats.ndvi12$deviance.mean)/cvstats.ndvi12$deviance.null
  
  varimp.ndvi3 <- as.data.frame(full.ndvi3$contributions)
  names(varimp.ndvi3)[2] <- "ndvi3"
  cvstats.ndvi3 <- as.data.frame(full.ndvi3$cv.statistics[c(1,3)])
  cvstats.ndvi3$deviance.null <- full.ndvi3$self.statistics$mean.null
  cvstats.ndvi3$deviance.exp <- (cvstats.ndvi3$deviance.null-cvstats.ndvi3$deviance.mean)/cvstats.ndvi3$deviance.null
  
  varimp.ndvi5 <- as.data.frame(full.ndvi5$contributions)
  names(varimp.ndvi5)[2] <- "ndvi5"
  cvstats.ndvi5 <- as.data.frame(full.ndvi5$cv.statistics[c(1,3)])
  cvstats.ndvi5$deviance.null <- full.ndvi5$self.statistics$mean.null
  cvstats.ndvi5$deviance.exp <- (cvstats.ndvi5$deviance.null-cvstats.ndvi5$deviance.mean)/cvstats.ndvi5$deviance.null
  
  cvstats.combo <- rbind(cvstats.nbr12,cvstats.nbr3,cvstats.nbr5,cvstats.ndvi12,cvstats.ndvi3,cvstats.ndvi5)
  cvstats.combo <- cbind(metrics,cvstats.combo)
  write.csv(cvstats.combo, file=paste0(w,"yukon_eco",ecozones[i],"cvstats.csv"))
  
  varimp.combo <- inner_join(varimp.nbr12,varimp.nbr3,by="var")
  varimp.combo <- inner_join(varimp.combo,varimp.nbr5,by="var")
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi12,by="var")  
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi3,by="var") 
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi5,by="var")  
  write.csv(varimp.combo, file=paste0(w,"yukon_eco",ecozones[i],"varimp.csv"))
            
 }


for (i in 1:length(ecoregions)){
  eco <- dat[dat$ecoregion == ecoregions[i],]
  full.nbr12 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=2,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5))
  try(save(full.nbr12,file=paste(w,"yukon_eco",ecoregions[i],"_brt_nbr12.R",sep="")))
  
  full.nbr3 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=3,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5))
  try(save(full.nbr3,file=paste(w,"yukon_eco",ecoregions[i],"_brt_nbr3.R",sep="")))
  
  full.nbr5 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=4,family="gaussian",tree.complexity=2,learning.rate=0.0001,bag.fraction=0.5))
  try(save(full.nbr5,file=paste(w,"yukon_eco",ecoregions[i],"_brt_nbr5.R",sep="")))
  
  full.ndvi12 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=5,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5))
  try(save(full.ndvi12,file=paste(w,"yukon_eco",ecoregions[i],"_brt_ndvi12.R",sep="")))
  
  full.ndvi3 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=6,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5))
  try(save(full.ndvi3,file=paste(w,"yukon_eco",ecoregions[i],"_brt_ndvi3.R",sep="")))
  
  full.ndvi5 <- try(gbm.step(eco,gbm.x=11:35,gbm.y=7,family="gaussian",tree.complexity=2,learning.rate=0.001,bag.fraction=0.5))
  try(save(full.ndvi5,file=paste(w,"yukon_eco",ecoregions[i],"_brt_ndvi5.R",sep="")))
  
  pdf(paste0(w,"yukon_ecor",ecoregions[i],"_partial_dependence_plots.pdf"))
  try(gbm.plot(full.nbr12,n.plots=12,smooth=TRUE))
  try(gbm.plot(full.nbr3,n.plots=12,smooth=TRUE))
  try(gbm.plot(full.nbr5,n.plots=12,smooth=TRUE))
  try(gbm.plot(full.ndvi12,n.plots=12,smooth=TRUE))
  try(gbm.plot(full.ndvi3,n.plots=12,smooth=TRUE))
  try(gbm.plot(full.ndvi5,n.plots=12,smooth=TRUE))
  dev.off()
  
  varimp.nbr12 <- try(as.data.frame(full.nbr12$contributions))
  names(varimp.nbr12)[2] <- "nbr12"
  cvstats.nbr12 <- as.data.frame(full.nbr12$cv.statistics[c(1,3)])
  cvstats.nbr12$deviance.null <- full.nbr12$self.statistics$mean.null
  cvstats.nbr12$deviance.exp <- (cvstats.nbr12$deviance.null-cvstats.nbr12$deviance.mean)/cvstats.nbr12$deviance.null
  cvstats.nbr12$metric = "nbr12"
  
  varimp.nbr3 <- try(as.data.frame(full.nbr3$contributions))
  names(varimp.nbr3)[2] <- "nbr3"
  cvstats.nbr3 <- as.data.frame(full.nbr3$cv.statistics[c(1,3)])
  cvstats.nbr3$deviance.null <- full.nbr3$self.statistics$mean.null
  cvstats.nbr3$deviance.exp <- (cvstats.nbr3$deviance.null-cvstats.nbr3$deviance.mean)/cvstats.nbr3$deviance.null
  cvstats.nbr3$metric = "nbr3"
  
  varimp.nbr5 <- try(as.data.frame(full.nbr5$contributions))
  names(varimp.nbr5)[2] <- "nbr5"
  cvstats.nbr5 <- as.data.frame(full.nbr5$cv.statistics[c(1,3)])
  cvstats.nbr5$deviance.null <- full.nbr5$self.statistics$mean.null
  cvstats.nbr5$deviance.exp <- (cvstats.nbr5$deviance.null-cvstats.nbr5$deviance.mean)/cvstats.nbr5$deviance.null
  cvstats.nbr5$metric = "nbr5"

  varimp.ndvi12 <- try(as.data.frame(full.ndvi12$contributions))
  names(varimp.ndvi12)[2] <- "ndvi12"
  cvstats.ndvi12 <- as.data.frame(full.ndvi12$cv.statistics[c(1,3)])
  cvstats.ndvi12$deviance.null <- full.ndvi12$self.statistics$mean.null
  cvstats.ndvi12$deviance.exp <- (cvstats.ndvi12$deviance.null-cvstats.ndvi12$deviance.mean)/cvstats.ndvi12$deviance.null
  cvstats.ndvi12$metric = "ndvi12"
  
  varimp.ndvi3 <- try(as.data.frame(full.ndvi3$contributions))
  names(varimp.ndvi3)[2] <- "ndvi3"
  cvstats.ndvi3 <- as.data.frame(full.ndvi3$cv.statistics[c(1,3)])
  cvstats.ndvi3$deviance.null <- full.ndvi3$self.statistics$mean.null
  cvstats.ndvi3$deviance.exp <- (cvstats.ndvi3$deviance.null-cvstats.ndvi3$deviance.mean)/cvstats.ndvi3$deviance.null
  cvstats.ndvi3$metric = "ndvi3"
  
  varimp.ndvi5 <- try(as.data.frame(full.ndvi5$contributions))
  names(varimp.ndvi5)[2] <- "ndvi5"
  cvstats.ndvi5 <- as.data.frame(full.ndvi5$cv.statistics[c(1,3)])
  cvstats.ndvi5$deviance.null <- full.ndvi5$self.statistics$mean.null
  cvstats.ndvi5$deviance.exp <- (cvstats.ndvi5$deviance.null-cvstats.ndvi5$deviance.mean)/cvstats.ndvi5$deviance.null
  cvstats.ndvi5$metric = "ndvi5" 
   
  cvstats.combo <- rbind(cvstats.nbr12,cvstats.nbr3,cvstats.nbr5,cvstats.ndvi12,cvstats.ndvi3,cvstats.ndvi5)
  write.csv(cvstats.combo, file=paste0(w,"yukon_ecor",ecoregions[i],"cvstats.csv"))
  
  varimp.combo <- inner_join(varimp.nbr12,varimp.nbr3,by="var")
  try(varimp.combo <- inner_join(varimp.combo,varimp.nbr5,by="var"))
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi12,by="var")  
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi3,by="var") 
  varimp.combo <- inner_join(varimp.combo,varimp.ndvi5,by="var")  
  write.csv(varimp.combo, file=paste0(w,"yukon_ecor",ecoregions[i],"varimp.csv"))
  
}

for (i in 1:length(ecoregions)){
  cvstats <- try(read.csv(paste0(w,"yukon_ecor",ecoregions[i],"cvstats.csv")))
  maxdev <- try(max(cvstats$deviance.exp))
  maxval <- try(max(cvstats$correlation.mean))
  maxmetric <- which.max(cvstats$correlation.mean)
  maxdevmet <- which.max(cvstats$deviance.exp)
  meansens$maxval[i] <- maxval
  meansens$maxdev[i] <- maxdev
  meansens$maxmetric[i] <- cvstats$metric[maxmetric]
  meansens$maxdevmet[i] <- cvstats$metric[maxdevmet]
}
write.csv(meansens,file=paste0(w,"Yukon_ecoregion_compare.csv"))

varimp <- read.csv(paste0(w,"yukon_ecor",ecoregions[1],"varimp.csv"))
for (i in 2:length(ecoregions)) {
  varimp1 <- read.csv(paste0(w,"yukon_ecor",ecoregions[i],"varimp.csv"))
  varimp <- rbind(varimp,varimp1)
}
varimpsum <- aggregate(varimp[,3:8],by=list(varimp$var),FUN="sum")
write.csv(varimpsum,file=paste0(w,"yukon_varimpsum.csv"))
