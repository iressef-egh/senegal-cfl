#Author: Nancy Fullman
#Date: October 14, 2022
  #Updated: May 19, 2023
  #Updated: June 10, 2023
#Purpose: Senegal facility list figures and statistics

##################################
############ SET UP ##############
##################################

#Load libraries
libs <- c('tidyverse', 'RColorBrewer', 'ggplot2', 'reshape2', 'knitr', 'viridis', 'ggrepel', 'readxl', 'dplyr', 'stringi', 'leaflet', 'htmlwidgets', 'webshot', 'mapview', 'GGally', 'expss', 'leaflet', 'htmlwidgets', 'webshot', 'mapview')

for(l in libs){
  if(!require(l,character.only = TRUE, quietly = TRUE)){
    message( sprintf('Did not have the required package << %s >> installed. Downloading now ... ',l))
    install.packages(l)
  }
  library(l, character.only = TRUE, quietly = TRUE)
}

#Clear workspace
rm(list=ls())

####Setting personal component of directory -- change to whatever directory is being used if different individual
personal_direct <- "C:/Users/NancyFullman"

####Setting directory - note that the directory has been modified from the original path for privacy purposes
mfl_direct <- paste0(personal_direct,"XXXXXXX")

###################################
###Making color schemes ########
################################

#Exemplar color palette
dkblue <- "#00416b"
teal <- "#0098a7"
orange <- "#ff6400"
purple <- "#472677"
lightGrey <- 'grey90'

#Other colors
magenta <- "#c92196"
eghblue <- "#0a6bd1"
eghgreen <- "#87d45c"
eghyellow <- "#ffb634"

#Teal shades/tints
dkteal <- "#005159"
medteal <- "#4cb6c1"
ltteal <- "#99d5db"

#Orange shades/tints
dkorange <- "#cc5000"
medorange <- "#ff8332"
ltorange <- "#ffa266"

black <- "black"

###########################################
####### DATA UPLOADING AND PROCESSING #####
###########################################

fac_list <- read_excel(paste0(mfl_direct, "/senegal_consolidated_facilitylist.xlsx"))
  
fac_list_long <- read_excel(paste0(mfl_direct, "/senegal_full_facilitylist.xlsx"))

#Comparisons - note that the directory has been modified from the original path for privacy purposes
spa_frame <- read.csv(paste0(personal_direct, "/XXXXX/SEN_facilityframes_SPA.csv"))
health_maps <- read.csv(paste0(personal_direct, "/XXXXXX/SEN_facilitycounts_healthmap.csv"))
maina2019 <- read.csv(paste0(personal_direct, "/XXXXXX/mainaetal2019.csv"))

#Fixing typos in comparison data
spa_frame <- spa_frame %>%
  mutate(location_name=ifelse(location_name=="Sediou", "Sedhiou",location_name),
         location_name=ifelse(location_name=="Kaokack", "Kaolack", location_name),
         location_name=ifelse(location_name=="Saint Louis", "Saint-Louis", location_name))

health_maps <- health_maps %>%
   mutate(location_name=ifelse(location_name=="Saint Louis", "Saint-Louis", location_name))

  
maina2019 <- maina2019 %>%
        mutate(location_name=Admin1,
               location_name=ifelse(location_name=="Sediou", "Sedhiou",location_name),
               location_name=ifelse(location_name=="Kaokack", "Kaolack", location_name),
               location_name=ifelse(location_name=="Saintlouis", "Saint-Louis", location_name))
               
##Computing totals by source
fac_list_bysource <- fac_list_long %>%
      mutate(n=1) %>%
      group_by(source) %>%
      summarize(count=sum(n))

#Computing number with flags
table(fac_list$data_flagged) #n=347

