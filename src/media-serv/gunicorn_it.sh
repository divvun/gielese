gunicorn -w 4 -b 127.0.0.1:5000 media_serv:app --log-level info --access-logfile access.nginx.log --error-logfile error.nginx.log --pid pidfile
