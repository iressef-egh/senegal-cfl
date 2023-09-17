# ##############################################################################
# Project: Collated Senegal MFL Prep
# Author:  Patty Liu (patrick.liu@gatesventures.com)
# The script runs through a pipeline to produce a consolidated facility list (CFL)
# in Senegal by matching across various facility lists. 
# Manual verification conducted by Nancy Fullman (Gates Ventures), Daouda Gueye (IRESSSEF)
# ##############################################################################

## Clear workspace
rm(list=ls())

## Load packages
pacman::p_load(data.table, dplyr, stringi, stringr, pbapply, stringdist, rio, xlsx, sf, sp, purrr, pbmcapply)

## Load name cleaning functions
source("code/ref/name_cleaning.r")

## Update
update <- 0 ## Toggle between 0/1 for updates

## 0. SETUP---------------------------------------------------------------------

## Paths 
data_root <- "data/01_raw"
out_root <- "data/02_prepped"

## 1. LOAD AND PREPARE FACILITY LISTS ------------------------------------------

df <- list()

## ANSD ------------------------------------------------------------------------

## Hospital, HC, HP file
df.ansd <- import(paste0(data_root, "/ansd/2017_2018/ansd_spa_list2017_2018_formatted.xlsx")) %>%
  as.data.table %>% 
  setnames(c("region", ".", "health_district", ".", "fac_name", ".", ".", ".", "fac_type", ".", ".", "fac_own", ".", "functioning", "source_id", ".", ".")) %>%
  select(region, health_district, fac_name, fac_type, fac_own, source_id)

## Case de santes file
df.ansd.cs <- import(paste0(data_root, "/ansd/2017_2018/ansd_spa_list2017_2018_formatted.xlsx"), sheet=2) %>% 
  as.data.table %>% 
  setnames(c("region", ".", "health_district", ".", "fac_assoc", "fac_name", "fac_type", ".", ".", ".", "fac_own", ".", ".", ".", "functioning", "source_id", ".", ".")) %>%
  select(region, health_district, fac_name, fac_type, fac_own, source_id)

## Append
df$ansd <- rbind(df.ansd, df.ansd.cs, fill=T)

## Clean facility type
df$ansd[, fac_type := dplyr::recode(fac_type,
                                    HO="Hospital",
                                    PS="Health post",
                                    CS="Health centre",
                                    case="Case de sante")]
df$ansd[, fac_own := dplyr::recode(fac_own, 
                                   PRIVATE="Private", 
                                   PUBLIQUE="Public")]

df$ansd[, region := str_to_title(region)]
df$ansd[, health_district := str_to_title(health_district)]

## DHS SPA ------------------------------------------------------------------------

## Load SPA facilities
df$spa <- fread("data/01_raw/dhs/spa_geolocated_SEN.csv") %>% 
          .[,.(region, svy, source_id=as.character(fac_id), fac_id, fac_type, fac_own, latnum, longnum)] %>% 
          setnames(c("region", "svy", "latnum", "longnum"), c("admin1_svy", "source", "lat", "long"))

## Load and clean identifier names
df.spa.names <- fread(paste0(data_root, "/dhs/spa_admin2_facnames_2014-2019_SEN.csv")) %>%
                .[, .(region_distfile, fac_id, fac_name, department)] %>%
                setnames(c("department", "region_distfile"), c("district", "region"))

## Merge on
df$spa <- merge(df$spa, df.spa.names, by="fac_id", all.x=T)
## Using admin1 specification from facility names file for all facilities except for SPA 2012-2013 (not in naming file)
## Doing this because of discrepancies in the micro-data where admin1's may be off
df$spa[source=="SPA 2012-2013", region := admin1_svy]
df$spa$admin1_svy <- NULL
df$spa$fac_id <- NULL

## DHIS2 -----------------------------------------------------------------------

## Load DHIS2 data
df$dhis <- import(paste0(data_root, "/dhis2/Health_Facilities_SN.xls"), sheet="Orgunit")

## Drop first two rows and rename
df$dhis <- df$dhis[3:nrow(df$dhis),1:4] %>%
  setnames(c("region", "district", "fac_name", "source_id")) %>%
  as.data.table

