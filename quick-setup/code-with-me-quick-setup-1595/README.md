# Single-click executable for the Code With Me (CWM) servers

## Current limitations

* Servers can be launched only on `linux-x86_64` platform

## Description

This setup is intended for the quick evaluation purposes and is highly insecure for the production use.

* It doesn't have SSL for the Lobby or Relay servers connections
* The Relay cannot verify whether the requests to establish a relay are authentic and coming from the real Lobby server
* The Relay or the Host cannot verify whether session join request is signed by the Lobby server

## Launch

### Options

Host address is specified by the `-h` option.

Path to license file is specified by the`-k` option. To obtain one visit https://www.jetbrains.com/code-with-me/on-prem/

Lobby and relay server ports can be specified using the `-l` and `-r` options. They default to `2093` and `3974` respectively.

### Example 1

`$./launch.sh -h 10.2.2.53 -k license.key`

1. Launches a lobby server, accessible via the address `http://10.2.2.53:2093`.
2. Launches a relay server on the port `3274`, and the lobby will share a link of `ws://10.2.2.53:3274` as the relay address.

### Example 2

`$./launch.sh -h myserver.internal -k license.key -l 4950 -r 8092`

1. Launches a lobby server, accessible via the address `http://myserver.internal:4950`.
2. Launches a relay server on the port `8092`, and the lobby will share a link of `ws://myserver.internal:8092` as the relay address.

