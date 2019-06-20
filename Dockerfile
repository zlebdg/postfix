FROM alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk --update add postfix busybox-extras bash vim \
    && rm -rf /var/cache/apk/*

RUN echo -e "\n\
#mail.err /var/log/mail.log \n\
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
relay_domains=\$mydestination,163.com,qq.com,!gmail.com, \n\
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
local_recipient_maps=hash:/etc/postfix/local_recipient_maps \n\
# 一个拒收规则 \n\
#smtpd_reject_unlisted_sender=yes \n\
# 虚拟别名 \n\
virtual_alias_domains=v.xjplus.xyz,vip.xjplus.xyz \n\
# 虚拟别名转发到本地unix用户目录 \n\
virtual_alias_maps=hash:/etc/postfix/virtual_alias_maps \n\
# 虚拟邮箱目录, 注意修改目录权限, 否则可能无法保存邮件 \n\
virtual_mailbox_base=/var/vmail \n\
# 虚拟邮箱域名 \n\
virtual_mailbox_domains=box.xjplus.xyz \n\
# 虚拟邮箱-邮件存储路径 \n\
virtual_mailbox_maps=hash:/etc/postfix/virtual_mailbox_maps \n\
# 最小uid, 默认100 \n\
virtual_minimum_uid=100 \n\
virtual_uid_maps=static:101 \n\
virtual_gid_maps=static:101 \n\
" >> /etc/postfix/main.cf

RUN echo -e "\n\
@qq.com y \n\
xuqplus@163.com y \n\
" > /etc/postfix/relay_recipient_maps && postmap /etc/postfix/relay_recipient_maps

RUN echo -e "\n\
local-01  y \n\
local-02  y \n\
" > /etc/postfix/local_recipient_maps && postmap /etc/postfix/local_recipient_maps \
    && adduser -D local-01 \
    && adduser -D local-02

RUN echo -e "\n\
test.abc@v.xjplus.xyz  test \n\
root.abc123@vip.xjplus.xyz  postmaster \n\
" > /etc/postfix/virtual_alias_maps && postmap /etc/postfix/virtual_alias_maps

RUN echo -e "\n\
box_001@box.xjplus.xyz  box.xjplus.xyz/box_001/ \n\
box_002@box.xjplus.xyz  box/box_002/ \n\
" > /etc/postfix/virtual_mailbox_maps && postmap /etc/postfix/virtual_mailbox_maps

EXPOSE 25

CMD newaliases && syslogd && postfix start && sh