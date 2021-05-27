#FORMATTING EXEMPT & GW MODELING TABLES
## EXEMPT #########################################################################################################
#TABLE 11 NON-TIDAL EXEMPT DATA SOURCES
nontidal_exempt <- read.csv(paste(folder,"table_11_non_tidal_exempt.csv",sep=""))

##KABLE
nontidal_exempt_tex <- kable(nontidal_exempt,align = c('l','c','c'),  booktabs = T, format = "latex",
                    caption = "Summary of Exempt Data Sources for Non-tidal Intakes",
                    label = "ex_nontidal",
                    col.names = c("Scenario Data Source Type",
                                  "No. of Intakes",
                                  "Total (MGD)")) %>%
  #kable_styling(latex_options = "scale_down") %>%
  kable_styling(font_size = 6) %>%
  column_spec(1, width = "12em") %>%
  column_spec(2, width = "7em") %>%
  column_spec(3, width = "7em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 6) %>%
  footnote(symbol = "Footnote goes here")

  nontidal_exempt_tex <- gsub(pattern = "401 Certification",
                   repl    =  "\\textsuperscript{*}401 Certification",
                   x       = nontidal_exempt_tex, fixed = T )
  nontidal_exempt_tex <- gsub(pattern = "VWP Permit",
                              repl    =  "\\textsuperscript{*}VWP Permit",
                              x       = nontidal_exempt_tex, fixed = T )
  nontidal_exempt_tex <- gsub(pattern = "\\multicolumn{3}{l}{\\textsuperscript{*} Footnote goes here}\\\\",
                              repl    =  "\\multicolumn{3}{l}{ \\multirow{}{}{\\parbox{7cm}{\\textsuperscript{*} These source types represent facilities permitted with either a 401 Certification or VWP Permit}}}\\\\",
                              x       = nontidal_exempt_tex, fixed = T )
  nontidal_exempt_tex <- gsub(pattern = "{table}[t]",
                              repl    =  "{table}[H]",
                              x       = nontidal_exempt_tex, fixed = T )
  nontidal_exempt_tex
  
#TABLE 12 TIDAL EXEMPT DATA SOURCES
tidal_exempt <- read.csv(paste(folder,"table_12_tidal_exempt.csv"))
##KABLE
tidal_exempt_tex <- kable(tidal_exempt,align = c('l','c','c'),  booktabs = T, format = "latex",
                             caption = "Summary of Exempt Data Sources for Tidal Intakes",
                             label = "ex_tidal",
                             col.names = c("Scenario Data Source Type",
                                           "No. of Intakes",
                                           "Total (MGD)")) %>%
  #kable_styling(latex_options = "scale_down") %>%
  kable_styling(font_size = 6) %>%
  column_spec(1, width = "12em") %>%
  column_spec(2, width = "7em") %>%
  column_spec(3, width = "7em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 6) %>%
  footnote(symbol = "Footnote goes here")

tidal_exempt_tex <- gsub(pattern = "401 Certification",
                            repl    =  "\\textsuperscript{*}401 Certification",
                            x       = tidal_exempt_tex, fixed = T )
tidal_exempt_tex <- gsub(pattern = "VWP Permit",
                            repl    =  "\\textsuperscript{*}VWP Permit",
                            x       = tidal_exempt_tex, fixed = T )
tidal_exempt_tex <- gsub(pattern = "\\multicolumn{3}{l}{\\textsuperscript{*} Footnote goes here}\\\\",
                            repl    =  "\\multicolumn{3}{l}{ \\multirow{}{}{\\parbox{7cm}{\\textsuperscript{*} These source types represent facilities permitted with either a 401 Certification or VWP Permit}}}\\\\",
                            x       = tidal_exempt_tex, fixed = T )
tidal_exempt_tex <- gsub(pattern = "{table}[t]",
                            repl    =  "{table}[H]",
                            x       = tidal_exempt_tex, fixed = T )
tidal_exempt_tex

## GW MODELING ######################################################################################

#FIG 48 Eastern Virginia GW Modeling

EV_GW <- read.csv(paste(folder,"table_fig48_VAHydro_EV_GW_model_scenarios.csv"))

##KABLE
EV_GW_tex <- kable(EV_GW,align = c('l','c','c','c','c'),  booktabs = T, format = "latex",
                             caption = "VAHydro Virginia Coastal Plain Model Scenarios Pumping Rates (MGD)",
                             label = "VA_EV_GW_model_scenarios",
                   col.names = c("Scenario",
                                 "Permitted Demands",
                                 "Domestic Estimates",
                                 "Injection Amount",
                                 "Total Pumping")) %>%
  kable_styling(latex_options = "scale_down") %>%
  kable_styling(font_size = 11) %>%
  # column_spec(1, width = "12em") %>%
  # column_spec(2, width = "7em") %>%
  # column_spec(3, width = "7em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 11)
  
EV_GW_tex <- gsub(pattern = "{table}[t]",
                            repl    =  "{table}[H]",
                            x       = EV_GW_tex, fixed = T )
EV_GW_tex

#FIG 49 Eastern Shore GW Modeling

ES_GW <- read.csv(paste(folder,"table_fig49_VAHydro_ES_GW_model_scenarios.csv"))
##KABLE
ES_GW_tex <- kable(ES_GW,align = c('l','c','c','c','c'),  booktabs = T, format = "latex",
                   caption = "VAHydro Virginia Eastern Shore Model Scenarios Pumping Rates (MGD)",
                   label = "VA_ES_GW_model_scenarios",
                   col.names = c("Scenario",
                                 "Permitted Demands",
                                 "Domestic Estimates",
                                 "Total Pumping")) %>%
  #kable_styling(latex_options = "scale_down") %>%
  kable_styling(font_size = 11) %>%
  # column_spec(1, width = "12em") %>%
  # column_spec(2, width = "7em") %>%
  # column_spec(3, width = "7em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 11)

ES_GW_tex <- gsub(pattern = "{table}[t]",
                  repl    =  "{table}[H]",
                  x       = ES_GW_tex, fixed = T )
ES_GW_tex

