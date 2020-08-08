CREATE TEMP TABLE poi_tag AS
SELECT
  id::numeric,
  lat,
  lon,
  bbox,
  coalesce('aerialway='||aerialway, 'aerodrome='||aerodrome, 'aeroway='||aeroway, 'amenity='||amenity, 'boundary='||boundary, 'bridge='||bridge, 'craft='||craft, 'emergency='||emergency, 'heritage='||heritage, 'highway='||highway, 'historic='||historic, 'junction='||junction, 'landuse='||landuse, 'leisure='||leisure, 'man_made='||man_made, 'military='||military, 'mountain_pass='||mountain_pass, 'natural='||"natural", 'office='||office, 'place='||place, 'railway='||railway, 'shop='||shop, 'tourism='||tourism, 'tunnel='||tunnel, 'waterway='||waterway) AS tag,
  regexp_replace(regexp_replace(format('%s;%s;%s;%s;%s;%s;%s',name, alt_name, short_name, official_name, local_name, name_fr, old_name),'(; )|(;;*)',';','g'),';$','') as name,
  insee AS citycode,
  c.nom AS city,
  format('%s, %s', nomdep, nomreg) as context
FROM
  poi
  LEFT JOIN com AS c ON
    ST_Intersects(poi.geom, c.geom)
  LEFT JOIN cog ON
    depcom = c.insee
;

CREATE INDEX idx_def_tag ON def((key1 || '=' || value1));


\pset tuples_only
\a
\o poi.json
SELECT
  row_to_json(t)
FROM (
  SELECT
    format('https://osm.org/%s/%s',case when id<1000000000000000 then 'node' when id>2000000000000000 then 'relation' else 'way' end, id % 1000000000000000) as id,
    'poi' AS type,
    value1 AS poi,
    (SELECT array_agg(case
      when lower(unaccent(n)) like '%'||lower(unaccent(trim(v)))||'%' then n
      when n is null then trim(v)
      else trim(format('%s (%s)',coalesce(n,''),trim(v))) end)
      FROM unnest(case when name='' then array[''] else string_to_array(name,';') end ) as n, unnest(regexp_split_to_array(label, ' / ')) AS t(v)) AS name,
    lat,
    lon,
    city,
    citycode,
    context,
    rank::numeric/10 + coalesce(log(0.00001+sqrt(st_area(st_expand(ST_LineFromText(regexp_replace(bbox, '(.*),(.*),(.*),(.*)','LINESTRING(\1 \2,\3 \4)')),0)::geography)))/100,0) AS importance
  FROM
    poi_tag
    JOIN def ON
      tag = key1 || '=' || value1
  WHERE
    rank IS NOT NULL AND
    rank != '0'
) AS t
;
\o