##Computing % with GPS 
fac_list_long2 <- fac_list  %>%
              mutate(fac_type=group_fac_type,
                     group_lat=group_latitude,
                     group_long=group_longitude) %>%
              filter(fac_type=="hopital" | fac_type=="centre de sante" | fac_type=="poste de sante" | fac_type=="case de sante") %>%
              dplyr::select(match_id, match_name, group_lat, group_long, region, fac_type) %>%
              mutate(gps=ifelse(!is.na(group_lat) & !is.na(group_long),1,0),
                     n=1) %>%
              group_by(match_id, match_name, region, fac_type,n) %>%
                  summarize(gps=max(gps)) %>%
              ungroup() %>%
              data.frame()

#Nationally - all facility types
fac_list_nat <- fac_list_long2 %>%
  dplyr::select(n, gps) %>%
  summarize(total_fac=sum(n),
            total_gps=sum(gps)) %>%
  mutate(pct_gps=(total_gps/total_fac)*100,
         region="All",
         fac_type="All") %>%
  dplyr::select(region, fac_type, total_fac, total_gps, pct_gps)


#Nationally - by facility type
fac_list_nat_factype <- fac_list_long2 %>%
            group_by(fac_type) %>%
  summarize(total_fac=sum(n),
            total_gps=sum(gps)) %>%
  ungroup() %>%
  mutate(pct_gps=(total_gps/total_fac)*100,
         region="All") %>%
  dplyr::select(region, fac_type, total_fac, total_gps, pct_gps)


#Regionally
fac_list_region <- fac_list_long2 %>%
                    group_by(region) %>%
                    summarize(total_fac=sum(n),
                              total_gps=sum(gps)) %>%
                    ungroup() %>%
                    mutate(pct_gps=(total_gps/total_fac)*100,
                           fac_type="All") %>%
  dplyr::select(region, fac_type, total_fac, total_gps, pct_gps)

#Regionally and by facility type
fac_list_region_factype <- fac_list_long2 %>%
  group_by(region, fac_type) %>%
  summarize(total_fac=sum(n),
            total_gps=sum(gps)) %>%
  ungroup() %>%
  mutate(pct_gps=(total_gps/total_fac)*100) %>%
  dplyr::select(region, fac_type, total_fac, total_gps, pct_gps)

###########################
#Compiling data together
##########################
senegal_stats <- rbind(fac_list_nat, fac_list_nat_factype,
                       fac_list_region, fac_list_region_factype)

#Formatting Senegal stats
senegal_stats <- senegal_stats %>%
  mutate(location_name=ifelse(region=="All", "Senegal", region),
         fac_type=ifelse(fac_type=="hopital", "Hospital", fac_type),
         fac_type=ifelse(fac_type=="centre de sante", "Health center",fac_type),
         fac_type=ifelse(fac_type=="poste de sante", "Health post", fac_type),
         fac_type=ifelse(fac_type=="case de sante", "Health hut", fac_type)) %>%
  dplyr::select(-region) %>%
  dplyr::select(location_name, fac_type, total_fac, total_gps, pct_gps)

#Outsheeting compiled data
write.csv(senegal_stats, paste0(mfl_direct, "/senegal_fac_stats.csv"), row.names=FALSE)

###Preparing comparisons
spa2012 <- spa_frame %>%
  filter(source=="SPA 2012-2013" & fac_own=="All") %>%
  mutate(n_spa2012=n,
        fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
        fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_spa2012)

spa2017 <- spa_frame %>%
  filter(source=="SPA 2017" & fac_own=="All") %>%
  mutate(n_spa2017=n,
         fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
         fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_spa2017)

spa2019 <- spa_frame %>%
  filter(source=="SPA 2019" & fac_own=="All") %>%
  mutate(n_spa2019=n,
         fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
         fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_spa2019)

healthmap2019_all <- health_maps %>%
  filter(year==2019 & fac_own=="All") %>%
  mutate(n_hm2019=n,
         fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
         fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_hm2019)
        
healthmap2019_public <- health_maps %>%
         filter(year==2019 & fac_own=="Public") %>%
  mutate(n_hm2019_public=n,
         fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
         fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_hm2019_public)
   
