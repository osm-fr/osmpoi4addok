# osmpoi4addok
OSM POI for addok geocoder

This serie of scripts extract and convert OSM POI from a PBF file into json format expected by addok geocoder.

def.csv contain the list of POI to extract + their translation + their rank.

Requires:
* postgresql + postgis
* osmconvert and osmfilter (apt install osmctools)

Extracted data for France is available at: http://osm13.openstreetmap.fr/~cquest/osm_poi/

