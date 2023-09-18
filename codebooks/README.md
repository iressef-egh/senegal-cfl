## Liste consolidée des établissements  
_Pour la description en anglais, voir ci-dessous. (For the description in English, please see below.)_

**données**: senegal_consolidated_facilitylist.xlsx
- **region:** région au Sénégal.  
- **match_id:** identifiant (id) d'établissement attribué à chaque regroupement d'établissements distincts dans la liste consolidée des établissements. L'identifiant relie les observations distinctes trouvées dans cet ensemble de données à la version 'complète' de cet ensemble de données, dans lequel tous les établissements d'un "match_id" précis ont été mis en correspondance dans des groupes de correspondance.  
    - _Remarque:_ cet id ne correspond pas à une source de données particulière ou à un système d'informations médicales formel (par ex., le DHIS2).  
- **match_name:** il s'agit de la version traitée du nom de l'établissement de santé utilisé pour la mise en correspondance, à l'exclusion des caractères spéciaux et des variations rencontrées entre les sources. Les noms d'origine des établissements, tels qu'ils sont inclus par source, se trouvent sous  “fac_name_orig” dans l'ensemble de données “senegal_full_facilitylist.xlsx”. 
- **group_fac_type:** il s'agit du type d'établissement attribué à une observation d'établissement distincte. Les types d'établissements d'origine peuvent varier en fonction de la source, ils sont listés sous  “fac_type_orig” dans l'ensemble de données “senegal_full_facilitylist.xlsx” dataset. Les types d'établissements suivants sont inclus en français dans cet ensemble de données (sans caractères spéciaux), avec les traductions en anglais:  
    - hopital = hospital
    - centre de sante = health center
    - poste de sante = health post
    - case de sante = health hut
    - autre = other
- **group_latitude:** coordonnées de latitude attribuées.  
- **group_longitude:** assigned longitude coordinates.
- **group_gps_source:** coordonnées de longitude attribuées.  
- **n_gps:** nombre de sources reliées aux coordonnées GPS pour une observation d'établissement distincte.  
- **n_source:** nombre de sources reliées pour une observation d'établissement distincte.  
- **source_list:** liste des sources pour une observation d'établissement distincte.  
- **data_flagged:** variable dans laquelle "1" indique les besoins de vérification ou les questions de suivi en suspens. 
- **data_notes:** autres détails sur les besoins d'une vérification ou les questions de suivi en suspens concernant l'établissement précis. _Toutes les notes sont pour l'heure en anglais._  

## Liste complète des établissements   
**données:** senegal_full_facilitylist.xlsx
- **region:** région au Sénégal.  
- **department:** unité ou subdivision administrative au sein des 14 Régions duSénégal, avec n = 45.  
   - _Remarque:_ le signalement des départements ou des districts de santé variait dans les sources de données (qui ne précisaient pas toujours ceux qui étaient inclus). Les informations sur les départements étaient cartographiées et les inexactitudes comptabilisées, mais certaines observations sur l'établissement/la source peuvent ne pas inclure un département.  
- **health_district:** niveau périphérique du secteur sanitaire du Sénégal, avec n = 77 à 79.   
   - _Remarque:_ le signalement des départements ou des districts sanitairevariait dans les sources de données (qui ne précisaient pas toujours ceux qui étaient inclus). La cartographie du district au département et la comptabilisation étaient effectuées si possible, mais certaines observations établissement-source peuvent ne pas avoir de district sanitaire.  
- **match_id:** identifiant (id) d'établissement attribué à chaque regroupement d'établissements distincts dans la liste consolidée des établissements. L'identifiant relie les groupes d'établissements dans cet ensemble de données aux observations distinctes trouvées dans la liste consolidée des établissements.  
    - _Remarque:_ cet id ne correspond pas à une source de données particulière ou à un système d'informations médicales formel (par ex., le DHIS2).  
- **match_name:** version traitée du nom de l'établissement de santé utilisé pour la mise en correspondance, à l'exclusion des caractères spéciaux et des variations rencontrées entre les sources.  
- **fac_name_orig:** nom d'origine de l'établissement de santé, tel qu'il est inclus dans une source précise de données.  
- **group_fac_type:** il s'agit du type d'établissement attribué à une observation d'établissement distincte. Les types d'établissements d'origine peuvent varier en fonction de la source, ils sont listés sous  “fac_type_orig.” Les types d'établissements suivants sont inclus en français dans cet ensemble de données (sans caractères spéciaux), avec les traductions en anglais:
   - hopital = hospital
   - hentre de sante = health center
   - poste de sante = health post
   - case de sante = health hut
   - autre = other