## Remove header on admin_1
df$dhis[, region := gsub("RM ", "", region)]

## COUS ------------------------------------------------------------------------

## Load COUS data
df$cous <- import(paste0(data_root, "/iressef/Updated MFL_ Sénégal 18032022.xlsx"), sheet="COUS Initiale")

## Reanme
df$cous <- df$cous %>% 
  as.data.table %>% 
  setnames(c("region", "health_district", "fac_name", "fac_type", "other", "fac_own", "lat", "long"))

## Drop other
df$cous$other <- NULL

## Set facility name and types
df$cous[, fac_type := dplyr::recode(fac_type,
                                    PS="Poste de sante",
                                    CS="Centre de sante",
                                    CMG="Centre de sante",
                                    HP="Hospital")]

df$cous <- df$cous[!fac_type%in%c("RM")]

## MAINA ET AL -----------------------------------------------------------------

## Load Maina
df$maina <- fread(paste0(data_root, "/who_gmp/SEN_who-cds-gmp-2019-01-eng.csv"), encoding="Latin-1")

## Adjust region spellings
df$maina[admin1=="Kaokack", admin1:= "Kaolack"]
df$maina[admin1=="Saintlouis", admin1:= "Saint-Louis"]
df$maina[admin1=="Sediou", admin1:= "Sedhiou"]

## Set facility ownership - all facilities are Public
df$maina[, fac_own := "Government/public"]

## Rename other vars for merging
df$maina %>% setnames(c("latitude", "longitude"), c("lat", "long"))

## Select
df$maina <- df$maina[, .(fac_name=facility_name, fac_type=stri_trans_general(facility_type, "latin-ascii"), fac_own=ownership, region=admin1, lat, long)]

## HDX -------------------------------------------------------------------------

## Load HDX
df.hdx <- paste0(data_root, "/hdx/senegal.csv") %>% fread %>%
      .[, .(X, Y, amenity, name, healthcare, operator_type, source_id=osm_id)] %>% 
      setnames(c("X", "Y", "name"), c("long", "lat", "fac_name")) %>%
      .[, .(fac_name, fac_type=amenity, lat, long, source_id)]

df.hdx[, `:=` (source = "HDX", fac_id=.I + 140000, admin1=NA, fac_own=NA)]

df.hdx.nogps <- df.hdx[is.na(lat)] ## remove those without gps so I can pull admin1
df.hdx <- df.hdx[!is.na(lat)]

## Use GPS location to find Admin1
adm_1 <- import("data/shapefiles/lbd_standard_admin_1.rds")
shp <- subset(adm_1, adm_1$ADM0_NAME == "Senegal")
export(shp, "data/shapefiles/sen_adm1.rds")
shp <- "data/shapefiles/sen_adm1.rds" %>% import
coordinates(df.hdx) <- ~ long + lat
proj4string(df.hdx) <- "+proj=longlat +datum=WGS84 +no_defs"
assigned_admin1 <- over(df.hdx, shp)
df.hdx <- df.hdx %>% as.data.table
df.hdx[, region := assigned_admin1$ADM1_NAME]

## Manually map facilities to regions
df.hdx[fac_name=="Poste de la Santé Mame-Louise-Gomis", region:="Dakar"]
df.hdx[fac_name=="Poste de Santé de Guet Ndar", region:="Saint-Louis"]
df.hdx[fac_name=="Poste de santé de Guet-Ndar", region:="Saint-Louis"]
df.hdx[fac_name=="Poste de Santé Ndar Toute", region:="Saint-Louis"]
df.hdx[fac_name=="Poste de Goxu-mbacc", region:="Saint-Louis"]
df.hdx[fac_name=="Case de Santé du quartier Hydrobase", region:="Saint-Louis"]

## Append back those without
df$hdx <- rbind(df.hdx, df.hdx.nogps, fill=TRUE)

## ESRI ------------------------------------------------------------------------