healthmap2021_public <- health_maps %>%
          filter(year==2021) %>%
          mutate(n_hm2021_public=n,
                 fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
                 fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type)) %>%
  dplyr::select(location_name, fac_type, n_hm2021_public)

#Compare #s for facility list to date and other sources
compare_stats <- merge(senegal_stats, spa2012, by=c("location_name", "fac_type"), all=TRUE)
compare_stats <- merge(compare_stats, spa2017, by=c("location_name", "fac_type"), all=TRUE)
compare_stats <- merge(compare_stats, spa2019, by=c("location_name", "fac_type"), all=TRUE)
compare_stats <- merge(compare_stats, healthmap2019_all, by=c("location_name", "fac_type"), all=TRUE)
compare_stats <- merge(compare_stats, healthmap2019_public, by=c("location_name", "fac_type"), all=TRUE)
compare_stats <- merge(compare_stats, healthmap2021_public, by=c("location_name", "fac_type"), all=TRUE)

#Formatting compare stats
compare_stats <- compare_stats %>%
                    mutate(total_fac=ifelse(location_name=="Dakar" & fac_type=="Case de sante",NA,total_fac),
                           total_gps=ifelse(location_name=="Dakar" & fac_type=="Case de sante",NA,total_gps),
                           pct_gps=ifelse(location_name=="Dakar" & fac_type=="Case de sante",NA,pct_gps))
                    #dplyr::select(total_gps, pct_gps)


compare_stats_long <- melt(data=compare_stats,
                           id=c("location_name", "fac_type"),
                           variable.name="source",
                           value.name="n")

compare_stats_long <- compare_stats_long %>%
                        filter()


compare_stats_cfl <- compare_stats_long %>%
                      filter(source=="total_fac") %>%
                      mutate(fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
                             fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type))


compare_stats_cfl$fac_order <- ordered(compare_stats_cfl$fac_type,
                                         levels=c("All", "Hospital", "Health center", "Health post", "Health hut"))

compare_stats_other <- compare_stats_long %>%
                      filter(source !="total_fac" & source !="total_gps" & source !="pct_gps") %>%
                      mutate(fac_type=ifelse(fac_type=="Case de sante", "Health hut", fac_type),
                            fac_type=ifelse(fac_type=="Health centre", "Health center", fac_type))

compare_stats_other$source_order <- factor(compare_stats_other$source, 
                                           levels=c("n_spa2012", "n_spa2017", "n_spa2019", "n_hm2019", "n_hm2019_public", 
                                                    "n_hm2021_public"),
                                           labels=c("SPA 2012 frame", "SPA 2017 frame", "SPA 2019 frame", "Health Map 2019 (all)",
                                                    "Health Map 2019 (public)", "Health Map 2021 (public)"))

compare_stats_other$fac_order <- ordered(compare_stats_other$fac_type,
                                            levels=c("All", "Hospital", "Health center", "Health post", "Health hut"))

#Creating bar charts by facility type
#All
compare_stats_other_all <- compare_stats_other %>%
  filter(location_name !="Senegal" & fac_type=="All") 

compare_stats_cfl_all <- compare_stats_cfl %>%
  filter(location_name !="Senegal" & fac_type=="All")

(ggplot() +
    geom_bar(data=compare_stats_cfl_all, aes(x=factor(location_name), y=n), fill=dkblue, width=0.90, stat="identity") +
    geom_point(data=compare_stats_other_all, aes(x=factor(location_name), y=n), color=black, size=8)) +
  geom_point(data=compare_stats_other_all, aes(x=factor(location_name), y=n, colour=source_order), size=7) +
  
  scale_colour_manual(values=c("#598300", "#80BC00", "#B0D781",
                               "#cc9e00", "#FFC600", "#ffd74c"), name="Source") +
  scale_y_continuous(breaks=seq(0,800,100), expand=c(0.01,0.01)) +
  theme_bw() +
  ggtitle("Comparing facility counts by source: all facilities") +
  xlab("") +
  ylab("Number of facilities") +
  theme(
    legend.position="right",
    panel.grid.major=element_blank(),
    panel.grid.minor=element_blank(),
    strip.text=element_text(size=12),
    axis.text=element_text(size=12),
    axis.title.y=element_text(size=14),
    plot.caption=element_text(size=5, face="italic", hjust=0))