- **fac_type_orig:** type d'origine de l'établissement, tels qu'il est inclus dans une source précise de données.
- **group_fac_own:** version traitée de l'autorité de gestion d'un établissement précis. Les types suivants sont inclus en français dans cet ensemble de données (sans caractères spéciaux), avec les traductions en anglais:
   - publique = public
   - prive = private
   - ong ou mission/confessionnel = NGO or mission/faith-based
   - paramilitaire = paramilitary
- **fac_own_orig**: autorité de gestion de l'établissement de santé, telle qu'elle est incluse dans une source précise de données.
- **latitude:** coordonnées de latitude, telles qu'elles sont incluses dans une source précise de données.
- **longitude:** coordonnées de longitude, telles qu'elles sont incluses dans une source précise de données.
- **max_gps_dist:** distance d'Haversine maximum en kilomètres entre des coordonnées GPS pour chaque regroupement d'établissements distinct. Si un établissement n'a qu'un ensemble de coordonnées GPS (n_gps==1), cette variable est vide. 
- **source:** source des données sur l'établissement.
- **data_flagged:** variable dans laquelle “1” indique les besoins de vérification ou les questions de suivi en suspens.
- **data_notes:** utres détails sur les besoins d'une vérification ou les questions de suivi en suspens concernant l'établissement précis. _Toutes les notes sont pour le moment en anglais._
   - Si des informations figurent dans “data_notes” mais que l'établissement n'est pas identifié (data_flagged==1), ces notes sont destinées à fournir des détails ou des informations supplémentaires sur un établissement précis sans éléments d'action immédiate ni suivi.
- **decision_notes:** détails supplémentaires sur les décisions prises pour les établissements mis en correspondance et feedback des points focaux régionaux. _Toutes les notes sont pour l'heure en anglais._
- **last_updated:** date de la dernière mise à jour au format AAAAMMJJ. Par exemple : 20230518 correspond au 18 mai 2023.
   - Ces mises à jour sont destinées à refléter les modifications apportées aux précédentes correspondances des établissements depuis l'atelier portant sur les listes des établissements de Dakar, qui s'est tenu du 31 janvier au 1er février 2023.
- **update_notes:** détails supplémentaires sur les mises à jour intervenues pour une observation d'établissement distincte. _Toutes les notes sont pour le moment en  anglais._
- **n_gps:** nombre de sources reliées aux coordonnées GPS pour chaque groupe d'établissements mis en correspondance.
- **n_source:** nombre de sources reliées pour chaque groupe d'établissements mis en correspondance.
- **source_list:** liste des sources pour chaque groupe d'établissements mis en correspondance.
- **fac_id:** id unique d'établissement, soit directement fourni par la source de données d'origine, soit généré afin de fournir un identifiant unique pour chaque observation d'établissement.
- **fac_id_orig:** id d'origine de l'établissement, tel qu'il est inclus dans une source précise de données des établissements.   
   - _Remarque:_ la plupart des sources de données non issues d'enquêtes n'avaient pas d'id d'établissement d'origine, par conséquent, cette variable est vide.
- **fac_id_orig_var:** nom de la variable contenant les ids d'établissements, tels qu'ils sont trouvés dans une source précise de données des établissements.
   - _Remarque:_ la plupart des sources de données non issues d'enquêtes n'avaient pas d'id d'établissement d'origine, par conséquent, cette variable est vide.  
- **n_geos:** nombre de combinaisons département-district de santé au sein d'un groupe d'établissements mis en correspondance. Cette variable a été incluse pour identifier plus facilement les établissements mis en correspondance qui:
   - Si n_geos==0, alors aucune information sur le département ou le district sanitairen'est incluse pour ces établissements.
   - Si n_geos==1, des combinaisons département-district de santé existent et sont cohérentes pour un groupe d'établissements mis en correspondance.
   - Si n_geos >1, les combinaisons département-district de santé varient au sein d'un groupe d'établissements mis en correspondance et une vérification supplémentaire est nécessaire.


## Consolidated facility list  
_Pour la description en français, voir ci-dessus. (For the description in French, please see above.)_  

**data**: senegal_consolidated_facilitylist.xlsx
- **region:** region in Senegal.
- **match_id:** facility id assigned for each unique facility grouping identified in the consolidated facility list. This identifier links the unique observations found in this dataset to the ‘full’ version of this dataset where all facilities for a given match_id have been matched into match groups.
    - _Note_: this id does not correspond with a particular data source or formal health information system (e.g., DHIS2).
- **match_name:** this is the processed version of health facility name used for matching, excluding special characters and variations found across sources. Original facility names, as included by source, can be found under “fac_name_orig” in the “senegal_full_facilitylist.xlsx” dataset. 
- **group_fac_type:** this is the facility type assigned to a unique facility observation. Original facility types may vary by source, of which are listed under “fac_type_orig” in the “senegal_full_facilitylist.xlsx” dataset. Facility types included in this dataset are as follows in French (without special characters), with English translations:
    - hopital = hospital
    - centre de sante = health center
    - poste de sante = health post
    - case de sante = health hut
    - autre = other
