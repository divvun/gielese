. env/bin/activate

rm data/*.json
python manage.py init_db
python manage.py install_media -f ../data/xml/heelsedh.xml
python manage.py install_media -f ../data/xml/beapmoeh.xml
python manage.py install_media -f ../data/xml/nature.animals.xml
python manage.py install_media -f ../data/xml/nature.world.xml
python manage.py install_media -f ../data/xml/phrases.xml
python manage.py install_media -f ../data/new_process.xml
python manage.py prepare_json