## Load and clean dataset
df$esri <- paste0(data_root, "/esri_senegal/Carte_sanitaire_Kaolack.csv") %>% fread %>%
          . [, .(source_id=GlobalID, fac_name=NOM, fac_type=TYPE, region=REGION, district=DEPARTEMEN, health_district=DISTRICTSA,  lat=X, long=Y)]

## OTHER FACILITIES FROM IRESSEF LIST  -----------------------------------------

df$iressef <- fread(paste0(data_root, "/iressef/draft_mfl_combined.csv"), encoding = "Latin-1") %>%
              .[source2%in%c("Merged facilities", "Other facilities", "No GPS facilities"),
                .(source2, region, department, fac_name_org, fac_type2, lat, long)] %>%
              setnames(c("source", "region", "district", "fac_name", "fac_type", "lat", "long"))

## MOH FILE ---------------------------------------------------------------

df$moh <- import(paste0(data_root, "/moh/Répartition PS et CS par commune Sénégal_combined.xlsx"), sheet=2) %>% 
          as.data.table %>%
          .[, .(region=Régions, district=Départements, health_district=`Districts de santé`, fac_name=`Structures de santé`)]


## REGIONAL FILES --------------------------------------------------------------

## Louga
df$louga <- fread(paste0(data_root, "/louga2023/louga2023.csv"), encoding = "Latin-1") %>%
  .[, .(region="Louga", district=department, health_district, fac_name, fac_type=stri_trans_general(fac_type, "latin-ascii"), fac_own, lat, long)]

## Sedhiou
df$sedhiou <- fread(paste0(data_root, "/sedhiou/sedhiou.csv"), encoding = "Latin-1") %>% 
  setnames(c("commune", "fac_type", "department"), c("fac_type", "fac_own", "district")) %>%
  .[fac_name!=nom_de_la_localite&nom_de_la_localite!="", fac_name_old := fac_name] %>% 
  .[fac_name!=nom_de_la_localite&nom_de_la_localite!="", fac_name := nom_de_la_localite] %>% 
  .[, .(region, district, health_district, fac_name, fac_name_old, fac_type=stri_trans_general(fac_type, "latin-ascii"), fac_own, lat, long)]


## DGES Hospital Data ----------------------------------------------------------

df$dges <- import(paste0(data_root, "/dges/La liste des Etablissements Publics de Sante par niveau.xlsx")) %>% 
  as.data.table %>%
  select(-additional_notes)

## Set names and ids -----------------------------------------------------------

df$ansd[, `:=`(source = "ANSD 2017-2018", fac_id=.I + 100000)]
df$dhis[, `:=`(source = "DHIS", fac_id=.I + 110000)]
df$cous[, `:=` (source = "COUS", fac_id=.I + 120000)]
df$maina[, `:=` (source = "Maina et. al (2019)", fac_id = .I + 130000)]
df$hdx[, `:=` (source = "HDX")]
df$esri[, `:=` (source = "ESRI Kaolack", fac_id=.I + 150000)]
df$iressef[, `:=` (source="IRESSEF Match", fac_id=.I + 160000)]
df$moh[, `:=` (source="MOH", fac_id=.I + 170000)]
df$louga[, `:=` (source="Louga", fac_id=.I + 180000)]
df$sedhiou[,  `:=` (source="Sedhiou", fac_id=.I + 190000)]
df$dges[, `:=` (source= "DGES", fac_id=.I + 200000)]

## Append lists
df <- lapply(df, function(x) {
  if ("source_id" %in% names(x)) x$source_id <- x$source_id %>% as.character
  return(x)
}) %>% rbindlist(fill=T)

export(df, "data/02_prepped/appended.rds")

df <- import("data/02_prepped/appended.rds")

## PREPPING --------------------------------------------------------------------

## Clean region strings
df[, region := stringi::stri_trans_general(region, "latin-ascii") %>% str_to_title]
df[region%in%c("Sediou"), region := "Sedhiou"]
df[grepl("Saint", region), region := "Saint-Louis"]
df[region=="Kaokack", region := "Kaolack"]