- **group_latitude:** assigned latitude coordinates.
- **group_longitude:** assigned longitude coordinates.
- **group_gps_source:** source of assigned facility GPS.
- **n_gps:** number of linked sources with GPS for a unique facility observation.
- **n_source:** number of linked sources for a unique facility observation.
- **source_list:** list of sources for a unique facility observation.
- **data_flagged:** variable whereby “1” indicates outstanding verification needs or follow-up questions.
- **data_notes:** further detail about outstanding verification needs or follow-up questions about the given facility. _All notes are in English at present._

## Full facility list 
**data:** senegal_full_facilitylist.xlsx
- **region:** region in Senegal.
- **department:** formal second-level administrative unit for Senegal, with n=45.
   - _Note_: Data sources varied in their reporting of departments or health districts (and did not always specify which was included). Mapping capturing department information and accounting for inaccuracies occurred where possible, but some facility-source observations may not have a department included.
- **health_district:** the peripheral level of Senegal’s health sector, with an n=77 to 79. 
   - _Note_: Data sources varied in their reporting of departments or health districts (and did not always specify which was included). Mapping from district to department and accounting occurred where possible, but some facility-source observations may not have a health district included. 
- **match_id:** facility id assigned for each unique facility grouping identified in the consolidated facility list. This identifier links facility groups in this dataset to unique observations found in the consolidated facility list.
   - _Note_: this id does not correspond with a particular data source or formal health information system (e.g., DHIS2).
- **match_name:** processed version of the health facility name used for matching, excluding special characters, variations found across sources.
- **fac_name_orig:** original health facility name, as found in a given facility data source. 
- **group_fac_type:** this is the facility type assigned to a unique facility observation. Original facility types may vary by source, of which are listed under “fac_type_orig.” Facility types included in this dataset are as follows in French (without special characters), with English translations:
   - hopital = hospital
   - hentre de sante = health center
   - poste de sante = health post
   - case de sante = health hut
   - autre = other
- **fac_type_orig:** original facility type, as provided in a given facility data source.
- **group_fac_own:** processed version of the managing authority for a given facility. Types included in this dataset are as follows in French (without special characters), with English translations:
   - publique = public
   - prive = private
   - ong ou mission/confessionnel = NGO or mission/faith-based
   - paramilitaire = paramilitary
- **fac_own_orig**: managing authority for the health facility, as provided in a given facility data source.
- **latitude:** latitude coordinates, as provided in a given data source.
- **longitude:** longitude coordinates, as provided in a given data source.
- **max_gps_dist:** maximum Haversine distance in kilometers between GPS coordinates for each unique facility grouping. If a facility has only set of GPS coordinates (n_gps==1), this variable is blank. 
- **source:** facility data source.
- **data_flagged:** variable whereby “1” indicates outstanding verification needs or follow-up questions.
- **data_notes:** further detail about outstanding verification needs or follow-up questions about the given facility. _All notes are in English at present._
   - If there is information in “data_notes” but the facility is not flagged (data_flagged==1), these notes are meant to provide additional detail or information about a given facility without immediate action items or follow-up.
- **decision_notes:** further detail about decisions made for matching facilities and feedback from regional focal points. _All notes are in English at present._
- **last_updated:** date of last update in YYYYMMDD format. For instance, 20230518 is 18 May 2023.
   - These updates are meant to reflect changes to previous facility matches since the Dakar facility list workshop that occurred from 31 January to 1 February 2023.
- **update_notes:** further detail on the updates that occurred for a unique facility observation. _All notes are in English at present._
- **n_gps:** number of linked sources with GPS for each matched facility group.
- **n_source:** number of linked sources for each matched facility group.
- **source_list:** list of sources for each matched facility group.
- **fac_id:** unique facility id, either directly provided from its original data source or generated in order to provide a unique identifier for each facility observation.
- **fac_id_orig:** original facility id, as provided in a given facility data source. 
   - _Note_: most non-survey data sources did not have an original facility id, and thus this variable is blank for them.
- **fac_id_orig_var:** variable name in which facility ids are contained, as found in a given facility data source.
   - _Note_: most non-survey data sources did not have an original facility id, and thus this variable is blank for them.
- **n_geos:** number of department-health district combinations within a matched facility group. This variable was included to more easily identify which matched facilities need further geographic variation, such that:
   - If n_geos==0, then no department or health district information were included for these facilities.
   - If n_geos==1, department-health district combinations for a matched facility group exist and are consistent.
   - If n_geos >1, department-health district combinations vary within a matched facility group and further verification is needed.

