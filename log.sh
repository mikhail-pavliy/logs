#!/bin/bash
yum install -y epel-release
yum install -y policycoreutils-python
cp -R /vagrant/rsyslog.conf /etc/rsyslog.conf
systemctl restart rsyslog
cp -R /vagrant/auditd.conf /etc/audit/auditd.conf
systemctl daemon-reload
service auditd restart