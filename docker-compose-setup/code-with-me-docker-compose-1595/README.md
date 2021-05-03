# Docker compose setup

Based on [Code With Me administration guide](https://www.jetbrains.com/help/cwm/code-with-me-administration-guide.html#enterprise_config)

## Prerequisites

You must have ssl certificates for `lobby.YOUR_DOMAIN` and `relay.YOUR_DOMAIN` 

## How to use this setup

`YOUR_DOMAIN` equals to `cwm.internal` in this setup

`YOUR_HOST` is the IP address of machine which running docker-compose

### Instance reachability

Default domains for this setup are `lobby.cwm.internal` and `relay.cwm.internal`

Configure your dns to respond with `YOUR_HOST` for:

1) `relay.cwm.internal`
2) `lobby.cwm.internal`

Or

Search and Replace `lobby.cwm.internal` and `relay.cwm.internal` with your domain name or host (e.g. 127.0.0.1)

**Note**: alternatively you can set a record in `/etc/hosts` or Windows counterpart for each client:
```
echo "YOUR_HOST lobby.cwm.internal relay.cwm.internal" > /etc/hosts
```
where YOUR_HOST is the host, where your docker-compose running

### License

Put your `license.key` in `lobby/license.key`

To obtain one visit https://www.jetbrains.com/code-with-me/on-prem/

### Certificates
Lobby and Relay:
```
openssl ecparam -name secp384r1 -genkey -noout -out lobby/lobby_private.pem
openssl ec -in lobby/lobby_private.pem -pubout -out relay/lobby_public.pem
```
nginx:

Out of scope of this guide

### Configuration

Look into docker-compose.yaml and tweak lobby and relay parameters to your needs.

Make sure you have at least 1.27 docker-compose version.

For parameter reference visit [Code With Me administration guide](https://www.jetbrains.com/help/cwm/code-with-me-administration-guide.html#enterprise_config)

### Troubleshooting

Whenever you see error like this - make sure you generated certificates for lobby and relays

```
lobby_1  | java.lang.NullPointerException: PEMParser(StringReader(keyText)).readObject() must not be null
lobby_1  | 	at com.a.a.b.O6.a(O6.java:298)
lobby_1  | 	at com.a.a.b.O6.a(O6.java:190)
lobby_1  | 	at com.a.a.b.O6.b(O6.java:25)
lobby_1  | 	at com.a.a.b.O6.a(O6.java:420)
lobby_1  | 	at com.a.a.b.O6.main(O6.java)
```