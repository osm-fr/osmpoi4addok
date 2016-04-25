psql < poi.sql
tail -n +2 poi.csv | psql -c "COPY poi FROM STDIN WITH NULL ''"

psql -c "SELECT AddGeometryColumn ('public','poi','geom',0,'POINT',2);"
psql -c "UPDATE poi SET geom = ST_MakePoint(lon, lat);"
psql -c "CREATE INDEX idx_poi_geom ON poi USING gist(geom);"

psql < poi2addok.sql
