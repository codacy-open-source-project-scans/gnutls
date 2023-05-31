#!/bin/bash

# Copyright (C) 2017 Red Hat, Inc.
#
# This file is part of GnuTLS.
#
# GnuTLS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GnuTLS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GnuTLS.  If not, see <https://www.gnu.org/licenses/>.

: ${srcdir=.}

tls_fuzzer_prepare() {
PRIORITY="NORMAL:+ARCFOUR-128:%VERIFY_ALLOW_SIGN_WITH_SHA1:+3DES-CBC:+DHE-DSS:+SIGN-DSA-SHA256:+SIGN-DSA-SHA1:-CURVE-SECP192R1:+VERS-SSL3.0"
${CLI} --list --priority "${PRIORITY}" >/dev/null 2>&1
if test $? != 0;then
	PRIORITY="NORMAL:+ARCFOUR-128:%VERIFY_ALLOW_SIGN_WITH_SHA1:+3DES-CBC:+DHE-DSS:+SIGN-DSA-SHA256:+SIGN-DSA-SHA1:+VERS-SSL3.0"
fi

sed -e "s|@SERVER@|$SERV|g" -e "s/@PORT@/$PORT/g" -e "s/@PRIORITY@/$PRIORITY/g" ../gnutls-cert.json >${TMPFILE}
}

. "${srcdir}/tls-fuzzer/tls-fuzzer-common.sh"