## Clean district strings
df[, district := stringi::stri_trans_general(district, "latin-ascii") %>% str_to_title]
df[, health_district := stringi::stri_trans_general(health_district, "latin-ascii") %>% str_to_title]

## FACILITY NAME ---------------------------------------------------------------

df[, fac_name2 := fac_name]
df[, fac_name2 := clean.fac_name(fac_name2)]

## FACILITY TYPE ---------------------------------------------------------------

## Store and create new column
df[, fac_type_orig := fac_type]
df[, fac_type := fac_type %>% tolower]

## Replace fac_type
db.fac_types <- fread("data/ref/fac_types.csv") %>%
  ## Remove non-alphanumeric (used for string search later)
  mutate(fac_type=gsub("\\\\s|\\^", "",fac_type ))
df <- merge(df, db.fac_types, by="fac_type", all.x=T)
df[!is.na(rename), fac_type := rename]; df$rename <- NULL
df[fac_type=="", fac_type := NA]

## Search for and export list of string matches close to facility type
if (update) {
  fac_types <- data.table(fac_type = df$fac_type %>% tolower %>%  unique %>% sort) %>% filter(fac_type!="other")
  str <- lapply(fac_types$fac_type, function(x) {
    res <- get.aregexec(x, df$fac_name2 %>% unique, 0.12)
    data.table(fac_type=x, string=res)
  }) %>% rbindlist
  
  ## Update list
  str[, .(fac_type = string, rename=fac_type)] %>%
    rbind(db.fac_types) %>% arrange(rename) %>% unique %>%
    export("data/ref/fac_types.csv")
}

## If fac_type "other", drop and see if I can pull it out
df[fac_type=="other", fac_type:=NA]

## Extract facility types
db.fac_types <- fread("data/ref/fac_types.csv")
## Arrange length
db.fac_types[, len := nchar(fac_type)]
db.fac_types <- db.fac_types %>% arrange(rename, -len)
types <- db.fac_types$rename %>% unique
for (i in 1:length(types)) {
  .string <- db.fac_types[rename==types[i]]$fac_type %>% paste0(., collapse="|")
  df[grepl(.string, fac_name2)&is.na(fac_type), fac_type := types[i]]
  df[, fac_name2 := gsub(.string, "", fac_name2)]
}
## Further name cleaning
df[, fac_name2 := gsub("communautaire|brigade nationale|brigade regionale|national|regional", "",  fac_name2)]
drop <- do.call(paste0, expand.grid(c("^", "\\s"), c("eta","etat", "la", "de", "du", "as"), c("\\s"))) %>% paste0(., collapse="|")
df[, fac_name2 := gsub(drop, " ", fac_name2)]
df[, fac_name2 := fac_name2 %>% trimws()]

## FACILITY OWN ----------------------------------------------------------------

df[, fac_own_orig := fac_own]
df[, fac_own := tolower(fac_own)]
df[grepl("priv", fac_own), fac_own := "private"]
df[grepl("pub|comm|garn", fac_own), fac_own := "public"]
df[grepl("ngo", fac_own), fac_own := "ngo/mission"]

t <- df %>% copy
t[, admin1 := region]
t[grepl("SPA", source), fac_id := source_id]

## MATCH -----------------------------------------------------------------------

## Load matched from IRESSEF Workshop
df <- import("data/02_prepped/match_restructured_facilitylist_20230108.xlsx", sheet=2) %>% 
  as.data.table %>%
  mutate(fac_name2 = group_name)

## Append on Louga, Sedhiou, DGES
q <- rbind(df, 
           t[source%in%c("Louga", "Sedhiou", "DGES")] %>% select(intersect(names(df), names(t)), fac_name_old), fill=T)

## Merge in region, department, health district, fac_type_orig, fac_own_orig
q <- merge(q, 
           t[, .(fac_id, region, department=district, health_district, fac_type_orig, fac_own_orig)] %>% unique,
           by="fac_id", all.x=T)
q %>% setcolorder(c("admin1", "admin2", "region", "department", "health_district"))
## Fill in region, department for SPA
q[grepl("SPA", source)&is.na(region), `:=` (region=admin1, department = admin2)]
q[source=="Tambacounda 2022 list", `:=` (region=admin1, health_district=admin2)]

