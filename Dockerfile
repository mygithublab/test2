#This dockerfile base on latest Centos image
#Author: Mygithublab@126.com
#Nagios core with Nagiosgraph

FROM centos

#Maintainer information
MAINTAINER Mygithublab (mygithublab@126.com)

#Systemd is now included in both the centos:7 and centos:latest base containers, but it is not active by default. In order to use systemd, you will need to include text similar to the example Dockerfile below: https://hub.docker.com/_/centos/
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
  systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

#Setup environment
ENV NAGIOSADMIN_USER nagiosadmin
ENV NAGIOSADMIN_PASS nagios

#Copy local Nagios installation to container
#ADD nagios-4.3.4.tar.gz /tmp
#ADD nagios-plugins-2.2.1.tar.gz /tmp

#Install tools
RUN yum install -y \
    openssh-server \
    git \
    vim \
    crontabs \
    ntp \
    ntpdate \
    tzdata \

#Prerequisties software for Nagios Core
    gcc \
    glibc \
    glibc-common \
    wget \
    unzip \
    httpd \
    php \
    gd \
    gd-devel \
    perl \

#Prerequisties software for Nagios plugin
    gcc \
    glibc \
    glibc-common \
    make \
    gettext \
    automake \
    autoconf \
    wget \
    openssl-devel \
    net-snmp \
    net-snmp-utils \
 && yum install -y \
    perl-Net-SNMP \
    epel-release \
   
#Prerequisties softeare for NagiosGraph
    perl-rrdtool \
    perl-GD \
    perl-CPAN \
    perl-CGI \
    perl-Time-HiRes \
#Prerequisties software for SnmpPrinter
    php-snmp \
    bc \

 && yum clean all \

#Install and setup Nagios::Config perl module for TCPTraffic
 && wget http://xrl.us/cpanm -O /usr/bin/cpanm && chmod +x /usr/bin/cpanm && cpanm Nagios::Config Digest::MD5 \
  
#Prerequisties software for TCPTraffic
 && cpanm Carp English File::Basename Monitoring::Plugin Monitoring::Plugin::Getopt Monitoring::Plugin::Threshold Monitoring::Plugin::Range Readonly version

#Download and nagios core and nagios plug-in to /tmp folder
RUN cd /tmp \
 && wget --no-check-certificate -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.3.4.tar.gz \
 && tar zxvf nagioscore.tar.gz \
 && cd /tmp/nagioscore-nagios-4.3.4/ \
 && ./configure \
 && make all \
 && useradd nagios \
 && usermod -a -G nagios apache \
 && make install \
 && make install-init \
 && systemctl enable nagios.service \
 && systemctl enable httpd.service \
 && make install-commandmode \
 && make install-config \
 && make install-webconf \
#&& firewall-cmd --zone=public --add-port=80/tcp \
#&& firewall-cmd --zone=public --add-port=80/tcp --permanent \
 && htpasswd -bcs /usr/local/nagios/etc/htpasswd.users "${NAGIOSADMIN_USER}" "${NAGIOSADMIN_PASS}" \
 && cd /tmp \
 && wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz \
 && tar zxvf nagios-plugins.tar.gz \
 && cd /tmp/nagios-plugins-release-2.2.1/ \
 && ./tools/setup \
 && ./configure \
 && make \
 && make install \
 && /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

#Downloading nagiosGraph to /tmp folder
RUN cd /tmp && wget --no-check-certificate -O nagiosgraph.tar.gz https://nchc.dl.sourceforge.net/project/nagiosgraph/nagiosgraph/1.5.2/nagiosgraph-1.5.2.tar.gz \
 && tar zxvf nagiosgraph.tar.gz && cd /tmp/nagiosgraph-1.5.2 \
 && ./install.pl --install                                              \
         --prefix                   /usr/local/nagiosgraph              \
         --etc-dir                  /usr/local/nagiosgraph/etc          \
         --var-dir                  /usr/local/nagiosgraph/var          \
         --log-dir                  /usr/local/nagiosgraph/var/log      \
         --doc-dir                  /usr/local/nagiosgraph/doc          \
         --nagios-cgi-url           /nagiosgraph/cgi-bin                \
         --nagios-perfdata-file     /usr/local/nagios/var/perfdata.log  \
         --nagios-user              nagios                              \
         --www-user                 apache                               

#Graphs in Nagios Mouseovers for nagiosGraph
RUN cd /tmp/nagiosgraph-1.5.2 \
 && cp share/nagiosgraph.ssi /usr/local/nagios/share/ssi/common-header.ssi \
 && sed -i '172a \\taction_url\t\t\t\/nagiosgraph\/cgi-bin\/show.cgi?host=$HOSTNAME$&service=$SERVICEDESC$'\'' onMouseOver='\''showGraphPopup(this)'\'' onMouseOut='\''hideGraphPopup()'\'' rel='\''\/nagiosgraph\/cgi-bin\/showgraph.cgi?host=$HOSTNAME$&service=$SERVICEDESC$&period=day&rrdopts=-w+450+-j' /usr/local/nagios/etc/objects/templates.cfg \
 && sed -i '185a \\taction_url\t\t\t\/nagiosgraph\/cgi-bin\/show.cgi?host=$HOSTNAME$&service=$SERVICEDESC$'\'' onMouseOver='\''showGraphPopup(this)'\'' onMouseOut='\''hideGraphPopup()'\'' rel='\''\/nagiosgraph\/cgi-bin\/showgraph.cgi?host=$HOSTNAME$&service=$SERVICEDESC$&period=day&rrdopts=-w+450+-j' /usr/local/nagios/etc/objects/templates.cfg \

