library(sqldf)
library(stringr)
library(kableExtra)
options(scipen = 9999)
#NEW OVERLEAF KITCHEN SINK
# setwd("U:\\OWS\\foundation_datasets\\wsp\\wsp2020")
# path = "U:\\OWS\\foundation_datasets\\wsp\\wsp2020"

#where to find metrics files
path <- "C:\\Users\\maf95834\\Documents\\wsp2020"
#where to save files
export_path <- "C:\\Users\\maf95834\\Documents\\TEST_SINK"
setwd(export_path)
file.names <- c(dir(path, pattern ="wsp2020.mp.all.MinorBasins_RSegs.csv"),dir(path, pattern ="metrics_facility"),(dir(path, pattern ="metrics_watershed")))

file.names <- dir(path, pattern ="wsp2020.mp.all.MinorBasins_RSegs.csv")


out.file <- ""


########################################################################################################
#CREATE BLANK SECTION LATEX FILES FOR EACH BASIN
########################################################################################################

basins_list <- c('PS', 'NR', 'YP', 'TU', 'RL', 'OR', 'EL', 'ES', 'PU', 'RU', 'YM', 'JA', 'MN', 'PM', 'YL', 'BS', 'PL', 'OD', 'JU', 'JB', 'JL')
for (mb in basins_list) {
  
  print(paste("Begin",mb,"Table Generation"))
  #wRITE NEW LATEX LINE IN .TEX FILE
  cat(paste0("\\subsection{",mb,"}"),file=paste0(mb,"_section_latex.tex"),sep="\n")
  cat("",file=paste0(mb,"_section_latex.tex"),sep="\n",append=TRUE)
}
  
  
########################################################################################################
#LOOP THROUGH METRICS FILES AND BASINS TO PRINT LATEX TABLES AND SECTION .TEX FILES
########################################################################################################

  for(i in 1:length(file.names)){
  
  #READ IN SINGLE METRICS FILE
  file.path <- paste(path,"\\",file.names[i],sep="")
  
  file <- read.csv(file.path,header=TRUE, sep=",", stringsAsFactors=FALSE)
  
  if (grepl(x = file.path, pattern = "mp.all") == T) {
    #mp.all file has a different column name for minorbasin_code
    #skips rows that do not have a minorbasin/riverseg for now
    
    #EXTRACT LIST OF BASIN CODES FROM FILE
    basins <- sqldf('SELECT DISTINCT MinorBasin_Code as basins
                  FROM file
                  WHERE basins NOT LIKE ""
                  ORDER BY MinorBasin_Code DESC') 
    
  } else {
    #all other metrics files have minorbasin_code as the prefix to the riverseg column
    #skips rows that do not have a minorbasin/riverseg for now
    
    #EXTRACT LIST OF BASIN CODES FROM FILE
  basins <- sqldf('SELECT DISTINCT leftstr(riverseg,2) as basins
                  FROM file
                  WHERE basins NOT LIKE "" 
                  ORDER BY riverseg DESC') 
  }
  
  print(paste0("PROCESSING METRIC: ",file.names[i]))
  
  for (b in 1:nrow(basins)) {
    
      if (grepl(x = file.path, pattern = "mp.all") == T) {
      
        print(paste0("PROCESSING BASIN: ",basins[b,]))
        #EXTRACT BASIN
        basin_file <- sqldf(paste('SELECT *
                          FROM file
                          WHERE MinorBasin_Code LIKE "', basins[b,], '%"', sep = ''))
        
        #SAVE EACH MINOR BASIN AS CSV
        write.csv(basin_file, file = paste(export_path,"\\",basins[b,],"_", file.names[i], sep = ""), row.names = FALSE)
        #drop columns to make narrow the table width
        basin_file <- basin_file[,!(names(basin_file) %in% c("source_type","MPID", "fips_centroid","optional","optional.1", "MinorBasin_Name","MinorBasin_Code"))]
        
        #WRITE KABLE TABLE
        table_tex <- kable(basin_file,align = "l",  booktabs = T,format = "latex",
                           caption = paste(basins[b,],"\\_", gsub(pattern = "_", 
                                                                  repl    = "\\_", 
                                                                  x       = str_remove(file.names[i],'.csv'), 
                                                                  fixed = T ), sep = ""),
                           label = paste(basins[b,],"_", (str_remove(file.names[i],'.csv')), sep = "")) %>%
          kable_styling(latex_options = c("striped","scale_down")) %>%
          column_spec(2, width = "12em")%>%
          column_spec(8, width = "9em")%>%
          column_spec(10, width = "9em")%>%
          column_spec(22, width = "5em")%>%
          column_spec(29, width = "9em")
          
      } else {
      print(paste0("PROCESSING BASIN: ",basins[b,]))
        #EXTRACT BASIN
      basin_file <- sqldf(paste('SELECT *
                          FROM file
                          WHERE riverseg LIKE "', basins[b,], '%"', sep = ''))
    
      #SAVE EACH MINOR BASIN AS TABLE
      write.csv(basin_file, file = paste(export_path,"\\",basins[b,],"_", file.names[i], sep = ""), row.names = FALSE)
      #drop columns to make narrow the table width
      basin_file <- basin_file[,!(names(basin_file) %in% c("X","hydrocode"))]

      #WRITE KABLE TABLE
      table_tex <- kable(basin_file,align = "l",  booktabs = T,format = "latex",longtable =T,
                          caption = paste(basins[b,],"\\_", gsub(pattern = "_", 
                                                               repl    = "\\_", 
                                                               x       = str_remove(file.names[i],'.csv'), 
                                                               fixed = T ), sep = ""),
                          label = paste(basins[b,],"_", (str_remove(file.names[i],'.csv')), sep = "")) %>%
        kable_styling(latex_options = "striped") %>%
        column_spec(2, width = "12em")
      }
        
        table_tex <- gsub(pattern = "{table}[t]", 
                           repl    = "{table}[H]", 
                           x       = table_tex, fixed = T )
      table_tex %>%
        cat(., file = paste0(export_path,"\\",basins[b,],"_", str_remove(file.names[i],'.csv'),".tex"),sep="")


      #wRITE NEW LATEX LINE IN .TEX FILE
      cat(paste0("\\input{sections/Xtables/",basins[b,],"_", (str_remove(file.names[i],'.csv')),".tex}"),file=paste0(basins[b,],"_section_latex.tex"),sep="\n",append=TRUE)
      cat("",file=paste0(basins[b,],"_section_latex.tex"),sep="\n",append=TRUE)

    }
  }