## Merge in newer fac_type call
t[, fac_type2 := fac_type]
q <- merge(q, t[, .(fac_id, fac_type2)] %>% unique, by="fac_id", all.x=T)

## Update facility types
q[, fac_type := tolower(fac_type)]
q[, fac_type := dplyr::recode(fac_type, 
                              `health post` = "poste de sante",
                              `health centre` = "centre de sante")]
q[, fac_type2 := dplyr::recode(fac_type2, 
                              `health post` = "poste de sante",
                              `health centre` = "centre de sante")]

## Fac own
q[, fac_own := tolower(fac_own)]

## If missing fac_name2, replace with district or health_district name
q[fac_name2=="", fac_name2:=health_district]

q <- q %>% arrange(admin1, fac_name2)

## Re-fuzzy match with new facilities
groups <- grouper_by(q[!is.na(fac_name2)&!is.na(admin1)] %>% select(-group), by=c("admin1"), method=list("str"), threshold=list("str="=0.2))
q[!is.na(fac_name2)&!is.na(admin1), g := groups$group]

q %>% setcolorder(c("admin1", "admin2", "region", "department", "health_district", "group","g", "group_name", "fac_name", "fac_name2", "fac_type", "fac_type2", "fac_type_orig", "fac_own", "fac_own_orig", "source", "fac_id", "fac_id_orig"))

## For newly matched

## If g has a unique group, then replace group=NA with group
gs <- q[grepl("Louga|Sedhiou|DGES", source)]$g %>% unique
for (i in 1:length(gs)) {
  .group <- q[g==gs[i]]$group %>% unique %>% na.omit
  if (length(.group)==1) q[g==gs[i], group := .group]
}

export(q, "data/02_prepped/match_facilitylist_20230504.xlsx")

## 3. FUZZY MATCH ACROSS LISTS -------------------------------------------------------------------------

## Fuzzy match across unique strings from facility lists
## Group by admin1 and set max Jaro-winkler distance of 0.2 for grouping fuzzy string matches
cond <- c("admin1")
match_var <- "fac_name2"
distance <- 0.2

## Separate out admin1, fac_name2 and sort
t <- df[, c(cond, "fac_name2"), with=F] %>% unique
t <- t[order(admin1, fac_name2)]

## Create a grouping variable to iterate matching on
t[, i := .GRP, by=cond]
## Fuzzy group matching
t1 <- lapply(t$i%>%unique, function(x) {
  sf <- t[i==x]
  sf[, bins := sapply(sf[[match_var]], function(n) { 
    paste(as.integer(ifelse(stringdist(n, sf[[match_var]], method = "jw")<=distance, 1, 0)), collapse="")}
  )]
}) %>% rbindlist
## Create an ID to group those that fuzzy matched together
t1[, group := as.integer(as.factor(bins))]
t1[, group := .GRP, by=c(cond, "group")]
## Remove bins column
t1[, bins := NULL]
## Identify number of strings within group
t1[, n := .N, by=group]
t1[, nth := seq_len(.N), by=group]
## Take the first string within a group and calculate JW distance 
## Between each member of the group and the first string
t1[n>1, first := fac_name2[nth==1], by=group]
t1[, dist := stringdist(fac_name2, first, method="jw")]
t1 <- t1[order(group)]
t1$i <- NULL
t1[, id := .I]
## Drop cols
t1 <- t1[, c("group", "n", "nth", "id") := NULL]

## Import previous verified
t1.v <- import(paste0(out_root, "/match_within_update_checked.xlsx"), col_types="text") %>% as.data.table
## Clear new column if processed
t1.v[checked==1|match_verified==1|unmatch==1|match_revise==1|match_flagged==1, new := NA]
## Append on new
t1.m <- merge(t1.v[, .(admin1, fac_name2, old=1)], t1[, .(admin1, fac_name2)], all=T)
t1.n <- t1.m[is.na(old)]
t1.u <- rbind(t1.v, t1.n %>% select(-old) %>% mutate(new=1), fill=T)
## Drop those without admin1 and those without a fac_name2
t1.u <- t1.u[!is.na(admin1)&!is.na(fac_name2)]
## Sort
t1.u <- t1.u[order(admin1, fac_name2)]
export(t1.u, paste0(out_root, "/match_within_update_20220430.xlsx"))

