ANNEE=2018
wget -nc https://insee.fr/fr/statistiques/fichier/3363419/comsimp$ANNEE-txt.zip
wget -nc https://insee.fr/fr/statistiques/fichier/3363419/depts$ANNEE-txt.zip
wget -nc https://insee.fr/fr/statistiques/fichier/3363419/reg$ANNEE-txt.zip
unzip -o comsimp2018-txt.zip
unzip -o depts2018-txt.zip
unzip -o reg2018-txt.zip

psql -c "drop table if exists cog_com cascade; create table cog_com (CDC text,CHEFLIEU text,REG text,DEP text,COM text,AR text,CT text,TNCC text,ARTMAJ text,NCC text,ARTMIN text,NCCENR text);"
psql -c "\copy cog_com from comsimp2018.txt with (format csv, header true, delimiter E'\t', encoding 'iso8859-1')"
psql -c "alter table cog_com add depcom text; update cog_com set depcom = dep||com; create index on cog_com (depcom);"

psql -c "drop table if exists cog_dep; create table cog_dep (REGION text, DEP text,CHEFLIEU text,TNCC text,NCC text,NCCENR text);"
psql -c "\copy cog_dep from depts2018.txt with (format csv, header true, delimiter E'\t', encoding 'iso8859-1')"

psql -c "drop table if exists cog_reg; create table cog_reg (REGION text, CHEFLIEU text,TNCC text,NCC text,NCCENR text);"
psql -c "\copy cog_reg from reg2018.txt with (format csv, header true, delimiter E'\t', encoding 'iso8859-1')"

psql -c "create view cog as (select c.depcom, d.dep, c.nccenr as nomcom, d.nccenr as nomdep, r.nccenr as nomreg from cog_com c join cog_dep d on (c.dep=d.dep) join cog_reg r on (r.region=d.region));"
