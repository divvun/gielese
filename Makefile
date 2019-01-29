media_serv_deps:
	cd media-serv && virtualenv env && source ./env/bin/activate && pip install -r requirements.txt

copy_json_data:
	cd media_serv && source ./env/bin/activate && python deploy_media_directory.py copy json \
		data \
		../sma-client/phonegap/gielese/www/data

copy_media_tablet:
	cd media_serv && source ./env/bin/activate && python deploy_media_directory.py copy media \
		static/media \
		../sma-client/phonegap/gielese/www/static/media \
		--strip-formats=original,orig,small \
		--keep-orphan-formats

copy_media_mobile:
	source env/bin/activate && python deploy_media_directory.py copy media \
		media-serv/static/media \
		sma-client/phonegap/gielese/www/static/media \
		--strip-formats=original,orig,medium \
		--keep-orphan-formats


prepare-for-phonegap: copy_json_data \
					  copy_media_mobile

