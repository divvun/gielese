. env/bin/activate

python manage.py init_db
python manage.py install_media -f ../data/sma_media.xml
python manage.py install_media -f ../data/heelsedh.xml
python manage.py install_media -f ../data/beapmoeh.xml
python manage.py install_media -f ../data/nature.animals.xml
python manage.py install_media -f ../data/nature.world.xml
python manage.py install_media -f ../data/phrases.xml
python manage.py append_lexical_data -f ../data/n_smanob_test.xml
python manage.py prepare_json

