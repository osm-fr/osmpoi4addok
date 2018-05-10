# download
wget -nc http://download.geonames.org/export/dump/FR.zip
# décompression
unzip -o FR.zip

# import
psql -c "drop table if exists geonames; create table geonames (id text, name text, asciiname text, alt_name text, latitude numeric, longitude numeric, class text, code text, country text, cc2 text, admin1 text, admin2 text, admin3 text, admin4 text, population numeric, elevation numeric, dem numeric, timezone text, last_update date);"
psql -c "\copy geonames from FR.txt with (format csv, delimiter E'\t', quote '^')"
psql -c "ALTER TABLE geonames ADD geom geometry; UPDATE geonames SET geom = ST_Makepoint(longitude, latitude);"
psql -c "CREATE INDEX on geonames using gist(geom);"

# import code / labels
psql -c "drop table if exists geonames_codes; create table geonames_codes (class text, code text, nb numeric, label text);"
psql -c "\copy geonames_codes from class_codes.csv with (format csv, header true)"

AAAAMM=$(date +%Y-%m)

psql -tAc "
SELECT
  row_to_json(t)
FROM (
  select 'gn'||g.id as id,
    string_to_array(regexp_replace(format('%s,%s',trim(regexp_replace(g.name,'(.*),(.*)','\2 \1')), regexp_replace(g.alt_name,'([^,]*)  ([^,]*)','\2 \1','g')),',$',''),',') as name,
    'poi' as type,
    'Geonames $AAAAMM CC-BY' as source,
    g.code as poi,
    latitude as lat,
    longitude as lon,
    format('%s, %s, %s',label,nomdep, nomreg) as context,
    nom as city,
    insee as citycode
  from geonames g
  join geonames_codes c on c.code=g.code
  join communes_20180101 o on (st_intersects(st_setsrid(st_makepoint(longitude, latitude),4326),o.wkb_geometry))
  join cog on depcom=insee
  where label != ''
) AS t" > geonames2addok.json


psql -tAc "
SELECT
  row_to_json(t)
FROM (
  select 'gn'||g.id as id,
    string_to_array(regexp_replace(format('%s,%s',trim(regexp_replace(g.name,'(.*),(.*)','\2 \1')), regexp_replace(g.alt_name,'([^,]*)  ([^,]*)','\2 \1','g')),',$',''),',') as name,
    'poi' as type,
    'Geonames $AAAAMM CC-BY' as source,
    g.code as poi,
    latitude as lat,
    longitude as lon,
    format('%s, %s, %s',label,nomdep, nomreg) as context,
    nom as city,
    insee as citycode
  from geonames g
  left join poi p on (ST_DWithin(p.geom, g.geom, 0.001) AND unaccent(p.name) <-> unaccent(g.name) > 0.2 )
  join geonames_codes c on c.code=g.code
  join communes_20180101 o on (st_intersects(st_setsrid(st_makepoint(longitude, latitude),4326),o.wkb_geometry))
  join cog on depcom=insee
  where label != '' and p.name is null
) AS t" > geonames2addok_dedup.json