#Configuring Data Processing for nagiosGraph
 && sed -i 's/process_performance_data=0/process_performance_data=1/g' /usr/local/nagios/etc/nagios.cfg \
 && sed -i '$a service_perfdata_file=\/usr\/local\/nagios\/var\/perfdata.log' /usr/local/nagios/etc/nagios.cfg \
 && sed -i '$a service_perfdata_file_template=\$LASTSERVICECHECK\$\|\|\$HOSTNAME\$\|\|\$SERVICEDESC\$\|\|$SERVICEOUTPUT\$\|\|\$SERVICEPERFDATA\$' /usr/local/nagios/etc/nagios.cfg \
 && sed -i '$a service_perfdata_file_mode=a' /usr/local/nagios/etc/nagios.cfg \
 && sed -i '$a service_perfdata_file_processing_interval=10' /usr/local/nagios/etc/nagios.cfg \
 && sed -i '$a service_perfdata_file_processing_command=process-service-perfdata-for-nagiosgraph' /usr/local/nagios/etc/nagios.cfg \

# && cat <<EOF>>/usr/local/nagios/etc/objects/commands.cfg
#define command {
#        command_name process-service-perfdata-for-nagiosgraph
#        command_line /usr/local/nagiosgraph/bin/insert.pl
#        }
# EOF \

#define the process-service-perfdata command for nagiosGraph
 && sed -i '$a define command \{' /usr/local/nagios/etc/objects/commands.cfg \
 && sed -i '$a \\t command_name process-service-perfdata-for-nagiosgraph' /usr/local/nagios/etc/objects/commands.cfg \
 && sed -i '$a \\t command_line /usr/local/nagiosgraph/bin/insert.pl' /usr/local/nagios/etc/objects/commands.cfg \
 && sed -i '$a \\t \}' /usr/local/nagios/etc/objects/commands.cfg \

#Configuring Graphing and Display for nagiosGraph
 && sed -i '$a Include /usr/local/nagiosgraph/etc/nagiosgraph-apache.conf' /etc/httpd/conf/httpd.conf \
 && sed -i '2,7 s/^#//' /usr/local/nagiosgraph/etc/nagiosgraph-apache.conf \
 && sed -i '12 s/^#//' /usr/local/nagiosgraph/etc/nagiosgraph-apache.conf \
 && sed -i '104 s/denied/granted/' /etc/httpd/conf/httpd.conf \
 && sed -i '$a default_geometry = 1000x200' /usr/local/nagiosgraph/etc/nagiosgraph.conf \
 && sed -i 's/action_url_target=_blank/action_url_target=_self/g' /usr/local/nagios/etc/cgi.cfg \
 && sed -i 's/notes_url_target=_blank/notes_url_target=_self/g' /usr/local/nagios/etc/cgi.cfg \
 && /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg \

#Fixes problem with not working multiple selection for nagiosgraph datasets and periods
# && sed -i '2467 s/$cgi->td($cgi->popup_menu(-name => '\''period'\'', -values => \[@PERIOD_KEYS\], -labels => \\%period_labels, -size => PERIODLISTROWS, -multiple => 1)), "\\n",/$cgi->td($cgi->popup_menu(-name => '\''period'\'', -values => \[@PERIOD_KEYS\], -labels => \\%period_labels, -size => PERIODLISTROWS, -multiple)), "\\n",/' /usr/local/nagiosgraph/etc/ngshared.pm \
# && sed -i '2460 s/$cgi->td($cgi->popup_menu(-name => '\''db'\'', -values => \[\], -size => DBLISTROWS, -multiple => 1)), "\\n",/$cgi->td($cgi->popup_menu(-name => '\''db'\'', -values => \[\], -size => DBLISTROWS, -multiple)), "\\n",/' /usr/local/nagiosgraph/etc/ngshared.pm \

#Clean /tmp folder
 && rm -rf /tmp/*

ADD run.sh /run.sh
ADD script.sh /script.sh
ADD authorized_keys /root/.ssh/authorized_keys
ADD plugin/check_snmp_printer /usr/local/nagios/libexec/check_snmp_printer
ADD plugin/check_tcptraffic /usr/local/nagios/libexec/check_tcptraffic
ADD plugin/check_mem.pl /usr/local/nagios/libexec/check_mem.pl

RUN mkdir /share \
 && chmod 755 /run.sh \
 && chmod 755 /script.sh \
 && chmod 700 /root/.ssh \
 && chmod 600 /root/.ssh/authorized_keys \

#Change plugin permission
 && chmod 755 /usr/local/nagios/libexec/check_snmp_printer \
 && chmod 755 /usr/local/nagios/libexec/check_tcptraffic \
 && chmod 755 /usr/local/nagios/libexec/check_mem.pl \ 

#Copy ngios and graph to /bk folder 
 && mkdir -p /bk/nagios \
 && mkdir -p /bk/nagiosgraph \
 && cp -R -p /usr/local/nagios/etc /bk/nagios \
 && cp -R -p /usr/local/nagios/var /bk/nagios \
 && cp -R -p /usr/local/nagiosgraph/var /bk/nagiosgraph \
 && cp -R -p /usr/local/nagios/libexec /bk/nagios \
 && cp -R -p /usr/local/nagiosgraph/etc /bk/nagiosgraph \

#Define schedule task and ntp timezone
 && sed -i '$a * * * * * root bash /script.sh' /etc/crontab \
 && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && touch /var/www/html/index.html \

 && /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

EXPOSE 80 22

VOLUME ["/sys/fs/cgroup","/share","/usr/local/nagios/etc","/usr/local/nagios/var","/usr/local/nagios/libexec","/usr/local/nagiosgraph/var","/usr/local/nagiosgraph/etc"]

CMD ["/usr/sbin/init","/run.sh"]
