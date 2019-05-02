# Template for deploy nagios 4.4.3 docker of CentOS

Testing or template of nagios 4.4.3 monitoring printer

Standalone mode:

`
docker run -itd --name printer -p 6001:22 -p 6000:80 \
 --privileged \ 
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /tmp/$(mktemp -d):/run \
 -v /volume2:/share \
 --restart=always printer
 `

External custom mode:

`
docker run -itd --name printer -p 6001:22 -p 6000:80 \
 --privileged \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /tmp/$(mktemp -d):/run \
 -v $WORKSPACE/etc:/usr/local/nagios/etc \
 -v /volume4/nagios/var:/usr/local/nagios/var \
 -v /volume4/nagiosgraph/var:/usr/local/nagiosgraph/var \
 -v /volume2:/share \
 --restart=always printer
`

1. After Nagios completed initialized then, copy nagios and nagiosgraph var folder to local host where is running nagios container.

2. Nagios/etc foler mount to github /etc folder, add host into object file, push to trigger a nagios restart.

3. Nagios/var folder mount to host folder. Log data with volume container as well.

4. Remove nagios container, the previous data still exist.

5. Migration Nagios and Nagiosgraph var folder to backup location.
