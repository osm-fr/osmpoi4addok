# extract OSM POI fr;om an osm2pgsql database to json format expected by addok geocoder

psql osm -t -P pager -A -c "select format('{\"id\":\"%s_n%s\",\"type\":\"poi\",\"poi\":\"%s\",\"name\":\"%s\",\"lat\":\"%s\",\"lon\":\"%s\",\"city\":\"%s\",\"city_code\":\"%s\",\"importance\":\"%s\"}',
insee,
osm_id,
type,
case when name='' then label when unaccent(lower(name)) ~ unaccent(lower(label)) then replace(name,'\"','\\\"') else format('%s (%s)',replace(name,'\"','\\\"'),label) end,
lat::text,
lon::text,
commune,
insee,
round(((rank+score)/20)::numeric,4)
) from (select
p.osm_id,
coalesce(p.name,p.\"addr:housename\",'') as name,
coalesce(
case when p.tags ? 'iata' then 'iata_' else null end, case when p.tags ? 'aerodrome' then concat('aerodrome_',p.tags->'aerodrome') else null end,
case when p.tags ? 'mountain_pass' then concat('mountain_pass_',p.tags->'mountain_pass') else null end,
'boundary_'||p.boundary,
'military_'||p.military,
'historic_'||p.historic,
'natural_'||p.\"natural\",
'tourism_'||p.tourism,
'leisure_'||p.leisure,
'amenity_'||p.amenity,
'shop_'||p.shop,
case when p.tags ? 'craft' then concat('craft_',p.tags->'craft') else null end,
'railway_'||p.railway,
'aeroway_'||p.aeroway,
'landuse_'||p.landuse,
'waterway_'||p.waterway,
'aerialway_'||p.aerialway,
'office_'||p.office,
'bridge_'||p.bridge,
'building_'||p.building,
'man_made_'||p.man_made,
case when p.tags ? 'emergency' then concat('emergency_',p.tags->'emergency') else null end,
'tunnel_'||p.tunnel,
'highway_'||p.highway,
'barrier_'||p.barrier,
case when p.tags ? 'junction' then concat('junction_',p.tags->'junction') else null end,
'lock_'||p.lock,
'power_'||p.power,
'public_transport_'||p.public_transport,
'route_'||p.route,
'sport_'||p.sport
) as type,
round(st_x(st_transform(p.way,4326))::numeric,6) as lon,
round(st_y(st_transform(p.way,4326))::numeric,6) as lat,
c.name as commune,
c.tags->'ref:INSEE' as insee,
log((1::numeric+length(coalesce(p.tags::text,' ')))/10)+(case when p.tags ? 'wikidata' then 0.1 when p.tags ? 'wikipedia' then 0.05 else 0 end) as score
from planet_osm_point p
join planet_osm_polygon c on (st_contains(c.way, p.way))
where c.boundary='administrative' and c.admin_level in ('8') and c.tags ? 'ref:INSEE'
order by 2)
as p join poi on (type=key||'_'||coalesce(value,''))
where type is not null
AND rank>0
and (name!='' or rank>3)
order by insee, rank+score desc;
" > ../out/poi_point.json &



psql osm -t -P pager -A -c "select format('{\"id\":\"%s_w%s\",\"type\":\"poi\",\"poi\":\"%s\",\"name\":\"%s\",\"lat\":\"%s\",\"lon\":\"%s\",\"city\":\"%s\",\"city_code\":\"%s\",\"importance\": %s}',
insee,
osm_id,
type,
case when name='' then label when unaccent(lower(name)) ~ unaccent(lower(label)) then replace(name,'\"','\\\"') else format('%s (%s)',replace(name,'\"','\\\"'),label) end,
lat::text,
lon::text,
commune,
insee,
round(((rank+score)/20)::numeric,4)
) from (select
p.osm_id,
coalesce(p.name,'') as name,
coalesce(
case when p.tags ? 'mountain_pass' then concat('mountain_pass_',p.tags->'mountain_pass') else null end,
'natural_'||p.\"natural\",
'tourism_'||p.tourism,
'leisure_'||p.leisure,
'amenity_'||p.amenity,
'shop_'||p.shop,
'railway_'||p.railway,
'aeroway_'||p.aeroway,
'landuse_'||p.landuse,
/* 'waterway_'||p.waterway, */
'aerialway_'||p.aerialway,
'office_'||p.office,
'bridge_'||p.bridge,
'building_'||p.building,
'man_made_'||p.man_made,
case when p.tags ? 'emergency' then concat('emergency_',p.tags->'emergency') else null end,
'tunnel_'||p.tunnel,
/* 'highway_'||p.highway, */
'barrier_'||p.barrier,
case when p.tags ? 'junction' then concat('junction_',p.tags->'junction') else null end,
'lock_'||p.lock,
'public_transport_'||p.public_transport,
'route_'||p.route,
'sport_'||p.sport
) as type,
round(st_x(st_transform(st_line_interpolate_point(p.way,0.5),4326))::numeric,6) as lon,
round(st_y(st_transform(st_line_interpolate_point(p.way,0.5),4326))::numeric,6) as lat,
c.name as commune,
c.tags->'ref:INSEE' as insee,
log((1::numeric+length(coalesce(p.tags::text,' ')))/10)+(case when p.tags ? 'wikidata' then 0.1 when p.tags ? 'wikipedia' then 0.05 else 0 end) as score
from planet_osm_line p
join planet_osm_polygon c on (c.way && p.way and st_intersects(c.way, st_line_interpolate_point(p.way,0.5)))
where c.boundary='administrative' and c.admin_level='8' and c.tags ? 'ref:INSEE' and p.name!='') as p
join poi on (type=key||'_'||coalesce(value,''))
where osm_id>0 and type is not null and type not like '%_yes' and type not like '%_no'
AND rank>3
order by insee, rank+score desc;
" > ../out/poi_line.json &


