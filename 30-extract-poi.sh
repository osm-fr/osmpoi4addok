PBF=http://download.geofabrik.de/europe/france-latest.osm.pbf
[ -f france-latest.osm.pbf ] || wget $PBF

FILTER="`tail -n +2 def.csv | cut -d ',' -f 1,2,3 | sort | sed -e 's/\([-_a-z0-9]\+\),\([-_a-z0-9]\+\),\([-_a-z0-9]*\)/( \1=\2 and \3= ) or/' | tr '\n' ' ' | sed -e 's/ and =//g' | sed -e 's/ or \$//'`"
osmconvert france-latest.osm.pbf -o=france-latest.o5m
osmfilter france-latest.o5m --keep="$FILTER" -o=france-poi.o5m
osmconvert france-poi.o5m --all-to-nodes --add-bbox-tags --max-objects=1000000000 -o=france-poi-all-to-nodes.o5m
osmfilter france-poi-all-to-nodes.o5m --keep="$FILTER" -o=france-poi-bbox.o5m
KEY="`tail -n +2 def.csv | cut -d ',' -f 1 | sort -u | tr '\n' ' '`"
osmconvert france-poi-bbox.o5m --csv="@id @lon @lat bBox name alt_name short_name name:fr local_name official_name old_name $KEY" --csv-headline > poi.csv
