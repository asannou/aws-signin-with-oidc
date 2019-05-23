#!/bin/sh -e

URL=$(grep '"url":' | cut -d'"' -f 4)
HOST=$(echo $URL | cut -d/ -f 3)
JWKS_HOST=$(curl -s https://$HOST/.well-known/openid-configuration | grep '"jwks_uri":' | cut -d'"' -f 4 | cut -d/ -f 3)

obtain() {
  while read line
  do
    echo '' | openssl s_client -servername $1 -showcerts -connect $line:443 2> /dev/null \
      | openssl x509 -fingerprint -noout 2> /dev/null \
      | cut -d= -f 2 | tr -d : |  tr '[A-F]' '[a-f]'
  done
}

THUMBPRINTS=$(dig $JWKS_HOST +short | obtain $JWKS_HOST | sort -u | xargs)
echo '{"thumbprints":"'$THUMBPRINTS'"}'

