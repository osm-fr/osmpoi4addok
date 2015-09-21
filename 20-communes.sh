URL=http://osm13.openstreetmap.fr/~cquest/openfla/export/communes-20150101-5m-shp.zip
[ -f communes-20150101-5m-shp.zip ] || wget $URL && unzip communes-20150101-5m-shp.zip
shp2pgsql -d communes-20150101-5m.shp > communes.sql
rm communes-20150101-5m.* LICENCE.txt communes-descriptif.txt
psql < communes.sql
psql -c 'CREATE INDEX idx_com_geom ON "communes-20150101-5m" USING gist(geom);'
