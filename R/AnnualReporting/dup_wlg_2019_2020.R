library(sqldf)

dup_wlg_2019_2020 <- read.csv("C:/Users/maf95834/Downloads/dup_wlg_2019-2020.csv", header = TRUE)
dup_wlg <- sqldf("SELECT distinct a_featureid, a_tsvalue, b_tsvalue, to_timestamp
                 FROM dup_wlg_2019_2020
                 ORDER BY a_featureid")
sqldf("SELECT distinct a_featureid
                 FROM dup_wlg_2019_2020
                 ")
