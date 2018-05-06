#!/bin/sh
mkdir border
cd border

# https://wambachers-osm.website/boundaries/
i=1
for iso in `cat ../iso.txt`; do
  file="border_$iso.zip"
  if [ ! -f $file ]; then
    echo "Downloading border #$i ($iso)"
    curl -f -o $file -# --url "https://wambachers-osm.website/boundaries/exportBoundaries?cliVersion=1.0&cliKey=12bba76b-e8a4-49ed-8614-4d0445bab178&exportFormat=shp&exportLayout=levels&exportAreas=water&union=false&selected=$iso"
    tar -xf "$file"
  fi
  i=$((i+1))
done

# merge and strip
if [ ! -f "../communities.shp" ]; then
  ogrmerge.py -single -lco ENCODING=UTF-8 -o ../communities.shp *.shp
fi
cd ..

if [ ! -f "communities.json" ]; then
  ogr2ogr -f GeoJSON -sql "select communities.country as country, communities.name as name, communities.locname as locname, ne.MAPCOLOR7 as color7 from communities left join 'admin-fixed.json'.ne_110m_admin_0_countries ne ON communities.country = ne.ISO_A3" communities.json communities.shp
fi

# maximum-zoom=g makes things very blurry, so hardcode instead
tippecanoe --maximum-zoom=10 --no-tile-compression --output-to-directory=. communities.json
