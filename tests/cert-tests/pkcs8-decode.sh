#!/bin/sh

# Copyright (C) 2004-2006, 2010, 2012 Free Software Foundation, Inc.
#
# Author: Simon Josefsson
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
: ${CERTTOOL=../../src/certtool${EXEEXT}}
: ${DIFF=diff -b -B}
TMPFILE=pkcs8-decode.$$.tmp

if ! test -x "${CERTTOOL}"; then
	exit 77
fi

if test "${GNUTLS_FORCE_FIPS_MODE}" = 1;then
	echo "Cannot run in FIPS140-2 mode"
	exit 77
fi

if ! test -z "${VALGRIND}"; then
	VALGRIND="${LIBTOOL:-libtool} --mode=execute ${VALGRIND}"
fi

ret=0
for p8 in "pkcs8-pbes1-des-md5.pem password" "encpkcs8.pem foobar" "unencpkcs8.pem" "enc2pkcs8.pem baz" "pkcs8-pbes2-sha256.pem password"; do
	set -- ${p8}
	file="$1"
	passwd="$2"
	${VALGRIND} "${CERTTOOL}" --key-info --pkcs8 --password "${passwd}" \
		--infile "${srcdir}/data/${file}"
	rc=$?
	if test ${rc} != 0; then
		echo "PKCS8 FATAL ${p8}"
		ret=1
	else
		echo "PKCS8 OK ${p8}"
	fi
done

for p8 in "der-key-PBE-SHA1-DES.p8 booo"; do
	set -- ${p8}
	file="$1"
	passwd="$2"
	${VALGRIND} "${CERTTOOL}" --key-info --pkcs8 --inder \
		    --password "${passwd}" --infile "${srcdir}/data/${file}"
	rc=$?
	if test ${rc} != 0; then
		echo "PKCS8 FATAL ${p8}"
		ret=1
	else
		echo "PKCS8 OK ${p8}"
	fi
done

for p8 in "openssl-aes128.p8" "openssl-aes256.p8" "openssl-3des.p8"; do
	set -- ${p8}
	file="$1"
	passwd="$2"
	${VALGRIND} "${CERTTOOL}" --p8-info --password "1234" \
		--infile "${srcdir}/data/${file}" --outfile $TMPFILE
	rc=$?
	if test ${rc} != 0; then
		echo "PKCS8 FATAL ${p8}"
		ret=1
	fi

	${DIFF} "${srcdir}/data/${p8}.txt" $TMPFILE
	rc=$?
	if test ${rc} != 0; then
		cat $TMPFILE
		echo "PKCS8 FATAL TXT ${p8}"
		ret=1
	fi
done
rm -f $TMPFILE

echo "PKCS8 DONE (rc $ret)"
exit $ret
