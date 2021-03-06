#!/usr/local/bin/bash
#
# smtp_hello_ - munin plugin for measuring smtp hello response
# Copyright (C) 2008 Marek Mahut <mmahut@fedoraproject.org>
#
# Usage:
# ln -s /usr/share/munin/plugins/smtp_hello_ /etc/munin/plugins/smtp_hello_mysmtpserver.example.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
#$log$
#Revision 1.0 2008/12/15 17:21:58 Marek Mahut (mmahut)
#Initial commit.
#
#%# family=auto
#%# capabilities=autoconf


host=`basename $0 | sed 's/^smtp_hello_//g'`

if [ "$1" == "config" ]; then

        echo "graph_title SMTP server response time"
        echo "graph_vlabel response in sec"
        echo "graph_period minute"
        echo "graph_category mail"
        echo "graph_args --base 1000 --lower-limit 0"
        echo "host25.label $host:25"
        echo "host587.label $host:587"
        echo "host465.label $host:465"

elif [ "$1" == "autoconf" ]; then

        if [ -x /usr/bin/time ] && [ -x /usr/bin/nc ]; then
                echo "yes"
                exit 0
        else
                echo "no (/usr/bin/time or /usr/bin/nc missing)"
                exit 1
        fi

else

        response=`echo HELO localhost | /usr/bin/time /usr/bin/nc -w 120 $host 25 2>&1 | tail -n 1 | awk '{print $1}'`
        echo "host25.value $response"
        response=`echo HELO localhost | /usr/bin/time /usr/bin/nc -w 120 $host 587 2>&1 | tail -n 1 | awk '{print $1}'`
        echo "host587.value $response"
        response=`echo HELO localhost | /usr/bin/time /usr/bin/nc -w 120 $host 465 2>&1 | tail -n 1 | awk '{print $1}'`
        echo "host465.value $response"

fi
