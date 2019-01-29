#!/bin/sh
# nds-sanit	Manage aajege-test processes.
# 
# chkconfig:    2345 95 20
#
# description: 	python/fastcgi processes for aajege-test 
# 
# processname: 	aajege-test

# source function library
. /etc/rc.d/init.d/functions

PROJNAME='aajege-test/fastcgi'

# NB: don't forget to change pidfile if copying this for a new config.

# Project's virtualenv
ENVLOC="/path/to/project/aajege/src/media-serv/.env/"
PROJECTLOC="/path/to/project/aajege/src/media-serv/"
SERVER_PID="$PROJECTLOC/pidfile.pid"

# Config file associated with the instance

HOSTNAME="hostname.domain.com"
PORT=80
BASE_CMD="gunicorn -w 4 -b $HOSTNAME:$PORT media_serv:app --log-level info --access-logfile $PROJECTLOC/access.log --error-logfile $PROJECTLOC/error.log --pid $SERVER_PID --daemon"

RETVAL=0

start_server () {
  if [ -f $1 ]; then
    #pid exists, check if running
    if [ "$(ps -p `cat $1` | wc -l)" -gt 1 ]; then
  	action $"Starting $PROJNAME -- ${ADDRESS}:${2}..." /bin/false
        echo -n " * Server already running on ${ADDRESS}:${2}"
       return
    fi
  fi
  cd $PROJECTLOC
  . $ENVLOC/bin/activate
  $BASE_CMD && success || failure
  RETVAL=$?
  echo -n $"Starting $PROJNAME -- ${ADDRESS}:${2}..." $?
  echo
}

restart_server () {
  PID=`cat $1`
  kill -1 $PID
  action $"Sending SIGHUP to $PROJNAME -- ${ADDRESS}:${2}..." /bin/true
}

stop_server (){
  if [ -f $1 ] && [ "$(ps -p `cat $1` | wc -l)" -gt 1 ]; then
    kill `cat $1`
    rm $1
    action $"Stopping $PROJNAME -- ${ADDRESS}:${2}..." /bin/true
  else 
    action $"Stopping $PROJNAME -- ${ADDRESS}:${2}..." /bin/false
    if [ -f $1 ]; then
      echo -n " * Server ${ADDRESS}:${2} not running"
    else
      echo -n " * No pid file found for server ${ADDRESS}:${2}"
    fi
  fi
}

case "$1" in
'start')
  start_server $SERVER_PID $SERVER_PORT 
  ;;
'stop')
  stop_server $SERVER_PID $SERVER_PORT
  ;;
'restart')
  stop_server $SERVER_PID $SERVER_PORT
  sleep 2
  start_server $SERVER_PID $SERVER_PORT 
  ;;
*)
  echo -n "Usage: $0 { start | stop | restart }"
  ;;
esac

exit $RETVAL