# facet_wrap(~fac_order, ncol=1, scales="free_y")

ggsave(paste0(mfl_direct, "/comparing_fac_counts_all.pdf"),
       width=15,
       height=8)


#Creating bar charts by facility type
  #Hospitals
compare_stats_other_hosp <- compare_stats_other %>%
                       filter(location_name !="Senegal" & fac_type=="Hospital")

compare_stats_cfl_hosp <- compare_stats_cfl %>%
                      filter(location_name !="Senegal" & fac_type=="Hospital")

(ggplot() +
    geom_bar(data=compare_stats_cfl_hosp, aes(x=factor(location_name), y=n), fill=purple, width=0.90, stat="identity") +
    geom_point(data=compare_stats_other_hosp, aes(x=factor(location_name), y=n), color=black, size=8)) +
    geom_point(data=compare_stats_other_hosp, aes(x=factor(location_name), y=n, colour=source_order), size=7) +
  
    scale_colour_manual(values=c("#598300", "#80BC00", "#B0D781",
                                 "#cc9e00", "#FFC600", "#ffd74c"), name="Source") +
    scale_y_continuous(breaks=seq(0,50,5), expand=c(0.01,0.01)) +
    theme_bw() +
    ggtitle("Comparing facility counts by source: hospitals") +
    xlab("") +
    ylab("Number of facilities") +
    theme(
   legend.position="right",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title.y=element_text(size=14),
      plot.caption=element_text(size=5, face="italic", hjust=0))
  # facet_wrap(~fac_order, ncol=1, scales="free_y")

ggsave(paste0(mfl_direct, "/comparing_fac_counts_hosp.pdf"),
       width=15,
       height=8)


#Creating bar charts by facility type
#Hospitals
compare_stats_other_hc <- compare_stats_other %>%
  filter(location_name !="Senegal" & fac_type=="Health center")

compare_stats_cfl_hc <- compare_stats_cfl %>%
  filter(location_name !="Senegal" & fac_type=="Health center")

(ggplot() +
    geom_bar(data=compare_stats_cfl_hc, aes(x=factor(location_name), y=n), fill=dkteal, width=0.90, stat="identity") +
    geom_point(data=compare_stats_other_hc, aes(x=factor(location_name), y=n), color=black, size=8)) +
  geom_point(data=compare_stats_other_hc, aes(x=factor(location_name), y=n, colour=source_order), size=7) +
  
  scale_colour_manual(values=c("#598300", "#80BC00", "#B0D781",
                               "#cc9e00", "#FFC600", "#ffd74c"), name="Source") +
 scale_y_continuous(breaks=seq(0,110,10), expand=c(0.01,0.01)) +
  theme_bw() +
  ggtitle("Comparing facility counts by source: health centres") +
  xlab("") +
  ylab("Number of facilities") +
  theme(
    legend.position="right",
    panel.grid.major=element_blank(),
    panel.grid.minor=element_blank(),
    strip.text=element_text(size=12),
    axis.text=element_text(size=12),
    axis.title.y=element_text(size=14),
    plot.caption=element_text(size=5, face="italic", hjust=0))
# facet_wrap(~fac_order, ncol=1, scales="free_y")

ggsave(paste0(mfl_direct, "/comparing_fac_counts_hc.pdf"),
       width=15,
       height=8)


#Creating bar charts by facility type
#Health posts
compare_stats_other_hp <- compare_stats_other %>%
  filter(location_name !="Senegal" & fac_type=="Health post")

compare_stats_cfl_hp <- compare_stats_cfl %>%
  filter(location_name !="Senegal" & fac_type=="Health post")

