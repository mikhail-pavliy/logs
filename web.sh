#!/bin/bash
cp -R /vagrant/nginx.repo /etc/yum.repos.d/nginx.repo
yum upgrade
yum install -y nginx
yum install -y epel-release
yum install -y audispd-plugins.x86_64
systemctl start nginx
cp -R /vagrant/crit.conf /etc/rsyslog.d/crit.conf
systemctl restart rsyslog
cp -R /vagrant/nginx.conf /etc/nginx/nginx.conf
nginx -t
systemctl restart nginx
cp -R /vagrant/au-remote.conf /etc/audisp/plugins.d/au-remote.conf
cp -R /vagrant/audisp-remote.conf /etc/audisp/audisp-remote.conf
cp -R /vagrant/audit.rules /etc/audit/rules.d/audit.rules
systemctl daemon-reload
service auditd restart