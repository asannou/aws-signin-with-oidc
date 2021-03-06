class AmazonS3OIDCGoogle {

  constructor(args) {
    this.clientId = args.clientId;
    this.role = args.role;
    const url = this.parseUrl(args.url);
    this.bucket = url.bucket;
    this.key = url.key;
  }

  async initAuth() {
    await this.promisify(gapi.load.bind(gapi))("auth2");
    await gapi.auth2.init({ clientId: this.clientId });
    this.auth = gapi.auth2.getAuthInstance();
    this.auth.currentUser.listen(() => this.navigateToSignedUrl());
  }

  navigateToSignedUrl() {
    const user = this.auth.currentUser.get();
    if (user.isSignedIn()) {
      const id_token = user.getAuthResponse().id_token;
      const email = user.getBasicProfile().getEmail();
      return this.setCredentials(id_token, email)
        .then(() => {
          location.href = this.getSignedUrl();
          return this.sleep(10000);
        })
        .catch((err) => {
          alert(err);
          this.showButton();
          return this.signOut();
        });
    }
  }

  renderButton(id, options) {
    this.button = document.getElementById(id);
    Object.assign(options, {
      scope: "profile",
      onsuccess: () => this.hideButton(),
      onfailure: console.log
    });
    return gapi.signin2.render(id, options);
  }

  showButton() {
    this.button.style.display = "block";
  }

  hideButton() {
    this.button.style.display = "none";
  }

  signOut() {
    return this.auth.signOut();
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

  sleep(msec) {
    return new Promise((resolve) => setTimeout(resolve, msec));
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
