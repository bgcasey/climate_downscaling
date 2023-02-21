m1<-lm(Tmax_diff~tpi_50, data=data_full)
m2<-lm(Tmax_diff~tpi_100, data=data_full)
m3<-lm(Tmax_diff~tpi_300, data=data_full)
m4<-lm(Tmax_diff~tpi_500, data=data_full)
m5<-lm(Tmax_diff~tpi_1000, data=data_full)


df<-data_full
df1<-df%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_100, tpi_300, tpi_500, tpi_1000)%>%
  na.omit()

tpi_gbm <- gbm.step(data=df1, gbm.x = c(2:6), gbm.y = 1,
                                 family = "gaussian", tree.complexity = 1,  n.minobsinnode = 20,
                                 learning.rate = 0.001, bag.fraction = 0.75, max.trees = 50000)





summary(brt_meanTemp_tuned_2) 

cor(data_full$tpi_50, data_full$tpi_500)


m1<-lmer(Tmax_diff ~ 1 + 1|season_2, data=data_full)
m2<-lm(Tmax_diff~season_4, data=data_full)

m1<-lme4::lmer(Tmax_diff ~ 1 + (1|season_2), data=data_full, na.action = na.exclude)
m2<-lme4::lmer(Tmax_diff ~ 1 + (1|season_4), data=data_full, na.action = na.exclude)
m3<-lme4::lmer(Tmax_diff ~ 1 + (1|Month), data=data_full, na.action = na.exclude)

anova(m1, m2, m3)

## season 4 is better
