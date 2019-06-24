# postfix

从alpine:3.9构建的postfix邮件服务器镜像, postfix版本3.3.2-r0  
除了sasl没有搞定, tls也没有搞定.. 以外, 对以下内容做了设置  
 本地收件人(local_recipient_maps 系统用户),  
 本地收件人别名(virtual_alias_maps 不需要系统用户),  
 虚拟收件人(virtual_mailbox_maps 不需要系统用户),  
 客户端连接策略(smtpd_client_restrictions),  
 helo策略,  
 发件人策略,  
 收件人策略  
使用`release 0.1`构建镜像, 能在mynetworks环境里自由发邮件, 外网只收取check_recipient_access限定收件人的邮件  
  
postfix需要syslogd来写日志, 日志重定向到了/var/log/mail.log  

主要参考了官方文档: http://www.postfix.org/documentation.html

___
`release 0.2` sasl已搞定..  
