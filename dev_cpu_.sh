#!/bin/sh
# -*- sh -*-
#
# Copyright (c) 2008 Dag-Erling Coïdan Smørgrav
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer
#    in this position and unchanged.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id$
#

#%# family=auto
#%# capabilities=autoconf suggest

# Munin plugin for CPU temperature and frequency on FreeBSD

# Apparently sysctl is in /bin on Debian GNU/kFreeBSD. basename is in /usr/bin.
export PATH=/sbin:/usr/bin:/bin

die() {
        echo "$@" 1>&2
        exit 1
}

cpus() {
        sysctl -N dev.cpu | awk -F. '$4 == "'"$func"'" { print $3 }'
}

reqcpus() {
        if [ -z "$func" ] ; then
                die "No function specified"
        fi
        cpus=$(cpus)
        if [ -z "$cpus" ] ; then
                die "No supported CPUs"
        fi
}

autoconf() {
        if [ -n "$cpus" ] ; then
                echo "yes"
                exit 0
        else
                echo "no (function not supported by kernel)"
                exit 0
        fi
}

suggest() {
        if [ -n "$func" ] ; then
                echo "$func"
                exit 0
        fi

        # Suggest output must be newline separated, so get in newlines
        # and preserve them.
        for func in freq temperature ; do
                if cpus >/dev/null ; then
                        funcs="$funcs
$func"
                fi
        done
        [ -n "$funcs" ] && echo "$funcs"
        exit $?
}

config() {
        reqcpus
        echo -n "graph_order"
        for cpu in $cpus ; do
                echo -n " CPU$cpu"
        done
        echo ""
        echo "graph_category system"
        echo "graph_scale no"
        case $func in
        freq)
                echo "graph_title CPU Frequency"
                echo "graph_vlabel Frequency in MHz"
                ;;
        temperature)
                echo "graph_title CPU Core Temperature"
                echo "graph_vlabel Core temperature in °C"
                for cpu in $cpus ; do
                 echo "CPU$cpu.warning ${temp_warning:-60}"
                 echo "CPU$cpu.critical ${temp_critical:-75}"
                done
                ;;
        esac
        for cpu in $cpus ; do
                echo "CPU$cpu.label CPU $cpu"
        done
        exit 0
}

get() {
        reqcpus
        for cpu in $cpus ; do
                echo -n "CPU$cpu.value "
                sysctl -n "dev.cpu.$cpu.$func" | tr -d 'C'
        done
}

self=$(basename $0)
func=${self##*_}

case "$*" in
autoconf)
        autoconf
        ;;
suggest)
        suggest
        ;;
config)
        config
        ;;
"")
        get
        ;;
*)
        die "usage: $self [autoconf|config]"
        ;;
esac

exit 0
