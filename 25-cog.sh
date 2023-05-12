ANNEE=2023
ID=6800675
wget -nc https://insee.fr/fr/statistiques/fichier/$ID/v_commune_$ANNEE.csv
wget -nc https://insee.fr/fr/statistiques/fichier/$ID/v_departement_$ANNEE.csv
wget -nc https://insee.fr/fr/statistiques/fichier/$ID/v_region_$ANNEE.csv

psql -c "drop table if exists cog_com cascade; create table cog_com (TYPECOM text,COM text,REG text,DEP text,CTCD text,ARR text,TNCC text,NCC text,NCCENR text,LIBELLE text,CAN text,COMPARENT text);"
psql -c "\copy cog_com from v_commune_${ANNEE}.csv with (format csv, header true, delimiter ',', encoding 'utf-8')"
psql -c "create index on cog_com (com);"

psql -c "drop table if exists cog_dep; create table cog_dep (REG text, DEP text,CHEFLIEU text,TNCC text,NCC text,NCCENR text,LIBELLE text);"
psql -c "\copy cog_dep from v_departement_${ANNEE}.csv with (format csv, header true, delimiter ',', encoding 'utf-8')"

psql -c "drop table if exists cog_reg; create table cog_reg (REG text, CHEFLIEU text,TNCC text,NCC text,NCCENR text,LIBELLE text);"
psql -c "\copy cog_reg from v_region_${ANNEE}.csv with (format csv, header true, delimiter ',', encoding 'utf-8')"

psql -c "create view cog as (select c.com, d.dep, c.libelle as nomcom, d.libelle as nomdep, r.libelle as nomreg from cog_com c join cog_dep d on (c.dep=d.dep) join cog_reg r on (r.reg=d.reg) where c.typecom='COM');"