(ggplot() +
    geom_bar(data=compare_stats_cfl_hp, aes(x=factor(location_name), y=n), fill=teal, width=0.90, stat="identity") +
    geom_point(data=compare_stats_other_hp, aes(x=factor(location_name), y=n), color=black, size=8)) +
  geom_point(data=compare_stats_other_hp, aes(x=factor(location_name), y=n, colour=source_order), size=7) +
  
  scale_colour_manual(values=c("#598300", "#80BC00", "#B0D781",
                               "#cc9e00", "#FFC600", "#ffd74c"), name="Source") +
 scale_y_continuous(breaks=seq(0,700,100), expand=c(0.01,0.01)) +
  theme_bw() +
  ggtitle("Comparing facility counts by source: health posts") +
  xlab("") +
  ylab("Number of facilities") +
  theme(
    legend.position="right",
    panel.grid.major=element_blank(),
    panel.grid.minor=element_blank(),
    strip.text=element_text(size=12),
    axis.text=element_text(size=12),
    axis.title.y=element_text(size=14),
    plot.caption=element_text(size=5, face="italic", hjust=0))
# facet_wrap(~fac_order, ncol=1, scales="free_y")

ggsave(paste0(mfl_direct, "/comparing_fac_counts_hp.pdf"),
       width=15,
       height=8)


#Creating bar charts by facility type
#Health huts
compare_stats_other_hh <- compare_stats_other %>%
  filter(location_name !="Senegal" & fac_type=="Health hut") %>%
  mutate(n=ifelse(source=="n_spa2017" & location_name=="Dakar",NA,n))

compare_stats_cfl_hh <- compare_stats_cfl %>%
  filter(location_name !="Senegal" & fac_type=="Health hut") 
(ggplot() +
    geom_bar(data=compare_stats_cfl_hh, aes(x=factor(location_name), y=n), fill=orange, width=0.90, stat="identity") +
    geom_point(data=compare_stats_other_hh, aes(x=factor(location_name), y=n), color=black, size=8)) +
  geom_point(data=compare_stats_other_hh, aes(x=factor(location_name), y=n, colour=source_order), size=7) +
  
  scale_colour_manual(values=c("#598300", "#80BC00", "#B0D781",
                               "#cc9e00", "#FFC600", "#ffd74c"), name="Source") +
  scale_y_continuous(breaks=seq(0,375,50), expand=c(0.01,0.01)) +
  theme_bw() +
  ggtitle("Comparing facility counts by source: health huts") +
  xlab("") +
  ylab("Number of facilities") +
  theme(
    legend.position="right",
    panel.grid.major=element_blank(),
    panel.grid.minor=element_blank(),
    strip.text=element_text(size=12),
    axis.text=element_text(size=12),
    axis.title.y=element_text(size=14),
    plot.caption=element_text(size=5, face="italic", hjust=0))
# facet_wrap(~fac_order, ncol=1, scales="free_y")

ggsave(paste0(mfl_direct, "/comparing_fac_counts_hh.pdf"),
       width=15,
       height=8)

#Outsheeting compare stats
write.csv(compare_stats, paste0(mfl_direct, "/compare_fac_stats.csv"), row.names=FALSE)

################################
###Stacked bar graphs by facility type
################################
graph_data <- compare_stats %>%
  mutate(total_no_gps=total_fac-total_gps) %>%
  dplyr::select(location_name, fac_type, total_gps, total_no_gps)

graph_data_long <- melt(graph_data,
                        id=c("location_name", "fac_type"),
                        variable.name="total",
                        value.name="n")

#Ordering
graph_data_long$location_name <- ordered(graph_data_long$location_name, levels=c("Ziguinchor", "Thies", "Tambacounda", "Sedhiou", "Saint-Louis",
                                                                                 "Matam", "Louga", "Kolda", "Kedougou", "Kaolack", "Kaffrine", "Fatick", "Diourbel", "Dakar", "Senegal"))

