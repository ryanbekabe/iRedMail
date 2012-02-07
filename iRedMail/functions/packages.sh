#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb(at)iredmail.org>

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

install_all()
{
    ALL_PKGS=''
    ENABLED_SERVICES=''
    DISABLED_SERVICES=''

    ###########################
    # Enable syslog or rsyslog.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        # RHEL/CENTOS, SuSE
        if [ -x ${DIR_RC_SCRIPTS}/syslog ]; then
            ENABLED_SERVICES="syslog ${ENABLED_SERVICES}"
        elif [ -x ${DIR_RC_SCRIPTS}/rsyslog ]; then
            ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
        fi
        DISABLED_SERVICES="${DISABLED_SERVICES} exim"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # Debian.
        ENABLED_SERVICES="network syslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"DEBIAN" ]; then
        # Debian.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"UBUNTU" ]; then
        # Ubuntu.
        if [ X"${DISTRO_CODENAME}" == X"hardy" \
            -o X"${DISTRO_CODENAME}" == X"intrepid" \
            -o X"${DISTRO_CODENAME}" == X"jaunty" ]; then
            # Ubuntu <= 9.04.
            ENABLED_SERVICES="sysklogd ${ENABLED_SERVICES}"
        else
            # Ubuntu >= 9.10.
            ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
        fi
    elif [ X"${DISTRO}" == X"GENTOO" ]; then
        ENABLED_SERVICES="syslog-ng ${ENABLED_SERVICES}"
    fi

    #################################################
    # Backend: OpenLDAP, MySQL, PGSQL and extra packages.
    #
    if [ X"${BACKEND}" == X"OPENLDAP" ]; then
        # OpenLDAP server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap${PKG_ARCH} openldap-clients${PKG_ARCH} openldap-servers${PKG_ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${LDAP_RC_SCRIPT_NAME}"

            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-server${PKG_ARCH} mysql${PKG_ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysqld"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} openldap2 openldap2-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} ldap"

            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-community-server mysql-community-server-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-ldap slapd ldap-utils libnet-ldap-perl"
            ENABLED_SERVICES="${ENABLED_SERVICES} slapd"

            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-server mysql-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
        elif [ X"${DISTRO}" == X"GENTOO" ]; then
            ALL_PKGS="${ALL_PKGS} net-nds/openldap"
            ENABLED_SERVICES="${ENABLED_SERVICES} slapd"
            gentoo_add_use_flags 'net-nds/openldap' 'berkdb crypt ipv6 ssl tcpd overlays perl sasl syslog'

            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} dev-db/mysql"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
            gentoo_add_use_flags 'dev-db/mysql' 'berkdb community perl ssl big-tables cluster'
        fi
    elif [ X"${BACKEND}" == X"MYSQL" ]; then
        # MySQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-server${PKG_ARCH} mysql${PKG_ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysqld"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-community-server mysql-community-server-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"

            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} postfix-mysql apache2-mod_auth_mysql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-server mysql-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"

            # Postfix module
            ALL_PKGS="${ALL_PKGS} postfix-mysql"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql"

        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} dev-db/mysql"
            ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
            gentoo_add_use_flags 'dev-db/mysql' 'berkdb community perl ssl big-tables cluster'
        fi
    elif [ X"${BACKEND}" == X"PGSQL" ]; then
        export USE_IREDAPD='NO'

        # PGSQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server"
            ENABLED_SERVICES="${ENABLED_SERVICES} postgresql"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server"
            ENABLED_SERVICES="${ENABLED_SERVICES} postgresql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # postgresql-contrib provides extension 'dblink' used in Roundcube password plugin.
            ALL_PKGS="${ALL_PKGS} postgresql postgresql-client postgresql-contrib"
            ENABLED_SERVICES="${ENABLED_SERVICES} postgresql"

            # Postfix module
            ALL_PKGS="${ALL_PKGS} postfix-pgsql"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} dev-db/postgresql-server"
            ENABLED_SERVICES="${ENABLED_SERVICES} postgresql-${PGSQL_VERSION}"
            gentoo_add_use_flags 'dev-db/postgresql-server' 'nls pam doc perl python xml'

        fi
    fi

    #################
    # Apache and PHP.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} httpd${PKG_ARCH} mod_ssl${PKG_ARCH} php${PKG_ARCH} php-common${PKG_ARCH} php-gd${PKG_ARCH} php-xml${PKG_ARCH} php-mysql${PKG_ARCH} php-ldap${PKG_ARCH}"
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} php-imap${PKG_ARCH} libmcrypt${PKG_ARCH} php-mcrypt${PKG_ARCH} php-mhash${PKG_ARCH} php-mbstring${PKG_ARCH}"
        fi
        ENABLED_SERVICES="${ENABLED_SERVICES} httpd"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} apache2-prefork apache2-mod_php5 php5-iconv php5-ldap php5-mysql php5-mcrypt php5-mbstring php5-gettext php5-dom php5-json php5-intl php5-fileinfo"
        if [ X"${DISTRO_VERSION}" == X"11.3" -o X"${DISTRO_VERSION}" == X"11.4" ]; then
            ALL_PKGS="${ALL_PKGS} php5-hash"
        fi
        ENABLED_SERVICES="${ENABLED_SERVICES} apache2"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} apache2 apache2-mpm-prefork apache2.2-common libapache2-mod-php5 php5-cli php5-imap php5-gd php5-mcrypt php5-mysql php5-ldap php5-pgsql"

        # Authentication modules
        ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql libapache2-mod-auth-pgsql"

        if [ X"${DISTRO_CODENAME}" != X"oneiric" ]; then
            ALL_PKGS="${ALL_PKGS} php5-mhash"
        fi

        if [ X"${DISTRO_CODENAME}" == X"lucid" \
            -o X"${DISTRO_CODENAME}" == X"natty" \
            -o X"${DISTRO_CODENAME}" == X"oneiric" \
            ]; then
            if [ X"${BACKEND}" == X"OPENLDAP" ]; then
                ALL_PKGS="${ALL_PKGS} php-net-ldap2"
            fi
        fi

        ENABLED_SERVICES="${ENABLED_SERVICES} apache2"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} www-servers/apache dev-lang/php"
        ENABLED_SERVICES="${ENABLED_SERVICES} apache2"
        gentoo_add_use_flags 'dev-libs/apr-util' 'ldap'
        gentoo_add_use_flags 'www-servers/apache' 'ssl doc ldap suexec'
        gentoo_add_make_conf 'APACHE2_MODULES' 'actions alias auth_basic authn_alias authn_anon authn_dbm authn_default authn_file authz_dbm authz_default authz_groupfile authz_host authz_owner authz_user autoindex cache cgi cgid dav dav_fs dav_lock deflate dir disk_cache env expires ext_filter file_cache filter headers include info log_config logio mem_cache mime mime_magic negotiation rewrite setenvif speling status unique_id userdir usertrack vhost_alias auth_digest authn_dbd log_forensic proxy proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_http proxy_scgi substitute version'
        gentoo_add_make_conf 'APACHE2_MPMS' 'prefork'

        gentoo_add_use_flags 'dev-lang/php' 'berkdb bzip2 cli crypt ctype fileinfo filter hash iconv ipv6 json nls phar posix readline session simplexml ssl tokenizer unicode xml zlib apache2 calendar -cdb cgi cjk curl curlwrappers doc flatfile fpm ftp gd gmp imap inifile intl kerberos ldap ldap-sasl mhash mysql mysqli mysqlnd odbc pdo postgres snmp soap sockets spell sqlite sqlite3 suhosin tidy truetype wddx xmlreader xmlrpc xmlwriter xpm xsl zip'
    fi

    ###############
    # Postfix.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix${PKG_ARCH}"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # On OpenSuSE, postfix already has ldap_table support.
        ALL_PKGS="${ALL_PKGS} postfix"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} mail-mta/postfix"
        gentoo_unmark_package 'mail-mta/ssmtp'
        gentoo_add_use_flags 'mail-mta/postfix' 'ipv6 pam ssl cdb dovecot-sasl hardened ldap ldap-bind mbox mysql postgres sasl'
    fi

    ENABLED_SERVICES="${ENABLED_SERVICES} postfix"

    # Policyd.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} policyd${PKG_ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} policyd"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} policyd"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        if [ X"${DISTRO_CODENAME}" == X"oneiric" ]; then
            # Policyd-2.x, code name "cluebringer".
            ALL_PKGS="${ALL_PKGS} postfix-cluebringer postfix-cluebringer-webui"
            ENABLED_SERVICES="${ENABLED_SERVICES} postfix-cluebringer"

            if [ X"${BACKEND}" == X"OPENLDAP" -o X"${BACKEND}" == X"MYSQL" ]; then
                ALL_PKGS="${ALL_PKGS} postfix-cluebringer-mysql"
            elif [ X"${BACKEND}" == X"PGSQL" ]; then
                ALL_PKGS="${ALL_PKGS} postfix-cluebringer-pgsql"
            fi
        else
            ALL_PKGS="${ALL_PKGS} postfix-policyd"
            ENABLED_SERVICES="${ENABLED_SERVICES} postfix-policyd"
        fi


        if [ X"${DISTRO_CODENAME}" == X"lucid" ]; then
            # Don't invoke dbconfig-common on Ubuntu.
            dpkg-divert --rename /etc/dbconfig-common/postfix-policyd.conf
            mkdir -p /etc/dbconfig-common/ 2>/dev/null
            cat > /etc/dbconfig-common/postfix-policyd.conf <<EOF
