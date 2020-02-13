#!/bin/sh
##### SCRIPT PARAMETERS #####
METRIC="$1"
CACHE_TTL="150"
USR=`find /home/*/.local/share/nucypher/ -type f -name ursula.json | awk -F "/" '{print $3}'`
if [ -z "$USR" ]; then
   HOME="/root"
else
   HOME="/home/$USR"
fi
IPC="$HOME/.ethereum/goerli/geth.ipc"
STAKERADDRESS=`cat $HOME/.local/share/nucypher/ursula.json | jq .checksum_address| tr -d '"'`
WORKERADDRESS=`cat $HOME/.local/share/nucypher/ursula.json | jq .worker_address | tr -d '"'`
echo $IPC
echo $WORKERADDRESS
STATSFILE=/tmp/nucypher.txt
CACHE_FILE="/tmp/nucypher.`echo $STATSFILE | md5sum | cut -d" " -f1`.cache"
EXEC_TIMEOUT="1"
NOW_TIME=`date '+%s'`

##### RUN #####
if [ -s "${CACHE_FILE}" ]; then
  CACHE_TIME=`stat -c %Y "${CACHE_FILE}"`
else
  CACHE_TIME=0
fi
DELTA_TIME=$(($NOW_TIME - $CACHE_TIME))

if [ $DELTA_TIME -lt $EXEC_TIMEOUT ]; then
  sleep $(($EXEC_TIMEOUT - $DELTA_TIME))
elif [ $DELTA_TIME -gt $CACHE_TTL ]; then
  cp $STATSFILE $CACHE_FILE
fi

NODESTOTAL=`cat $CACHE_FILE | grep Nickname | sort -u | wc -l`
NODESACTIVE=`cat $CACHE_FILE | grep Activity | grep Next | wc -l`
NODESPENDING=`cat $CACHE_FILE | grep Activity | grep Pending | wc -l`
NODESINACTIVE=`cat $CACHE_FILE | grep Activity | grep -v Pending | grep -v Next | wc -l`
TOKENSOWNED=`cat $CACHE_FILE | grep $STAKERADDRESS -A 1 | egrep -o "Owned:\s+[0-9]+\.[0-9]+" | awk '{print $2}'`
TOKENSSTAKED=`cat $CACHE_FILE | grep $STAKERADDRESS -A 1 | egrep -o "Staked:\s+[0-9]+\.[0-9]+" | awk '{print $2}'`
TOKENSDIFF=`echo $TOKENSOWNED-$TOKENSSTAKED | bc`
WORKERETHAMOUNT=`geth --exec 'web3.fromWei(eth.getBalance("$WORKERADDRESS"), "ether")' attach $IPC`
INDEX=`cat $CACHE_FILE | grep NU | egrep -o "Owned:\s+[0-9]+\.[0-9]+" | awk '{print $2}'`
TOKENSTOTAL=`echo $INDEX | xargs | tr ' ' '+' | bc`
INDEX1=`cat $CACHE_FILE | grep -e "Next period confirmed" -e Pending -B3 | egrep -o "Staked:\s+[0-9]+\.[0-9]+" | awk '{print $2}' | xargs | tr ' ' '+' | bc`
TOKENSACTIVETOTAL=`echo $INDEX1 | xargs | tr ' ' '+' | bc`
PERIOD=`echo $NOW_TIME / 86400 | bc`
BLOCKHEIGHT=`geth --exec "eth.blockNumber" attach $IPC`
if [ "$BLOCKHEIGHT" = 0 ]; then
  BLOCKHEIGHT=`geth --exec eth.syncing attach $IPC | jq .currentBlock`
fi
GETDIRSIZE=`du -bs $HOME/.ethereum | awk '{print $1}'`
URSULADIRSIZE=`du -bs $HOME/.cache/nucypher | awk '{print $1}'`
DATABACKUPDIRSIZE=`du -bs /usr/data_backup | awk '{print $1}'`
NUCYPHERVERSIONLOCAL=`cat $HOME/nucypher*env/lib/python3.6/site-packages/nucypher/__about__.py | grep "__version__ =" | egrep -o '".*' | tr -d '"'`
#NUCYPHERVERSIONGIT=`curl -s "https://api.github.com/repos/nucypher/nucypher/tags" | jq -r '.[0].name' | tr -d 'v'`

##### PARAMETERS #####
if [ "${METRIC}" = "nodestotal" ]; then
  echo $NODESTOTAL
  fi
if [ "${METRIC}" = "nodesactive" ]; then
  echo $NODESACTIVE
fi
if [ "${METRIC}" = "nodespending" ]; then
  echo $NODESPENDING
fi
if [ "${METRIC}" = "nodesinactive" ]; then
  echo $NODESINACTIVE
fi
if [ "${METRIC}" = "tokenstotal" ]; then
  echo $TOKENSTOTAL
fi
if [ "${METRIC}" = "tokensactivetotal" ]; then
  echo $TOKENSACTIVETOTAL
fi
if [ "${METRIC}" = "tokensowned" ]; then
  echo $TOKENSOWNED
fi
if [ "${METRIC}" = "tokensstaked" ]; then
  echo $TOKENSSTAKED
fi
if [ "${METRIC}" = "tokensdiff" ]; then
  echo $TOKENSDIFF
fi
if [ "${METRIC}" = "workerethamount" ]; then
  echo $WORKERETHAMOUNT
fi
if [ "${METRIC}" = "period" ]; then
  echo $PERIOD
fi
if [ "${METRIC}" = "blockheight" ]; then
  echo $BLOCKHEIGHT
fi
if [ "${METRIC}" = "gethdirsize" ]; then
  echo $GETDIRSIZE
fi
if [ "${METRIC}" = "ursuladirsize" ]; then
  echo $URSULADIRSIZE
fi
if [ "${METRIC}" = "databackupdirsize" ]; then
  echo $DATABACKUPDIRSIZE
fi
if [ "${METRIC}" = "nucypherversionlocal" ]; then
  echo $NUCYPHERVERSIONLOCAL
fi
if [ "${METRIC}" = "nucypherversiongit" ]; then
  echo $NUCYPHERVERSIONGIT
fi
#
exit 0
