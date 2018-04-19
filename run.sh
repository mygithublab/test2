#!/bin/bash

systemctl restart sshd
systemctl restart crond
systemctl restart ntpd
systemctl restart nagios
systemctl restart httpd
/bin/bash