psql osm -t -P pager -A -c "select format('{\"id\":\"%s_w%s\",\"type\":\"poi\",\"poi\":\"%s\",\"name\":\"%s\",\"lat\":\"%s\",\"lon\":\"%s\",\"city\":\"%s\",\"city_code\":\"%s\",\"importance\":\"%s\" }',
insee,
osm_id,
type,
case when name='' then label when unaccent(lower(name)) ~ unaccent(lower(label)) then replace(name,'\"','\\\"') else format('%s (%s)',replace(name,'\"','\\\"'),label) end,
lat::text,
lon::text,
commune,
insee,
round(((rank+score)/20)::numeric,4)
) from (select
p.osm_id,
coalesce(p.name,p.\"addr:housename\",'') as name,
coalesce(
case when p.tags ? 'iata' then 'iata_' else null end, case when p.tags ? 'aerodrome' then concat('aerodrome_',p.tags->'aerodrome') else null end,
case when p.tags ? 'mountain_pass' then concat('mountain_pass_',p.tags->'mountain_pass') else null end,
'boundary_'||p.boundary,
'military_'||p.military,
'historic_'||p.historic,
'natural_'||p.\"natural\",
'tourism_'||p.tourism,
'leisure_'||p.leisure,
'amenity_'||p.amenity,
'shop_'||p.shop,
case when p.tags ? 'craft' then concat('craft_',p.tags->'craft') else null end,
'railway_'||p.railway,
'aeroway_'||p.aeroway,
'landuse_'||p.landuse,
'waterway_'||p.waterway,
'aerialway_'||p.aerialway,
'office_'||p.office,
'bridge_'||p.bridge,
'building_'||p.building,
'man_made_'||p.man_made,
case when p.tags ? 'emergency' then concat('emergency_',p.tags->'emergency') else null end,
'tunnel_'||p.tunnel,
'highway_'||p.highway,
'barrier_'||p.barrier,
case when p.tags ? 'junction' then concat('junction_',p.tags->'junction') else null end,
'lock_'||p.lock,
'power_'||p.power,
'public_transport_'||p.public_transport,
'route_'||p.route,
'sport_'||p.sport
) as type,
round(st_x(st_transform(st_centroid(p.way),4326))::numeric,6) as lon,
round(st_y(st_transform(st_centroid(p.way),4326))::numeric,6) as lat,
c.name as commune,
c.tags->'ref:INSEE' as insee,
log((1::numeric+length(coalesce(p.tags::text,' ')))/10)+(case when p.tags ? 'wikidata' then 0.1 when p.tags ? 'wikipedia' then 0.05 else 0 end) as score
from planet_osm_polygon p
join planet_osm_polygon c on (c.way && p.way and st_intersects(c.way, st_centroid(p.way)))
where c.boundary='administrative' and c.admin_level='8' and c.tags ? 'ref:INSEE' and p.osm_id>0) as p
join poi on (type=key||'_'||coalesce(value,''))
where type is not null
AND rank>0
and (name!='' or rank>3)
order by insee, rank+score desc;
" > ../out/poi_polygon.json &