dbc_install='true'
dbc_upgrade='false'
dbc_remove=''
dbc_dbtype='mysql'
dbc_dbuser='postfix-policyd'
dbc_dbpass="${POLICYD_DB_PASSWD}"
dbc_dbserver=''
dbc_dbport=''
dbc_dbname='postfixpolicyd'
dbc_dbadmin='root'
dbc_basepath=''
dbc_ssl=''
dbc_authmethod_admin=''
dbc_authmethod_user=''
EOF
        fi
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} mail-filter/policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} policyd"
    fi

    # Dovecot.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot${PKG_ARCH} dovecot-sieve${PKG_ARCH} dovecot-managesieve${PKG_ARCH}"
        elif [ X"${DISTRO_VERSION}" == X"6" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot${PKG_ARCH} dovecot-managesieve${PKG_ARCH} dovecot-pigeonhole${PKG_ARCH}"
        fi

        # We will use Dovecot SASL auth mechanism, so 'saslauthd'
        # is not necessary, should be disabled.
        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot12"

        if [ X"${BACKEND}" == X"MYSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot12-backend-mysql"
        elif [ X"${BACKEND}" == X"PGSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot12-backend-pgsql"
        fi

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d"

        if [ X"${DISTRO_CODENAME}" == X"oneiric" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-managesieved dovecot-sieve"

            if [ X"${BACKEND}" == X"OPENLDAP" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-ldap dovecot-mysql"
            elif [ X"${BACKEND}" == X"MYSQL" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-mysql"
            elif [ X"${BACKEND}" == X"PGSQL" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-pgsql"
            fi
        fi
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} net-mail/dovecot"
        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"
        gentoo_add_use_flags 'net-mail/dovecot' 'bzip2 ipv6 maildir pam ssl zlib caps doc kerberos ldap managesieve mbox mdbox mysql postgres sdbox sieve sqlite suid'
    fi

    ENABLED_SERVICES="${ENABLED_SERVICES} dovecot"

    # Amavisd-new & ClamAV & Altermime.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} clamd${PKG_ARCH} clamav${PKG_ARCH} clamav-db${PKG_ARCH} spamassassin${PKG_ARCH} altermime${PKG_ARCH} perl-LDAP.noarch"
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} amavisd-new${PKG_ARCH} perl-IO-Compress.noarch"
        else
            ALL_PKGS="${ALL_PKGS} amavisd-new.noarch"
        fi
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamd"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new clamav clamav-db spamassassin altermime perl-ldap perl-DBD-mysql"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamd freshclam"
        DISABLED_SERVICES="${DISABLED_SERVICES} clamav-milter spamd spampd"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl clamav-freshclam clamav-daemon spamassassin altermime arj zoo nomarch cpio lzop cabextract p7zip rpm unrar-free ripole"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamav-daemon clamav-freshclam"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} mail-filter/amavisd-new mail-filter/spamassassin app-antivirus/clamav net-mail/altermime"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamd"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamd"

        gentoo_add_use_flags 'mail-filter/amavisd-new' 'dkim ldap mysql postgres razor snmp spamassassin'
        gentoo_add_use_flags 'mail-filter/spamassassin' 'berkdb ipv6 ssl doc ldap mysql postgres sqlite'
        gentoo_add_use_flags 'app-antivirus/clamav' 'bzip2 iconv ipv6'
    fi

    # SPF verification.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        # SPF implemention via perl-Mail-SPF.
        ALL_PKGS="${ALL_PKGS} perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # SPF implemention via perl-Mail-SPF.
        ALL_PKGS="${ALL_PKGS} perl-Mail-SPF"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} libmail-spf-perl"

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} dev-perl/Mail-SPF"
    fi

    # phpPgAdmin
    if [ X"${USE_PHPPGADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            :
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} phpPgAdmin"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} phppgadmin"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} dev-db/phppgadmin"
        fi
    fi

    ############
    # iRedAPD.
    #
    if [ X"${USE_IREDAPD}" == X"YES" ]; then
        [ X"${DISTRO}" == X"RHEL" ] && ALL_PKGS="${ALL_PKGS} python-ldap${PKG_ARCH}"
        [ X"${DISTRO}" == X"SuSE" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
        [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
        # Don't append 'iredapd' to ${ENABLED_SERVICES} since we don't have
        # RC script ready in early stage.
        #ENABLED_SERVICES="${ENABLED_SERVICES} iredapd"
    fi

    # iRedAdmin.
    # Force install all dependence to help customers install iRedAdmin-Pro.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} python-jinja2${PKG_ARCH} python-webpy.noarch MySQL-python${PKG_ARCH} mod_wsgi${PKG_ARCH}"
        [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap${PKG_ARCH}"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} apache2-mod_wsgi python-jinja2 python-mysql python-xml"

        # Note: Web.py will be installed locally with command 'easy_install'.
        if [ X"${DISTRO_VERSION}" == X"11.3" -o X"${DISTRO_VERSION}" == X"11.4" ]; then
            ALL_PKGS="${ALL_PKGS} python-setuptools"
        else
            ALL_PKGS="${ALL_PKGS} python-distribute"
        fi
        [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} libapache2-mod-wsgi python-mysqldb python-jinja2 python-netifaces python-webpy"
        [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} dev-python/jinja dev-python/webpy dev-python/mysql-python"
        [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} dev-python/python-ldap"

        gentoo_add_use_flags 'dev-python/jinja' 'doc examples i18n vim-syntax'
    fi

    #############
    # Awstats.
    #
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch"
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} www-misc/awstats"
            gentoo_add_use_flags 'www-misc/awstats' 'ipv6 geoip'
        fi
    fi

    #### Fail2ban ####
    if [ X"${USE_FAIL2BAN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" -o \
            X"${DISTRO}" == X"DEBIAN" -o \
            X"${DISTRO}" == X"UBUNTU" -o \
            X"${DISTRO}" == X"SUSE" \
            ]; then
            ALL_PKGS="${ALL_PKGS} fail2ban"
            ENABLED_SERVICES="${ENABLED_SERVICES} fail2ban"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} net-analyzer/fail2ban"
            ENABLED_SERVICES="${ENABLED_SERVICES} fail2ban"
        fi

        if [ X"${DISTRO}" == X"RHEL" ]; then
            DISABLED_SERVICES="${DISABLED_SERVICES} shorewall"
        fi
    fi


    ############################
    # Misc packages & services.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2${PKG_ARCH} acl${PKG_ARCH} patch${PKG_ARCH} tmpwatch${PKG_ARCH} crontabs.noarch dos2unix${PKG_ARCH}"
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} vixie-cron${PKG_ARCH}"
        fi
        ENABLED_SERVICES="${ENABLED_SERVICES} crond"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tmpwatch dos2unix"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tofrodos"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} app-text/dos2unix"
    fi
    #### End Misc packages & services ####

    # Disable Ubuntu firewall rules, we have iptables init script and rule file.
    [ X"${DISTRO}" == X"UBUNTU" ] && export DISABLED_SERVICES="${DISABLED_SERVICES} ufw"

    # Debian 6 and Ubuntu 10.04/10.10 special.
    # Install binary packages of phpldapadmin-1.2.x and phpMyAdmin-3.x.
    if [ X"${DISTRO_CODENAME}" == X"lucid" -o X"${DISTRO_CODENAME}" == X"squeeze" ]; then
        # Install phpLDAPadmin.
        if [ X"${USE_PHPLDAPADMIN}" == X"YES" ]; then
            ALL_PKGS="${ALL_PKGS} phpldapadmin"
        fi

        # Install phpMyAdmin-3.x.
        if [ X"${USE_PHPMYADMIN}" == X"YES" ]; then
            ALL_PKGS="${ALL_PKGS} phpmyadmin"
        fi
    fi
    #
    # ---- End Ubuntu 10.04 special. ----
    #

    export ALL_PKGS ENABLED_SERVICES

    # Install all packages.
    install_all_pkgs()
    {
        # Remove 'patterns-openSUSE-minimal_base' on OpenSuSE-11.4 before install.
        if [ X"${DISTRO}" == X"SUSE" -a X"${DISTRO_VERSION}" == X"11.4" ]; then
            rpm -e patterns-openSUSE-minimal_base
        fi

        # Install all packages.
        eval ${install_pkg} ${ALL_PKGS}

        if [ X"${DISTRO}" == X"SUSE" -a X"${USE_IREDADMIN}" == X"YES" ]; then
            ECHO_DEBUG "Install web.py (${MISC_DIR}/web.py-*.tar.bz)."
            easy_install ${MISC_DIR}/web.py-*.tar.gz >/dev/null
        fi
        echo 'export status_install_all_pkgs="DONE"' >> ${STATUS_FILE}
    }

    # Enable/Disable services.
    enable_all_services()
    {
        # Enable services.
        eval ${enable_service} ${ENABLED_SERVICES} >/dev/null

        # Disable services.
        eval ${disable_service} ${DISABLED_SERVICES} >/dev/null

        if [ X"${DISTRO}" == X"SUSE" ]; then
            eval ${disable_service} SuSEfirewall2_setup SuSEfirewall2_init >/dev/null
        fi

        echo 'export status_enable_all_services="DONE"' >> ${STATUS_FILE}
    }

    check_status_before_run install_all_pkgs
    check_status_before_run enable_all_services
}
