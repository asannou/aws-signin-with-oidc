var S3Google = function(clientId) {
  this.clientId = clientId;
  this.param = {};
  var query = location.search.substring(1).split("&");
  query.forEach((q) => {
    q = q.split("=");
    this.param[q[0]] = decodeURIComponent(q[1]);
  });
};

S3Google.prototype.initClient = function() {
  return gapi.client.init({
    clientId: this.clientId,
    scope: "profile",
    cookie_policy: "none"
  }).then(() => {
    var auth = gapi.auth2.getAuthInstance();
    auth.signOut();
    auth.currentUser.listen(this.handleCurrentUserChange.bind(this));
  });
};

S3Google.prototype.handleSignIn = function() {
  gapi.auth2.getAuthInstance().signIn({
    prompt: "select_account"
  });
};

S3Google.prototype.handleCurrentUserChange = function(user) {
  if (user.isSignedIn()) {
    var id_token = user.getAuthResponse().id_token;
    var email = user.getBasicProfile().getEmail();
    this.setCredentials(id_token, email, () => this.navigateToSignedUrl());
  }
}

S3Google.prototype.setCredentials = function(id_token, email, callback) {
  var credentials = new AWS.WebIdentityCredentials({
    RoleArn: this.param["role"],
    RoleSessionName: email,
    WebIdentityToken: id_token
  });
  credentials.refresh((err) => {
    if (err) {
      alert(err);
    } else {
      callback();
    }
  });
  AWS.config.credentials = credentials;
}

S3Google.prototype.navigateToSignedUrl = function() {
  var url = decodeURIComponent(this.param["url"]);
  var parsed = this.parseUrl(url);
  this.getSignedUrl(parsed.bucket, parsed.key, (signedUrl) => {
    location.href = signedUrl;
  });
}

S3Google.prototype.parseUrl = function(url) {
  var parser = document.createElement("a");
  parser.href = url;
  var path = parser.pathname.split("/").slice(1);
  return {
    bucket: path.shift(),
    key: path.join("/")
  };
}

S3Google.prototype.getSignedUrl = function(bucket, key, callback) {
  var s3 = new AWS.S3();
  s3.getSignedUrl("getObject", {
    Bucket: bucket,
    Key: key,
    Expires: 60
  }, (err, url) => {
    if (err) {
      alert(err);
    } else {
      callback(url);
    }
  });
}

window.addEventListener("load", function() {
  gapi.load("client:auth2", () => {
    var s3g = new S3Google("${client_id}");
    s3g.initClient().then(() => {
      var button = document.getElementById("getobject");
      button.addEventListener("click", (e) => {
        e.target.setAttribute("disabled", true);
        s3g.handleSignIn();
      });
    });
  });
});