## 4. IMPORT FUZZY MATCH LIST, MERGE, AND CLEAN -------------------------------------------------------------------------

t2 <- import(paste0(out_root,"/match_within_update_20220430_checked.xlsx"))
t2 <- t2 %>% as.data.table

## Set groups
t2[, group_name := ifelse(!is.na(first_v2), first_v2, first)]
t2[is.na(group_name), group_name := fac_name2]
t2 <- t2[, .(admin1, fac_name2, group_name, match_flagged, notes)]

## Merge on to df
df1 <- merge(df[!(source%in%c("IRESSEF Match", "DHIS"))],
             t2, by=c("admin1", "fac_name2"), all.x=T)
df1 <- df1[is.na(group_name), group_name := fac_name2]
df1 <- df1[order(admin1, group_name)]
df1[, group := .GRP, by=.(admin1, group_name)]


df1 %>% setcolorder(c("admin1", "admin2", "fac_type", "group", "group_name", "source", "fac_id", "fac_name", "fac_name2",
                      "fac_own", "functioning", "lat", "long", "fac_assoc"))
df1 <- df1[!is.na(fac_name)]

## Flag those with multiple facility types
df1[!is.na(fac_type)&fac_type!=""&fac_type!="Autre", n_fac_type :=unique(fac_type) %>% length, by=group]
df1[, n_fac_type := max(n_fac_type, na.rm=T), by=group]
df1[is.na(n_fac_type),  n_fac_type := 1]

## Within a group, calculate the max pairwise GPS distance
df1[, c("lat", "long") := lapply(.SD, as.numeric), .SDcols=c("lat", "long")]
ids <- unique(df1[!is.na(group)]$group) %>% as.numeric
q <- pblapply(ids, function(x) {
  t <- df1[group==x&!is.na(lat), .(lat, long)] %>% unique
  if (nrow(t)>1) {
    perms <- combn(c(1:nrow(t)), 2) %>% t
    dists <- lapply(1:nrow(perms), function(i) {
      distHaversine(t[perms[i,1],], t[perms[i,2],])
    }) %>% unlist
    df1[group==x, max_dist := round(max(dists)/1000, 2)] ## Meters to kilometers
    df1[group==x, n_gps := nrow(t)]
  } else {
    df1[group==x, n_gps := nrow(t)]
  }
})

## Sort for easier viewing
df1 <- df1[order(group, fac_type, source, admin2, lat)]
df1[, n := .N, by=group]


## Split out matches

## Flag if there are more than 1 ansd per matching group
df1[grepl("ANSD", source), n_ansd := .N, by=group]
df1[, n_ansd := ifelse(!is.na(max(n_ansd, na.rm=T)),max(n_ansd, na.rm=T),0), by=group]
df1[is.na(n_ansd), n_ansd := 0]

## 1.) If two different facility types, separate these out

## Create column to regroup
## Within ANSD
g1 <- df1[n_ansd>1&n_fac_type>1]  ## Split by facility type
g2 <- df1[n_ansd>1&n_fac_type==1] ## Split by Admin
g3 <- df1[n_ansd==1&n_fac_type>1]  ## Adjust facility type (?)
g4 <- df1[n_ansd==1&n_fac_type==1&n>1] ## Adjust facility type (?)
## Only in ANSD - No match
g5 <- df1[n_ansd==1&n==1]  ## Only in ANSD
## Not in ANSD
g6 <- df1[n_ansd==0&n_fac_type>1] 
g7 <- df1[n_ansd==0&n_fac_type==1] 

## Confirm rows are equal
tf <- list(g1[, set := "ANSD>1 | fac_type"], 
           g2[, set := "ANSD>1 | admin1"], 
           g3[, set := "ANSD==1 | fac_type"], 
           g4[, set := "ANSD==1 | admin1"], 
           g5[, set := "ANSD only"], 
           g6[, set := "Not ANSD | fac_type"], 
           g7[, set := "Not ANSD"]) %>% rbindlist
