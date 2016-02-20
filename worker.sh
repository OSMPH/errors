#!/usr/bin/env bash

DATA=/path/to/data
PublicData=path/to/public/url
webhook=https://hooks.slack.com/services/add/webhook/key
bbox=$1

echo "# Downloading planet..."
wget -O $DATA/philippines.mbtiles.gz https://s3.amazonaws.com/mapbox/osm-qa-tiles/latest.country/philippines.mbtiles.gz

echo "# Extracting planet..."
gunzip -f $DATA/philippines.mbtiles.gz

echo "# Looking for missing layers on bridges..."
osmlint missinglayerbridges  --bbox=$bbox $DATA/philippines.mbtiles > $DATA/missinglayerbridges.json

echo "# Looking for untagged ways..."
osmlint untaggedways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/untaggedways.json

echo "# Looking for bridges on a node..."
osmlint bridgeonnode --bbox=$bbox $DATA/philippines.mbtiles > $DATA/bridgeonnode.json

echo "# Looking for unclosed ways..."
osmlint unclosedways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/unclosedways.json

echo "# Looking for self-intersecting highways..."
osmlint selfintersectinghighways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/selfintersectingways.json

echo "# Looking for crossing highways..."
osmlint crossinghighways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/crossinghighways.json

echo "# Looking for crossing highways and waterways ..."
osmlint crossingwaterwayshighways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/crossingwaterwayshighways.json

echo "# Looking for node ending near highways..."
osmlint nodeendingnearhighway --bbox=$bbox $DATA/philippines.mbtiles > $DATA/nodeendingnearhighway.json

echo "# Looking for node unconnected highways..."
osmlint unconnectedhighways --bbox=$bbox $DATA/philippines.mbtiles > $DATA/unconnectedhighways.json

echo "# Merging results..."
python utils/merge-geojson.py $DATA/bridgeonnode.json > $DATA/bridgeonnode.final.json
python utils/merge-geojson.py $DATA/untaggedways.json > $DATA/untaggedways.final.json
python utils/merge-geojson.py $DATA/missinglayerbridges.json > $DATA/missinglayerbridges.final.json
python utils/merge-geojson.py $DATA/selfintersectingways.json > $DATA/selfintersectingways.final.json
python utils/merge-geojson.py $DATA/unclosedways.json > $DATA/unclosedways.final.json
python utils/merge-geojson.py $DATA/crossingwaterwayshighways.json > $DATA/crossingwaterwayshighways.final.json
python utils/merge-geojson.py $DATA/nodeendingnearhighway.json > $DATA/nodeendingnearhighway.final.json
python utils/merge-geojson.py $DATA/crossinghighways.json > $DATA/crossinghighways.final.json
python utils/merge-geojson.py $DATA/unconnectedhighways.json > $DATA/unconnectedhighways.final.json


geojson-merge $DATA/bridgeonnode.final.json $DATA/missinglayerbridges.final.json $DATA/selfintersectingways.final.json \
	      $DATA/unclosedways.final.json $DATA/crossinghighways.final.json $DATA/nodeendingnearhighway.final.json $DATA/unconnectedhighways.final.json > $DATA/results.json


geojson-josm-url $DATA/results.json > $DATA//results.json 


echo "# Posting to slack ..."

count="$(jq '.features |length' $DATA/results.json)"
url="http://osmph.github.io/errors/"

curl -X POST --data-urlencode 'payload={"channel": "#general", "username": "errors", "text": "'$count' errors today at '$url'", "icon_emoji": ":mag:"}' $webhook
