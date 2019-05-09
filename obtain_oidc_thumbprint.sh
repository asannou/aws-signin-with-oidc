#!/bin/sh -e
URL=$(grep '"url":' | cut -d'"' -f 4)
HOST=$(echo $URL | cut -d/ -f 3)
JWKS_HOST=$(curl -s https://$HOST/.well-known/openid-configuration | grep '"jwks_uri":' | cut -d'"' -f 4 | cut -d/ -f 3)
THUMBPRINT=$(echo '' | openssl s_client -servername $JWKS_HOST -showcerts -connect $JWKS_HOST:443 2> /dev/null | openssl x509 -fingerprint -noout 2> /dev/null | cut -d= -f 2 | tr -d : |  tr '[A-F]' '[a-f]')
echo '{"thumbprint": "'$THUMBPRINT'"}'
