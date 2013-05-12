mv media_serv.db media_serv.bak
python manage.py init_db
python manage.py install_media -f ../data/sma_media.xml
python manage.py append_lexical_data -f ../data/n_smanob_test.xml
