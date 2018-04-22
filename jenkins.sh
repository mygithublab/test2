#/bin/bash

docker build --rm -t printer .
#docker rm -f printer
docker run -itd --name printer -p 8003:22 -p 8002:80 \
 --privileged \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /tmp/$(mktemp -d):/run \
 -v $WORKSPACE/etc:/usr/local/nagios/etc \
 -v /volume4/nagios/var:/usr/local/nagios/var \
 -v /volume4/nagiosgraph/var:/usr/local/nagiosgraph/var \
 -v /volume2:/share \
 --restart=always printer
