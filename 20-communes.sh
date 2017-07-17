COMMUNES=communes-20170112
URL=http://osm13.openstreetmap.fr/~cquest/openfla/export/$COMMUNES-shp.zip
[ -f $COMMUNES-shp.zip ] || wget $URL && unzip $COMMUNES-shp.zip
psql -c "DROP TABLE IF EXISTS com;"
shp2pgsql -d $COMMUNES.shp | psql -q
psql -c "ALTER TABLE \"$COMMUNES\" RENAME TO com;"
psql -c "CREATE INDEX idx_com_geom ON com USING gist(geom);"
rm $COMMUNES.* LICENCE.txt communes-descriptif.txt

