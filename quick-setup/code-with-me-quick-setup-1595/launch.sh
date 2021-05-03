#!/bin/bash
set -euo pipefail
set -o monitor
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

EXAMPLE="Example: ./launch.sh -h my_server -k path/to/license.key [-a listen_address -l 2093 -r 3274].\nThis will launch an unsecure installation of lobby server which is accessible on the port 2093, generates links for sessions staring with http://my_server:2093 and a relay server on the address ws://my_server:3274. Servers will be listening on all interfaces by default, or on listen_address if specified.\n"
HELP_MESSAGE="This a single-entrypoint distribution of CWM servers for testing purposes.\nTwo command-line arguments are required: the host name and the path to license key file.\nTo obtain license - visit https://www.jetbrains.com/code-with-me/on-prem/\n\n$EXAMPLE"

# we need printf exactly for \n
# shellcheck disable=SC2059
[[ "$#" == "0" ]] && printf "$HELP_MESSAGE" >&2 && exit 1

HOST_ADDRESS=""
LOBBY_PORT="2093"
RELAY_PORT="3274"
LISTEN_ADDRESS=""
LICENSE=""
ENABLED_FEATURES=direct_tcp,ws_relay,project_names,user_names

while getopts ":h:a:l:r:k:" opt; do
  case $opt in
    h)
      HOST_ADDRESS=$OPTARG
      ;;
    a)
      LISTEN_ADDRESS=$OPTARG
      ;;
    l)
      LOBBY_PORT=$OPTARG
      ;;
    r)
      RELAY_PORT=$OPTARG
      ;;
    k)
      LICENSE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      # shellcheck disable=SC2059
      printf "\n$EXAMPLE"
      exit 1
      ;;
  esac
done

INVALID_OPT=0

if [[ -z "$HOST_ADDRESS" ]] ; then
  printf "Host address is not set. Use -h to set it (e.g.: -h my_server).\n" >&2
  INVALID_OPT=1
fi

if [[ -z "$LOBBY_PORT" ]] ; then
  printf "Lobby port is not set. Use -l to set it (e.g.: -l 2093).\n" >&2
  INVALID_OPT=1
fi

if [[ -z "$RELAY_PORT" ]] ; then
  printf "Relay port is not set. Use -r to set it (e.g.: -r 3274).\n" >&2
  INVALID_OPT=1
fi

if [[ -z "$LICENSE" ]] ; then
  printf "License is not set. Use -k to set it (e.g.: -k path/to/license.key).\n" >&2
  INVALID_OPT=1
fi

# shellcheck disable=SC2059
[[ "$INVALID_OPT" -eq "1" ]] && printf "\n$EXAMPLE" && exit 1

# kill child processes on termination
function killChildProcesses() {
  echo "Terminating child processes"

  # disabling recursive trapping
  trap - SIGTERM SIGINT EXIT

  # shellcheck disable=SC2046
  # yep, that's exactly what we want
  kill $(jobs -p)
}

trap 'killChildProcesses' SIGTERM SIGINT EXIT

# either address:port, or :port for all interfaces
("$SCRIPT_PATH/relay/ws-relayd" --allow-server-without-authentication --addr "$LISTEN_ADDRESS:$RELAY_PORT" > relay.log 2>&1) &
RELAY_PID=$!
echo "relay server is up, PID=$RELAY_PID"

printf "Lobby server will generate links with the HTTP protocol and the clients will use the WS protocol for communicating with the relay servers. Do not use this in production.\n" >&2
LOBBY_URL="http://$HOST_ADDRESS:$LOBBY_PORT"
RELAY_URL="ws://$HOST_ADDRESS:$RELAY_PORT"
CONFIG_JSON=$SCRIPT_PATH/lobby/config.json
echo "
  {
    \"stunTurnServers\": [
      {
        \"uri\": \"stun:stun.l.google.com:19302\"
      },
      {
        \"uri\": \"stun:stun2.l.google.com:19302\"
      }
    ],
    \"relays\": [
      {
        \"regionName\" : \"internal\",
        \"latitude\": 0,
        \"longitude\": 0,
        \"servers\" : [
          \"$RELAY_URL\"
        ]
      }
    ]
  }" > "$SCRIPT_PATH/lobby/config.json"
export CONFIG_JSON

export ENABLED_FEATURES
if [[ -n "$LISTEN_ADDRESS" ]]
then
  SERVER_LISTEN_ON=$LISTEN_ADDRESS
  export SERVER_LISTEN_ON
fi
(SERVER_PORT=$LOBBY_PORT BASE_URL=$LOBBY_URL LICENSE_BUNDLES="$LICENSE" lobby/bin/lobby-server > lobby.log 2>&1) &
LOBBY_PID=$!
echo "lobby server is up, PID=$LOBBY_PID"

printf "*******************\n"
echo "Lobby server is accessible on the URL $LOBBY_URL. Set this address in Settings->Code With Me->Lobby server URL to use it."
printf "*******************\n"

printf "Servers are launched, see relay.log and lobby.log for more info. Press Ctrl-C to stop.\n"

(tail -F relay.log lobby.log) &
TAIL_PID=$!

while true; do
  if ! kill -0 "$RELAY_PID" > /dev/null 2>&1; then
    echo "Relay server [pid $RELAY_PID] is not alive"
    wait "$RELAY_PID"
    break
  fi
  if ! kill -0 "$LOBBY_PID" > /dev/null 2>&1; then
    echo "Lobby server [pid $LOBBY_PID] is not alive"
    wait "$LOBBY_PID"
    break
  fi
  if ! kill -0 "$TAIL_PID" > /dev/null 2>&1; then
    echo "Log printing process [pid $TAIL_PID] is not alive"
    wait "$TAIL_PID"
    break
  fi
  sleep 0.3
done