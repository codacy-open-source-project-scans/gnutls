#!/bin/sh

# Copyright (C) 2014-2018 Nikos Mavrogiannopoulos
# Copyright (C) 2018 Red Hat, Inc.
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
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>

#set -e

: ${srcdir=.}
: ${CERTTOOL=../../src/certtool${EXEEXT}}
: ${DIFF=diff -b -B}
TMPFILE1=certtool-file1.$$.tmp
TMPFILE2=certtool-file2.$$.tmp
PASS="1234"

if test -n "$DISABLE_BASH_TESTS"; then
	exit 77
fi

if ! test -x "${CERTTOOL}"; then
	exit 77
fi

if ! test -z "${VALGRIND}"; then
	VALGRIND="${LIBTOOL:-libtool} --mode=execute ${VALGRIND}"
fi

: ${SETSID=setsid}
if ("$SETSID" --version) >/dev/null 2>&1; then
	${VALGRIND} "${CERTTOOL}" --generate-privkey --rsa --outfile ${TMPFILE1} --pkcs8 --password ${PASS}
	if test $? != 0;then
		echo "private key generation failed"
		exit 1
	fi

	grep 'modulus:' ${TMPFILE1}
	if test $? = 0;then
		cat ${TMPFILE1}
		echo "PKCS#8 file contains text modulus"
		exit 1
	fi

	#check whether password is being honoured
	#some CI runners need GNUTLS_PIN (GNUTLS_PIN=${PASS})
	${SETSID} "${CERTTOOL}" --generate-self-signed --load-privkey ${TMPFILE1} --template ${srcdir}/templates/template-test.tmpl --ask-pass >${TMPFILE2} 2>&1 <<EOF
$PASS
EOF
	if test $? != 0;then
		cat ${TMPFILE2}
		echo "cert generation failed"
		exit 1
	fi

	grep "Enter password" ${TMPFILE2} >/dev/null 2>&1
	if test $? != 0;then
		cat ${TMPFILE2}
		echo "No password was asked"
		exit 1
	fi
fi

#check whether "funny" spaces can be interpreted
id=`${VALGRIND} "${CERTTOOL}" --key-id --infile "${srcdir}/data/funny-spacing.pem" --hash sha1| tr -d '\r'`
rc=$?

if test "${id}" != "1e09d707d4e3651b84dcb6c68a828d2affef7ec3"; then
	echo "Key-ID1 doesn't match the expected: ${id}"
	exit 1
fi

id=`${VALGRIND} "${CERTTOOL}" --key-id --infile "${srcdir}/data/funny-spacing.pem"| tr -d '\r'`
rc=$?

if test "${id}" != "1e09d707d4e3651b84dcb6c68a828d2affef7ec3"; then
	echo "Default key-ID1 doesn't match the expected; did the defaults change? ID: ${id}"
	exit 1
fi

id=`"${CERTTOOL}" --pubkey-info <"${srcdir}/data/funny-spacing.pem"|"${CERTTOOL}" --key-id --hash sha1| tr -d '\r'`
rc=$?

if test "${id}" != "1e09d707d4e3651b84dcb6c68a828d2affef7ec3"; then
	echo "Key-ID2 doesn't match the expected: ${id}"
	exit 1
fi

id=`"${CERTTOOL}" --pubkey-info <"${srcdir}/data/funny-spacing.pem"|"${CERTTOOL}" --key-id --hash sha256| tr -d '\r'`
rc=$?

if test "${id}" != "118e72e3655150c895ecbd19b3634179fb4a87c7a25abefcb11f5d66661d5a4d"; then
	echo "Key-ID3 doesn't match the expected: ${id}"
	exit 1
fi

id=`"${CERTTOOL}" --pubkey-info <"${srcdir}/data/funny-spacing.pem"|"${CERTTOOL}" --key-id --hash sha512| tr -d '\r'`
rc=$?

if test "${id}" != "5e81ba533b1e7b88b3b0834a392c1cd63f8ccbe45f39edf4cb4b6a3e7700b333cfa386c54b1c5704a2b82a20dc417b347bb8f961c339134a91158a134ca6c478"; then
	echo "Key-ID4 doesn't match the expected: ${id}"
	exit 1
fi

#fingerprint
id=`${VALGRIND} "${CERTTOOL}" --fingerprint --infile "${srcdir}/data/funny-spacing.pem"| tr -d '\r'`
rc=$?

if test "${id}" != "8f735c5ddefd723f59b6a3bb2ac0522470c0182f"; then
	echo "Fingerprint doesn't match the expected: 3"
	exit 1
fi

id=`${VALGRIND} "${CERTTOOL}" --fingerprint --hash sha256 --infile "${srcdir}/data/funny-spacing.pem"| tr -d '\r'`
rc=$?

if test "${id}" != "fc5b45b20c489393a457f177572920ac40bacba9d25cea51200822271eaf7d1f"; then
	echo "Fingerprint doesn't match the expected: 4"
	exit 1
fi

id=`${VALGRIND} "${CERTTOOL}" --fingerprint --hash sha512 --infile "${srcdir}/data/funny-spacing.pem"| tr -d '\r'`
rc=$?

if test "${id}" != "c4880390506a849cd2d8289fb8aea8c189e635aff1054faba58658a0f107472b725672c10d2f7f4ca360528b9433db278f544846e5613f9cd4cb4aa2f56a7894"; then
	echo "Fingerprint doesn't match the expected: 5"
	exit 1
fi

# Test whether certtool --outder doesn't output the informational text data

${VALGRIND} "${CERTTOOL}" -i --infile "${srcdir}/data/funny-spacing.pem" --outder --outfile ${TMPFILE1}
if test $? != 0;then
	echo "cert output to DER failed"
	exit 1
fi

grep 'Version:' ${TMPFILE1}
if test $? = 0;then
	echo "found text info in DER certificate"
	exit 1
fi

${VALGRIND} "${CERTTOOL}" -i --infile "${srcdir}/data/commonName.cer" | grep -v "Not After:" > ${TMPFILE1}
if test $? != 0;then
	echo "commonName cert output failed"
	exit 1
fi

${DIFF} "${srcdir}/data/commonName.cer" ${TMPFILE1}
if test $? != 0;then
	exit 1
fi


rm -f ${TMPFILE1} ${TMPFILE2}

export TZ="UTC"

. ${srcdir}/../scripts/common.sh

cat "${srcdir}/../certs/cert-ecc256.pem" "${srcdir}/../certs/ca-cert-ecc.pem"|
${VALGRIND} "${CERTTOOL}" --attime "2012-11-22" --verify-chain
rc=$?

if test "${rc}" != "0"; then
	echo "There was an issue verifying the chain"
	exit 1
fi

exit 0
