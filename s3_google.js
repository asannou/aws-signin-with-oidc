class AmazonS3OIDCGoogle {

  constructor(clientId, role, url) {
    this.clientId = clientId;
    this.role = role;
    url = this.parseUrl(url);
    this.bucket = url.bucket;
    this.key = url.key;
  }

  async initClient() {
    await this.promisify(gapi.load.bind(gapi))("client:auth2");
    await gapi.client.init({
      clientId: this.clientId,
      scope: "profile",
      cookie_policy: "none"
    });
    const auth = gapi.auth2.getAuthInstance();
    await auth.signOut();
    auth.currentUser.listen(this.handleCurrentUserChange.bind(this));
  }

  signIn() {
    return gapi.auth2.getAuthInstance().signIn({
      prompt: "select_account"
    });
  }

  handleCurrentUserChange(user) {
    if (user.isSignedIn()) {
      const id_token = user.getAuthResponse().id_token;
      const email = user.getBasicProfile().getEmail();
      this.setCredentials(id_token, email)
        .then(() => location.href = this.getSignedUrl())
        .catch((err) => console.log(err));
    }
  }

  setCredentials(id_token, email) {
    const credentials = new AWS.WebIdentityCredentials({
      RoleArn: this.role,
      RoleSessionName: email,
      WebIdentityToken: id_token
    });
    AWS.config.credentials = credentials;
    return this.promisify(credentials.refresh.bind(credentials))();
  }

  getSignedUrl() {
    const s3 = new AWS.S3();
    return s3.getSignedUrl("getObject", {
      Bucket: this.bucket,
      Key: this.key,
      Expires: 60
    });
  }

  parseUrl(url) {
    const parser = document.createElement("a");
    parser.href = url;
    const path = parser.pathname.split("/").slice(1);
    return {
      bucket: path.shift(),
      key: path.join("/")
    };
  }

  promisify(original) {
    return (...args) => new Promise((resolve, reject) => {
      original(...args, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  static parseQueryString() {
    const string = location.search.substring(1).split("&");
    const param = {};
    string.forEach((s) => {
      s = s.split("=");
      param[s[0]] = decodeURIComponent(s[1]);
    });
    return param;
  }

}
