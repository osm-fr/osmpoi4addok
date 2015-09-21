CREATE TEMP TABLE poi_tag AS
SELECT
  id,
  lat,
  lon,
  coalesce('aerialway='||aerialway, 'aerodrome='||aerodrome, 'aeroway='||aeroway, 'amenity='||amenity, 'boundary='||boundary, 'bridge='||bridge, 'craft='||craft, 'emergency='||emergency, 'heritage='||heritage, 'highway='||highway, 'historic='||historic, 'junction='||junction, 'landuse='||landuse, 'leisure='||leisure, 'man_made='||man_made, 'military='||military, 'mountain_pass='||mountain_pass, 'natural='||"natural", 'office='||office, 'place='||place, 'railway='||railway, 'shop='||shop, 'tourism='||tourism, 'tunnel='||tunnel, 'waterway='||waterway) AS tag,
  name,
  insee AS city_code,
  c.nom AS city
FROM
  poi
  JOIN "communes-20150101-5m" AS c ON
    ST_Intersects(poi.geom, c.geom)
;

CREATE INDEX idx_def_tag ON def((key1 || '=' || value1));


\pset tuples_only
\a
\o poi.json
SELECT
  row_to_json(t)
FROM (
  SELECT
    id,
    'poi' AS type,
    value1 AS poi,
    (SELECT array_agg(trim(v) || coalesce(' ' || name, '')) FROM unnest(regexp_split_to_array(label, ' / ')) AS t(v)) AS name,
    lat,
    lon,
    city,
    city_code,
    rank AS importance
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