graph_data_long$fac_type <- ordered(graph_data_long$fac_type, levels=c("All", "Hospital", "Health center", "Health post", "Health hut"))
graph_data_long$total <- ordered(graph_data_long$total, levels=c("total_no_gps", "total_gps"))

#Bar graph - all facilities
graph_data_long_all <- graph_data_long %>%
  filter(location_name !="Senegal" & fac_type=="All")

(ggplot(graph_data_long_all, aes(x=location_name, y=n)) +
    geom_bar(aes(fill=total), stat="identity", color=dkblue) +
    scale_fill_manual(values=c(lightGrey,dkblue), name="") +
    coord_flip() +
    theme_bw() +
    xlab("") +
    ylab("") +
    theme(
      legend.position="none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title=element_text(size=12)) 
  # facet_wrap(~fac_type, ncol=2) 
)

ggsave(paste0(mfl_direct, "/pct_facilities_gps_all_byregion.pdf"),
       width=11,
       height=8)

#Bar graph - hospitals
graph_data_long_all <- graph_data_long %>%
  filter(location_name !="Senegal" & fac_type=="Hospital")

(ggplot(graph_data_long_all, aes(x=location_name, y=n)) +
    geom_bar(aes(fill=total), stat="identity", color=purple) +
    scale_fill_manual(values=c(lightGrey,purple), name="") +
    coord_flip() +
    theme_bw() +
    xlab("") +
    ylab("") +
    theme(
      legend.position="none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title=element_text(size=12)) 
  # facet_wrap(~fac_type, ncol=2) 
)

ggsave(paste0(mfl_direct, "/pct_facilities_gps_hosp_byregion.pdf"),
       width=11,
       height=8)

#Bar graph - health centres
graph_data_long_all <- graph_data_long %>%
  filter(location_name !="Senegal" & fac_type=="Health center")

(ggplot(graph_data_long_all, aes(x=location_name, y=n)) +
    geom_bar(aes(fill=total), stat="identity", color=dkteal) +
    scale_fill_manual(values=c(lightGrey,dkteal), name="") +
    coord_flip() +
    theme_bw() +
    xlab("") +
    ylab("") +
    theme(
      legend.position="none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title=element_text(size=12)) 
  # facet_wrap(~fac_type, ncol=2) 
)

ggsave(paste0(mfl_direct, "/pct_facilities_gps_hc_byregion.pdf"),
       width=11,
       height=8)


#Bar graph - health post
graph_data_long_all <- graph_data_long %>%
  filter(location_name !="Senegal" & fac_type=="Health post")


(ggplot(graph_data_long_all, aes(x=location_name, y=n)) +
    geom_bar(aes(fill=total), stat="identity", color=teal) +
    scale_fill_manual(values=c(lightGrey,teal), name="") +
    coord_flip() +
    theme_bw() +
    xlab("") +
    ylab("") +
    theme(
      legend.position="none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title=element_text(size=12)) 
  # facet_wrap(~fac_type, ncol=2) 
)

ggsave(paste0(mfl_direct, "/pct_facilities_gps_hp_byregion.pdf"),
       width=11,
       height=8)

#Bar graph - case de sante

graph_data_long_all <- graph_data_long %>%
  filter(location_name !="Senegal" & fac_type=="Health hut")

(ggplot(graph_data_long_all, aes(x=location_name, y=n)) +
    geom_bar(aes(fill=total), stat="identity", color=orange) +
    scale_fill_manual(values=c(lightGrey,orange), name="") +
    coord_flip() +
    theme_bw() +
    xlab("") +
    ylab("") +
    theme(
      legend.position="none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      strip.text=element_text(size=12),
      axis.text=element_text(size=12),
      axis.title=element_text(size=12)) 
  # facet_wrap(~fac_type, ncol=2) 
)

ggsave(paste0(mfl_direct, "/pct_facilities_gps_cds_byregion.pdf"),
       width=11,
       height=8)