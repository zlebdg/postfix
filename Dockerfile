FROM alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk --update add postfix busybox-extras bash

RUN echo -e "#mail.err /var/log/mail.log \n\
#mail.info /var/log/mail.log \n\
#mail.debug /var/log/mail.log \n\
mail.* /var/log/mail.log" > /etc/syslog.conf

RUN echo -e "\n\
myhostname=mail.xjplus.xyz \n\
mydomain=xjplus.xyz \n\
myorigin=\$mydomain \n\
inet_interfaces=all \n\
mynetworks=0.0.0.0/0 \n\
mydestination=\$myhostname,\$mydomain \n\
relay_domains=\$mydestination \n\
home_mailbox=maildir/" >> /etc/postfix/main.cf

EXPOSE 25

CMD newaliases && syslogd && postfix start && sh