#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

TEMPFILE=`echo "${0#*/}" | /usr/bin/sed "s/\//_/g"`
TEMPFILE="/tmp/.munin_${TEMPFILE}"
PARTS=1
TIMEOUT=5

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

case $0 in
    *ping6_*)
        PING=ping6
        file_host=${0##*/ping6_}
        V=IPv6
        PARAM="-i 0.1 -c 20"
        ;;
    *ping_*)
        PING=ping
        file_host=${0##*/ping_}
        V=IPv4
        PARAM="-i 0.1 -c 20 -t 4"
        ;;
esac

host=${host:-${file_host:-127.0.0.1}}
if [ "${HOSTS[$host]}" == "" ]; then
 HOSTS[${host}]=${host}
fi
name=${host}
if [ "${host}" == ".new" ]; then
 PARTS=2
 host="127.0.0.1"
 name="Localhost"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2="::1"
fi
if [ "${host}" == "localhost" ]; then
 PARTS=2
 host="127.0.0.1"
 name="Localhost"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2="::1"
fi
if [ "${host}" == "nix" ]; then
 PARTS=2
 host=${NIX}
 name="NIX"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2=${NIX6}
fi
if [ "${host}" == "pdns" ]; then
 PARTS=2
 host=${PDNS}
 name="Public DNS"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2=${PDNS6}
fi
if [ "${host}" == "isp" ]; then
 PARTS=2
 host=${MyISP:-127.0.0.1}
 name="ISP"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2=${MyISP6:-\:\:1}
fi
if [ "${host}" == "gw" ]; then
 PARTS=2
 host=${MyGW:-127.0.0.1}
 name="GW"
 V2=IPv6
 PARAM2="-i 0.1 -c 20"
 PING2="ping6"
 host2=${MyGW6:-\:\:1}
fi

if [ "$1" = "config" ]; then
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_vlabel roundtrip time (miliseconds)'
        echo 'graph_category network'
        echo 'graph_info This graph shows ping RTT statistics.'
        hcnt=0
        for h in ${host}; do
         echo "pta${hcnt}.label ${HOSTS[$h]}"
         echo "pta${hcnt}.info Ping to ${h}"
         hcnt=$((${hcnt}+1))
        done
        if [ "${PARTS}" == "2" ]; then
         hcnt=0
         for h in ${host2}; do
          echo "ptb${hcnt}.label ${HOSTS[$h]}"
          echo "ptb${hcnt}.info Ping to ${h}"
          hcnt=$((${hcnt}+1))
         done
        fi
        echo graph_title Ping to ${name}
        exit 0
fi

hcnt=0
for h in ${host}; do
 ${PING:-/sbin/ping} ${PARAM} -q ${h} 2>&1 | /usr/bin/grep "round-trip" | /usr/bin/sed "s/\// /g" | /usr/bin/awk '{print $7}' > ${TEMPFILE}.PTA${hcnt} &
 hcnt=$((${hcnt}+1))
done
if [ "${PARTS}" == "2" ]; then
 hcnt=0
 for h in ${host2}; do
  ${PING2:-/sbin/ping6} ${PARAM2} -q ${h} 2>&1 | /usr/bin/grep "round-trip" | /usr/bin/sed "s/\// /g" | /usr/bin/awk '{print $7}' > ${TEMPFILE}.PTB${hcnt} &
  hcnt=$((${hcnt}+1))
 done
fi
/bin/sleep ${TIMEOUT}

hcnt=0
for h in ${host}; do
 PT=`/usr/bin/tail -n 1 ${TEMPFILE}.PTA${hcnt}`
 echo "pta${hcnt}.value ${PT:-U}"
 /bin/rm -f ${TEMPFILE}.PTA${hcnt}
 hcnt=$((${hcnt}+1))
done
if [ "${PARTS}" == "2" ]; then
 hcnt=0
 for h in ${host2}; do
  PT2=`/usr/bin/tail -n 1 ${TEMPFILE}.PTB${hcnt}`
  echo "ptb${hcnt}.value ${PT2:-U}"
  /bin/rm -f ${TEMPFILE}.PTB${hcnt}
  hcnt=$((${hcnt}+1))
 done
fi
