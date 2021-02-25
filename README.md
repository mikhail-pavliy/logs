# logs
Настраиваем центральный сервер для сбора логов
в вагранте поднимаем 2 машины web и log
на web поднимаем nginx
на log настраиваем центральный лог сервер на любой системе на выбор
- journald
- rsyslog
- elk
настраиваем аудит следящий за изменением конфигов нжинкса

все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему


* развернуть еще машину elk
и таким образом настроить 2 центральных лог системы elk И какую либо еще
в elk должны уходить только логи нжинкса
во вторую систему все остальное

# 1. настраиваем аудит следящий за изменением конфигов нжинкса

Подготавливаем наши виртуалки web и log, в файлах web.sh и log.sh конфигурируем их 
Добавляем правила (опция -k задает ключ фильтрации, по которому можно будет отследить события при срабатывании данного правила):
```ruby
[root@web vagrant]# cat /etc/audit/rules.d/audit.rules
## First rule - delete all
-D

## Increase the buffers to survive stress events.
## Make this bigger for busy systems
-b 8192

## Set failure mode to syslog
-f 1
-w /etc/nginx/ -p wa -k nginx_watch
```
После редактирования данного файла нужно рестартануть auditd:
```ruby
[root@web vagrant]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
Проверим наше праивло:
```ruby
[root@web vagrant]# auditctl -l
-w /etc/nginx -p wa -k nginx_watch
```
Изменим порт нжинкса в конфиг-файле и проверим логи auditd:
```ruby
[root@web vagrant]# ausearch -k nginx_watch
```
Полчим вот такой вывод
```ruby
Thu Feb 25 13:35:04 2021
type=CONFIG_CHANGE msg=audit(1614260104.090:1045): proctitle=6E616E6F002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1614260104.090:1045): item=1 name="/etc/nginx/nginx.conf" inode=67147343 dev=fd:00 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1614260104.090:1045): item=0 name="/etc/nginx/" inode=67147329 dev=fd:00 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1614260104.090:1045):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1614260104.090:1045): arch=c000003e syscall=2 success=yes exit=3 a0=26f9c60 a1=241 a2=1b6 a3=7ffddae741e0 items=2 ppid=3762 pid=3883 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=5 comm="nano" exe="/usr/bin/nano" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_watch"
```

# 2. все критичные логи с web должны собираться и локально и удаленно
В /etc/rsyslog.conf вносим изменения для отправки всех критических изменений на сервер log. Правки вносим в раздел RULES
```ruby
*.crit action(type="omfwd" target="192.168.10.20" port="514" protocol="tcp"
              action.resumeRetryCount="100"
              queue.type="linkedList" queue.size="10000")
 ```
 
 # 3. все логи с nginx должны уходить на удаленный сервер (локально только критичные)

В конфиг nginx добавляем следующие строки:
``` ruby
error_log syslog:server=192.168.10.20:514,tag=nginx_error;
error_log  /var/log/nginx/error.log crit;
----------------

access_log syslog:server=192.168.10.20:514,facility=local6,tag=nginx_access,severity=info main;
```
Для разделения логов nginx, access и error по отделным директориям в конфигурацию /etc/rsyslog.conf
```ruby
if ($hostname == 'web') and ($programname == 'nginx_access') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_access.log")
    stop
}

if ($hostname == 'web') and ($programname == 'nginx_error') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_error.log")
    stop
}
```

# 4. Отправлять все аудит логи на сервер log.
Чтобы логи auditd писались на удаленный rsyslog сервер, нужно установить пакет audispd-plugins как на  web, так и на  log. Затем изменить следующие опции в конфиг файлах:
в файле  /etc/audisp/audisp-remote.conf: 
```ruby
remote_server = 192.168.10.20
port = 514
```
в файле ```ruby /etc/audisp/plugins.d/au-remote.conf:```
```ruby
active = yes
```
в файле ```ruby /etc/audit/auditd.conf: ```
```ruby
write_logs = no
```
На самом сервере log разрешить прием логов в файле  /etc/rsyslog.conf:
```ruby
# Provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514

	# Provides TCP syslog reception
	$ModLoad imtcp
	$InputTCPServerRun 514
```  
Изменим  конфиг нжинкса  и проверим логи auditd:
```ruby
[root@log vagrant]# ausearch -k nginx_watch
------
node=web type=PATH msg=audit(1614261253.736:1053): item=1 name="/etc/nginx/nginx.conf" inode=67147343 dev=fd:00 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1614261253.736:1053): item=0 name="/etc/nginx/" inode=67147329 dev=fd:00 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=CWD msg=audit(1614261253.736:1053):  cwd="/home/vagrant"
node=web type=SYSCALL msg=audit(1614261253.736:1053): arch=c000003e syscall=2 success=yes exit=3 a0=1565cc0 a1=241 a2=1b6 a3=7ffc79db77e0 items=2 ppid=3762 pid=4038 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=5 comm="nano" exe="/usr/bin/nano" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_watch"
```

