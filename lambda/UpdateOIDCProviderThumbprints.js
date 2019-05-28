'use strict';

const util = require('util');
const request = util.promisify(require('request'));
const url = require('url');
const resolve4 = util.promisify(require('dns').resolve4);
const tls = require('tls');

const AWS = require('aws-sdk');
const iam = new AWS.IAM();
const get = iam.getOpenIDConnectProvider.bind(iam);
const update = iam.updateOpenIDConnectProviderThumbprint.bind(iam);

const arn = process.env.OIDC_PROVIDER_ARN;

const connect = (port, address, servername) => {
  return new Promise((resolve, reject) => {
    const options = { servername: servername };
    const socket = tls.connect(port, address, options, () => {
      socket.end();
      const cert = socket.getPeerCertificate();
      if (socket.authorized) {
        resolve(cert.fingerprint.replace(/:/g, '').toLowerCase());
      } else {
        reject();
      }
    });
  });
};

const uniq = (array) => Array.from(new Set(array));

exports.handler = async (event, context, callback) => {
  const params = { OpenIDConnectProviderArn: arn };
  const provider = await get(params).promise();
  const response = await request(`https://${provider.Url}/.well-known/openid-configuration`);
  const config = JSON.parse(response.body);
  const jwksUri = url.parse(config.jwks_uri);
  const port = jwksUri.port || 443;
  const addresses = await resolve4(jwksUri.hostname);
  const hostname = jwksUri.hostname;
  const connects = addresses.map((address) => connect(port, address, hostname));
  const thumbprints = await Promise.all(connects);
  params.ThumbprintList = uniq(provider.ThumbprintList.concat(thumbprints));
  const data = await update(params).promise();
  callback(null, data);
};

