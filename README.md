# Docker Stack - Network
Docker Stack to provide various services on the network.

## Traefik

```
bash ./traefik/install.sh -a 192.168.0.42 -n net-traefik
```

## Prometheus

```
bash ./prometheus/install.sh -a 192.168.0.42 -n net-prometheus
```

## Grafana

```
bash ./grafana/install.sh -a 192.168.0.42 -n net-grafana
```

## DNS
This Docker Stack is using unbound as recursive, caching DNS resolver. It also can be used as a upstream server for Pi-hole. It is possible to change the DNS port using `dns/unbound.port.conf`. This Stack is currently missing Pi-hole because of the missing option to change the web port. This option will be introduced with Pi-hole 6.

```
bash ./dns/install.sh -n net-dns
```