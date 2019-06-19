FROM alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk --update add postfix busybox-extras bash

RUN echo -e "#mail.err /var/log/mail.log \n\
#mail.info /var/log/mail.log \n\
#mail.debug /var/log/mail.log \n\
mail.* /var/log/mail.log\n\
" > /etc/syslog.conf

RUN echo -e "\n\
# 服务器的名字 \n\
myhostname=mail.xjplus.xyz \n\
# 域名 \n\
mydomain=xjplus.xyz \n\
# 发邮件的邮箱后缀名, 如: user@\$mydomain \n\
myorigin=\$mydomain \n\
# 收邮件的邮箱后缀名, 如: user@\$mydestination \n\
mydestination=\$myhostname,\$mydomain \n\
# 为什么邮箱后缀中继邮件 \n\
relay_domains=\$mydestination,qq.com,163.com, \n\
# 可用的收件人列表 \n\
relay_recipient_maps=hash:/etc/postfix/relay_recipient_maps \n\
#.com.cn,.cn,.xyc \n\
# 保存邮件的相对路径 \n\
home_mailbox=maildir/ \n\
# 收件网关 \n\
inet_interfaces=all \n\
# 什么客户端可以发邮件 \n\
mynetworks=172.18.0.0/16,127.0.0.0/8 \n\
# 可用的本地收件邮箱 \n\
local_recipient_maps=hash:/etc/postfix/local_recipient_maps\n\
" >> /etc/postfix/main.cf

RUN echo -e "\n\
test001     y \n\
test002     y \n\
" > /etc/postfix/local_recipient_maps && postmap /etc/postfix/local_recipient_maps

EXPOSE 25

CMD newaliases && syslogd && postfix start && sh