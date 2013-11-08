. env/bin/activate

rm data/*.json

python read_media_directory.py read categories static/media/ --output=JSON --server-media-uri=/ > data/categories.json
python read_media_directory.py read concepts static/media/ --output=XML --server-media-uri=/ > data/concepts.tmp.xml

python manage.py init_db
python manage.py install_media -f ../data/xml/nature.animals.xml
python manage.py install_media -f ../data/xml/nature.world.xml
python manage.py install_media -f data/concepts.tmp.xml
rm data/concepts.tmp.xml
python manage.py prepare_json
