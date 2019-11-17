FROM alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk --update add postfix postfix-mysql cyrus-sasl cyrus-sasl-login busybox-extras bash vim \
    && rm -rf /var/cache/apk/*

RUN echo -e "\n\
#mail.err /var/log/mail.log \n\
#mail.info /var/log/mail.log \n\
#mail.debug /var/log/mail.log \n\
mail.* /var/log/mail.log\n\
" > /etc/syslog.conf

# main.conf, defer/defer_if_reject/defer_if_permit

ARG POSTFIX_DOMAIN=java8.xyz

RUN echo -e "\n\
# 服务器的名字 \n\
myhostname=mail.${POSTFIX_DOMAIN} \n\
# 域名 \n\
mydomain=${POSTFIX_DOMAIN} \n\
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
mynetworks=172.19.0.0/16,172.18.0.0/16,127.0.0.0/8 \n\
# 可用的本地收件邮箱 \n\
local_recipient_maps=hash:/etc/postfix/local_recipient_maps \n\
# 一个拒收规则 \n\
#smtpd_reject_unlisted_sender=yes \n\
# 虚拟别名 \n\
virtual_alias_domains=v.${POSTFIX_DOMAIN},vip.${POSTFIX_DOMAIN} \n\
# 虚拟别名转发到本地unix用户目录 \n\
virtual_alias_maps=hash:/etc/postfix/virtual_alias_maps \n\
# 虚拟邮箱目录, 注意修改目录权限, 否则可能无法保存邮件 \n\
virtual_mailbox_base=/var/vmailbox \n\
# 虚拟邮箱域名 \n\
virtual_mailbox_domains=box.${POSTFIX_DOMAIN} \n\
# 虚拟邮箱-邮件存储路径 \n\
virtual_mailbox_maps=hash:/etc/postfix/virtual_mailbox_maps \n\
# 最小uid, 默认100 \n\
virtual_minimum_uid=100 \n\
virtual_uid_maps=static:101 \n\
virtual_gid_maps=static:101 \n\
# 开启sasl \n\
smtpd_sasl_auth_enable=yes \n\
smtpd_sasl_path=smtpd \n\
smtpd_sasl_security_options=noanonymous \n\
# 立即拒绝 \n\
smtpd_delay_reject=no \n\
# client 策略 \n\
smtpd_client_restrictions=permit_mynetworks, defer_if_reject \n\
# helo策略 \n\
smtpd_helo_required=yes \n\
smtpd_helo_restrictions= \n\
 permit_mynetworks \n\
 reject_invalid_helo_hostname \n\
 reject_unknown_helo_hostname \n\
# 发件人策略 \n\
smtpd_sender_restrictions= \n\
 # 拒绝非全限定域名的发件人 \n\
 reject_non_fqdn_sender \n\
 # mynetworks内部通过 \n\
 # permit_mynetworks \n\
 # 查表 permit/reject/dunno \n\
 check_sender_access hash:/etc/postfix/check_sender_access \n\
 # sasl认证 \n\
 reject_sender_login_mismatch \n\
 reject_known_sender_login_mismatch \n\
 reject_authenticated_sender_login_mismatch \n\
 # 其他 \n\
 defer_if_reject \n\
# sasl登录用户对应发件名 \n\
smtpd_sender_login_maps=hash:/etc/postfix/smtpd_sender_login_maps \n\
# 收件人策略 \n\
smtpd_recipient_restrictions= \n\
 # 拒绝非全限定域名的收件人 \n\
 reject_non_fqdn_recipient \n\
 # mynetworks内部通过 \n\
 # permit_mynetworks \n\
 # sasl认证的通过 \n\
 permit_sasl_authenticated \n\
 # 查表 permit/reject/dunno \n\
 check_recipient_access hash:/etc/postfix/check_recipient_access \n\
 # 其他拒绝 \n\
 defer \n\
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
virtual-01@v.${POSTFIX_DOMAIN}  local-01 \n\
virtual-02@v.${POSTFIX_DOMAIN}  local-02 \n\
virtual-03@vip.${POSTFIX_DOMAIN}  postmaster \n\
" > /etc/postfix/virtual_alias_maps && postmap /etc/postfix/virtual_alias_maps

RUN echo -e "\n\
# 目录要以/结尾 \n\
box-01@box.${POSTFIX_DOMAIN}  box.${POSTFIX_DOMAIN}/box-01/ \n\
box-02@box.${POSTFIX_DOMAIN}  box.${POSTFIX_DOMAIN}/box-02/ \n\
" > /etc/postfix/virtual_mailbox_maps && postmap /etc/postfix/virtual_mailbox_maps \
    && mkdir /var/vmailbox/ \
    && chown postfix:postfix /var/vmailbox \
    && chmod 774 /var/vmailbox/ -R

RUN echo -e "\n\
local-01@${POSTFIX_DOMAIN}         ok \n\
virtual-01@v.${POSTFIX_DOMAIN}     ok \n\
box-01@box.${POSTFIX_DOMAIN}       ok \n\
test@${POSTFIX_DOMAIN}             ok \n\
" > /etc/postfix/check_recipient_access && postmap /etc/postfix/check_recipient_access

RUN echo -e "\n\
hosts=Tool-mysql \n\
user=postfix \n\
password=123456 \n\
dbname=tool_postfix \n\
query=select 'reject' \n\
" > /etc/postfix/check_recipient_access_mysql && postmap /etc/postfix/check_recipient_access_mysql

RUN echo -e "\n\
" > /etc/postfix/check_sender_access && postmap /etc/postfix/check_sender_access

# shadow/saslauthd/系统用户密码/ auth login 后指定发件名
RUN echo -e "\n\
@${POSTFIX_DOMAIN}              nobody@${POSTFIX_DOMAIN} \n\
@v.${POSTFIX_DOMAIN}            nobody@v.${POSTFIX_DOMAIN} \n\
@box.${POSTFIX_DOMAIN}          nobody@box.${POSTFIX_DOMAIN} \n\
local-01@${POSTFIX_DOMAIN}      local-01@${POSTFIX_DOMAIN} \n\
local-02@${POSTFIX_DOMAIN}      local-007@${POSTFIX_DOMAIN} \n\
postfix@${POSTFIX_DOMAIN}       postfix@${POSTFIX_DOMAIN} \n\
" > /etc/postfix/smtpd_sender_login_maps && postmap /etc/postfix/smtpd_sender_login_maps \
    && (echo 123456; echo 123456;) | passwd postfix \
    && (echo 123456; echo 123456;) | passwd local-01 \
    && (echo 123456; echo 123456;) | passwd local-02

# smtpd pwcheck_method
RUN echo -e "\n\
pwcheck_method: saslauthd \n\
" > /etc/sasl2/smtpd.conf

EXPOSE 25

CMD newaliases && syslogd && saslauthd -a shadow && postfix start && sh