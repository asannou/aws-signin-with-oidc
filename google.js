var GOOGLE_CLIENT_ID = "${client_id}";
var AWS_API_GATEWAY_INVOKE_URL = "${invoke_url}";

var param = parseQueryString();

if (!param["role"]) {
  param["role"] = prompt("role");
}

window.addEventListener("load", function() {
  gapi.load("client:auth2", function() {
    initClient().then(function() {
      var signin = document.getElementById("signin");
      signin.addEventListener("click", handleSignIn);
    });
  });
});

function initClient() {
  return gapi.client.init({
    clientId: GOOGLE_CLIENT_ID,
    scope: "profile",
    cookie_policy: "none"
  }).then(function() {
    var auth = gapi.auth2.getAuthInstance();
    auth.signOut();
    auth.currentUser.listen(handleCurrentUserChange);
  });
}

function handleSignIn() {
  this.setAttribute("disabled", true);
  gapi.auth2.getAuthInstance().signIn({
    prompt: "select_account"
  });
}

function handleCurrentUserChange(user) {
  if (user.isSignedIn()) {
    var id_token = user.getAuthResponse().id_token;
    var email = user.getBasicProfile().getEmail();
    setCredentials(id_token, email, function() {
      if (param["export"]) {
        appendExports();
      } else {
        signin();
      }
    });
  }
}

function setCredentials(id_token, email, callback) {
  var credentials = new AWS.WebIdentityCredentials({
    RoleArn: param["role"],
    RoleSessionName: email,
    WebIdentityToken: id_token
  });
  credentials.refresh(function(err) {
    if (err) {
      alert(err);
    } else {
      callback();
    }
  });
  AWS.config.credentials = credentials;
}

function signin() {
  var credentials = AWS.config.credentials;
  var session = {
    sessionId: credentials.accessKeyId,
    sessionKey: credentials.secretAccessKey,
    sessionToken: credentials.sessionToken
  };
  location.href = AWS_API_GATEWAY_INVOKE_URL + "/federation?" + [
    "Action=getSigninToken",
    "SessionDuration=43200",
    "Session=" + encodeURIComponent(JSON.stringify(session))
  ].join("&");
}

function appendExports() {
  var input = document.createElement("input");
  input.value = exportCredentials();
  input.addEventListener("click", function() {
    this.select(0, this.value.length);
  });
  document.body.appendChild(input);
}

function exportCredentials() {
  var credentials = AWS.config.credentials;
  return [
    "export AWS_ACCESS_KEY_ID=" + credentials.accessKeyId,
    "export AWS_SECRET_ACCESS_KEY=" + credentials.secretAccessKey,
    "export AWS_SESSION_TOKEN=" + credentials.sessionToken
  ].join("; ");
}

function parseQueryString() {
  var param = {};
  var string = location.search.substring(1).split("&");
  string.forEach(function(s) {
    s = s.split("=");
    param[s[0]] = decodeURIComponent(s[1]);
  });
  return param;
}

