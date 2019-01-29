. env/bin/activate

rm data/*.json

python read_media_directory.py read categories \
    static/media/ \
    --output=JSON \
    --relative-paths > data/categories.json

python read_media_directory.py read concepts \
    static/media/ \
    --output=XML \
    --relative-paths > data/concepts.tmp.xml

# Unfortunate requirement because manage.py handles arguments in an odd way

MEDIA_SERV_CONF_PATH=gielese.app.config.yaml python manage.py init_db
MEDIA_SERV_CONF_PATH=gielese.app.config.yaml python manage.py install_media -f data/concepts.tmp.xml
MEDIA_SERV_CONF_PATH=gielese.app.config.yaml python manage.py prepare_json

rm data/concepts.tmp.xml
