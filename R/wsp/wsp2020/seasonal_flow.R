
usgs_por_mo <- c(11400,	14200,	19300,	16400,	12900,	8230,	4500,	4210,	4220,	5040,	5940,	9010)


names(usgs_por_mo) <- month.abb
barplot(usgs_por_mo)
por_win <- mean(usgs_por_mo[c('Jan', 'Feb', 'Mar')])
por_not_win <- mean(usgs_por_mo[c('Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')])
por_first4 <- mean(usgs_por_mo[c('Jan', 'Feb', 'Mar', 'Apr')])
por_last8 <- mean(usgs_por_mo[c('May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')])

pie(
  c(por_win, por_not_win), 
  labels = c('January-March', 'April-December'),
  main='Total Potomac River Flow In Winter/Non-Winter'
)

pie(
  c(por_first4, por_last8), 
  labels = c('January-April', 'May-December'),
  main='Total Potomac River Flow In Winter/Non-Winter'
)

library("ggplot2")

df <- data.frame(
  group = c('January-March','April-December'),
  value = c(por_win, por_not_win )
)

bp<- ggplot(df, aes(x="", y=value, fill=group))+
  geom_bar(width = 1, stat = "identity")
bp
pie <- bp + coord_polar("y", start=0)
pie
pie + scale_fill_brewer(palette="Blues")+
  theme_minimal()
pie + labs(
  title = 'Potomac River Flow',
  subtitle = 'Winter vs. Non-Winter Months',
  x = 'Sum of Monthly Flow (cfs)'
)
pie + scale_fill_brewer(palette="Blues")+
  theme_minimal()


# 
usgs_por_mos <- data.frame(
  month = month.abb,
  cfs_mean = c(11400,	14200,	19300,	16400,	12900,	8230,	4500,	4210,	4220,	5040,	5940,	9010),
  group = c('January-March', 'January-March', 'January-March', 'April-December', 'April-December', 'April-December', 'April-December', 'April-December', 'April-December', 'April-December', 'April-December', 'April-December'),
  modays = c(31,28.25,31,30,31,30,31,31,30,31,30,31)
) 
usgs_por_mos$mg <- usgs_por_mos$cfs_mean * usgs_por_mos$modays / 1.547

bp<- ggplot(usgs_por_mos, aes(x="", y=mg, fill=group))+
  geom_bar(width = 1, stat = "identity")
bp
pie <- bp + coord_polar("y", start=0)
pie
pie + scale_fill_brewer(palette="Blues")+
  theme_minimal()
pie + labs(
  title = 'Potomac River Flow',
  subtitle = 'Winter vs. Non-Winter Months',
  x = 'Sum of Monthly Flow (cfs)'
)
pie + scale_fill_brewer(palette="Blues")+
  theme_minimal()