expect(nrow(tf)==nrow(df1), "diff rows")

export(tf, paste0(out_root, "/match_to_verify_long.xlsx"))

## Export into an excel sheet
df1 %>% setcolorder(c( "admin1", "admin2","fac_type", "group", "group_name", "fac_name2", "fac_name","source","fac_id", 
                       "fac_own", "functioning", "fac_assoc", "lat", "long", "n_gps", "max_dist", "n", "n_fac_type","match_flagged", "notes"))
export(df1, paste0(out_root, "/match_to_verify_long.xlsx"))


## Rehape on ANSD
dfa <- df1[source=="ANSD 2017-2018"]
dfn <- df1[!(source%in%c("ANSD 2017-2018"))]

## Merge
t <- merge(dfa[, .(region=admin1, district_ansd=admin2, fac_type_ansd=fac_type, fac_own_ansd=fac_own, 
                   fac_name_ansd=fac_name, match_name_ansd=fac_name2, 
                   match_group=group, match_group_name=group_name)],
           dfn[, .(match_group=group, match_group_name=group_name, match_name_matchsource=fac_name2, fac_name_matchsource=fac_name, 
                   region=admin1, district_matchsource=admin2, fac_type_matchsource=fac_type, 
                   fac_own_matchsource=fac_own, match_source=source, 
                   lat, long, n_gps, max_dist, match_flagged, n_fac_type, match_notes=notes)],
           by=c("region", "match_group", "match_group_name"), all=T)

## Cleaning
t[, match_group := as.numeric(match_group)]

t %>% setcolorder(c("region", "match_group", "match_group_name", "district_ansd", "fac_type_ansd", "fac_own_ansd", "fac_name_ansd", "match_name_ansd",
                    "match_name_matchsource", "fac_name_matchsource", "lat", "long", "n_gps", "max_dist", "match_source", "district_matchsource", "fac_type_matchsource", "fac_own_matchsource", "n_fac_type"))

export(t, paste0(out_root, "/match_to_verify.xlsx"))

## 5. INCOPORATE MANUAL VERIFICATION FROM -------------------------------------------------------------------------

df <- import(paste0(out_root, "/match_verified_long.xlsx")) %>% as.data.table

## Final processing

## Add in original id
df.id <- rbind(df.ansd, df.spa, df.cous, df.m, df.hdx, df.esri, df.moh, fill=T)[, .(fac_id, fac_id_orig)]
names <- data.table(source=c("SPA 2014", "SPA 2015", "SPA 2017", "SPA 2018", "SPA 2019", "HDX", "ANSD 2017-2018", "ESRI Kaolack"),
                    fac_id_orig_col=c("spafacid","spafacid","spafacid","spafacid","spafacid","osm_id", "HFID2015", "GlobalID" ))
df <- merge(df, df.id, by="fac_id", all.x=T)
df <- merge(df, names, by="source", all.x=T)

## Regroup - group, regroup
df <- df[order(admin1, group_name)]
df[, group := .GRP, by=.(group, regroup)]

## Reclassify facility type if specified
df[!is.na(fac_type_recode), fac_type := fac_type_recode]

## Fill facility type within a group
df[fac_type=="Health post", fac_type := "Health Post"]
df[fac_type=="Autre", fac_type := NA]
df <- df %>% group_by(admin1, group_name, regroup) %>% fill(fac_type, .direction = "downup") %>% as.data.table

## Remove non-specific facilities
df <- df[!grepl("drop|specific", match_notes)]

## Ownership
df[grepl("Pri|PRI|NGO", fac_own), fac_own := "Private"]
df[grepl("Gov|Comm", fac_own), fac_own := "Public"]
df <- df %>% group_by(group) %>% fill(fac_own, .direction = "downup") %>% as.data.table

## Remove some junk HDX facilities
df <- df[!(source=="HDX"&fac_name%in%c("administration",
                                       "conference center", 
                                       "consultation pnt",
                                       "laboratory/dental clinic",
))]


