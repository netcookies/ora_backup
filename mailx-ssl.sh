#!/usr/bin/env ksh


#################################Function Define ###############################
function Usage
{
    print "ERROR! Usage: ${0##*/} -f <MAIL_FROM> -u <SMTP_USER> -p <SMTP_PASSWORD> "
}

function print_msg {
    #### Function to print messages with timestamp ####
    msg=$*

    if [ ! -z "${msg}" ]
    then
        curdate=$(date '+%D %T')
        print -- "${curdate} : ${msg}" |tee -a ${LOGFILE}
    else
        print -- "${curdate} :" | tee -a ${LOGFILE}
    fi
}

function setMailrc {
	cat <<-EOF>>/etc/mail.rc
		set from="${MAIL_FROM}"
		set smtp=smtp.qq.com # 设置邮件服务器（注意端口）QQ邮箱这样写即可
		set smtp-auth-user="${SMTP_USER}"  #设置邮件用户登录账号
		set smtp-auth-password="${SMTP_PASSWORD}" #授权码
		set smtp-auth=login
		#set smtp-use-starttls=yes #QQ邮箱中，加上后，会报错，但是邮件可以正常发送
		set ssl-verify=ignore #认证方式
		set nss-config-dir=/root/.certs  #证书地址
	EOF
}

function setMailSsl {
    mkdir -p /root/.certs/
    echo -n | openssl s_client -connect smtp.qq.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ~/.certs/qq.crt
    certutil -A -n "GeoTrust SSL CA" -t "C,," -d ~/.certs -i ~/.certs/qq.crt
    certutil -A -n "GeoTrust Global CA" -t "C,," -d ~/.certs -i ~/.certs/qq.crt
    certutil -L -d /root/.certs
    cd /root/.certs
    certutil -A -n "GeoTrust SSL CA - G3" -t "Pu,Pu,Pu" -d ./ -i qq.crt
}

############################## Function Define End  #############################

######### Parameter define ################
while getopts f:u:p: next; do
        case $next in
                f)
                 MAIL_FROM=$OPTARG
                 ;;
                u)
                 SMTP_USER=$OPTARG
                 ;;
                p)
                 SMTP_PASSWORD=$OPTARG
                 ;;
                *)
                 Usage
                 exit 1
                 ;;
        esac
done

if [ "$MAIL_FROM" == "" ]; then
    print_msg "No mail sender provided."
    Usage
    exit
fi

if [ "$SMTP_USER" == "" ]; then
    print_msg "No smtp user provided."
    Usage
    exit
fi

if [ "$SMTP_PASSWORD" == "" ]; then
    print_msg "No smtp password provided."
    Usage
    exit
fi

setMailrc
setMailSsl

exit 0