## Flags

## Flag if not in COUS, ANSD, MOH, Tambacounda
df[, any_moh := max(ifelse(grepl("ANSD|MOH|COUS|Tambacounda", source), 1, 0)), by=group]
df[, flag_not_in_moh := ifelse(any_moh==0, 1, 0)]

## Flag if large discrepancy in GPS
ids <- unique(df[!is.na(group)]$group) %>% as.numeric
q <- pblapply(ids, function(x) {
  t <- df[group==x&!is.na(lat), .(lat, long)] %>% unique
  if (nrow(t)>1) {
    perms <- combn(c(1:nrow(t)), 2) %>% t
    dists <- lapply(1:nrow(perms), function(i) {
      distHaversine(t[perms[i,1],], t[perms[i,2],])
    }) %>% unlist
    df[group==x, max_dist := round(max(dists)/1000, 2)] ## Meters to kilometers
    df[group==x, n_gps := nrow(t)]
  } else {
    df[group==x, n_gps := nrow(t)]
  }
})

df[, flag_no_gps := as.numeric(ifelse(n_gps==0, 1, 0)), by=group]

## Flag discrepant facility ownership
df[, flag_ownership := as.numeric(ifelse(length(unique(fac_own))>1, 1, 0)), by=group]

## Flag missing type
df[, flag_no_type := as.numeric(ifelse(is.na(fac_type), 1, 0)), by=group]

## Recount number of sources
df[, n_sources := length(unique(source)), by=group]

## Prepare unique -------------------------------------------------------

## Group GPS: Prioritize COUS > SPA (all other) > SPA 2017 > ESRI > Maina > HDX
sources <- c("COUS", "SPA 2016", "SPA 2015", "SPA 2014", "SPA 2017", "Maina et. al (2019)", "ESRI Kaolack", "HDX") 
source_merge <- data.table(group_gps_source=sources, best_source=1:length(sources))
df[, source_ord := factor(source, sources, sources, ordered=T) %>% as.numeric]
df[, best_source := min(source_ord[!is.na(lat)], na.rm=T), by=group]
df[source_ord==best_source, `:=` (group_lat=lat, group_long=long)]
df[, `:=` (group_lat=max(group_lat, na.rm=T), group_long=max(group_long, na.rm=T)), by=group]
df[group_lat%in%c(-Inf, 0), `:=`(group_lat=NA, group_long=NA)]
df <- merge(df, source_merge, by=c("best_source"), all.x=T)

## Columns for source list
df <- df[order(group, source)]
df[, source_list := paste0(unique(source), collapse="; "), by=group]

## Save as sheets --------------------------------------------------

## Confirm no duplicate rows
sheet2[, n := .N, group]
nrow(sheet2[n>1])
sheet2$n <- NULL
sheet2 <- sheet2 %>% arrange(admin1, group_name, group)

## Create cleaned long list
sheet1 <- df[, .(admin1, admin2, fac_type, group, group_name, source, fac_id, fac_id_orig, fac_id_orig_col, fac_name, fac_own, lat, long, decision_notes, match_flagged, match_notes, n_sources, n_gps, max_dist, flag_not_in_moh, flag_no_gps, flag_no_type, flag_ownership)]
sheet1 <- sheet1 %>% arrange(admin1, group_name, group, source)
sheet1 <- sheet1 %>% setcolorder(c("admin1", "admin2", "group", "group_name", "fac_type", "fac_name", "source", "fac_id", "fac_id_orig"))

## Fill match notes by group
sheet2 <- df[, .(admin1, group, group_name, fac_type, group_lat, group_long, group_gps_source, n_gps, max_dist, n_sources, source_list, flag_not_in_moh, flag_no_gps, flag_no_type, flag_ownership)] %>% unique


## --------------------------

## Export as excel 
out <- paste0(out_root, "/match_cleaned_20220803.xlsx")
xl_lst <- list('All Lists (Long)' = sheet1, 'Unique Facilities' = sheet2)
write.xlsx(xl_lst, file=out, rowNames=FALSE)






