/**
 * Created by Kadhir on 9/17/16.
 */

function User() {
    console.log(localStorage["Facebook_ID"]);
}

(function(d, s, id) {
    var js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return;
    js = d.createElement(s); js.id = id;
    js.src = "//connect.facebook.net/en_US/sdk.js";
    fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

/* Logs out of Facebook SDK. */
function facebookLogout() {
    FB.init({
        appId      : '1549697168604262',
        cookie     : true,  // enable cookies to allow the server to access
                            // the session
        xfbml      : true,  // parse social plugins on this page
        version    : 'v2.5' // use graph api version 2.5
    });
    FB.getLoginStatus(function(response){
        if (response.status != "connected") {
            goeLogout();
        } else {
            FB.logout(goeLogout(response));
        }

    });
}

window.onload = function() {
    setUserName();
};

/* Sets the user name in the menu bar. */
function setUserName() {
    var tempName = localStorage["Username"].split(".");
    document.getElementById("username_menu").textContent = tempName[0] + " " + tempName[1][0];
}

/* Logs out of goe by clearing the local cache and the moves the window ref. */
function goeLogout(response) {
    localStorage["Facebook_ID"] = "";
    localStorage["ID"] = "";
    localStorage["recordName"] = "";
    window.location.href = "../index.html";
}

/* Loads the cloud kit. */
window.addEventListener('cloudkitloaded', function() {
    CloudKit.configure({
        containers: [{
            containerIdentifier: 'iCloud.com.GoeAdventure.Goe',
            apiTokenAuth: {
                apiToken: '1934b95597d2ddbac825cbd5b72958c26b68d430ce014a44001abe23e32429d8',
                persist: true
            },
            environment: 'development'
        }]
    });

    function GoeViewModel() {
        var self = this;
        var container = CloudKit.getDefaultContainer();
        var publicDB = container.publicCloudDatabase;

        self.gotoAuthenticatedState = function(userInfo) {
            console.log("USER IS AUTHENTICATED");
            container
                .whenUserSignsOut()
                .then(self.gotoUnauthenticatedState);
        };

        self.gotoUnauthenticatedState = function(error) {
            console.log("USER CAN SUCK MY DICK");
            container
                .whenUserSignsIn()
                .then(self.gotoAuthenticatedState)
                .catch(self.gotoUnauthenticatedState);
        };

        container.setUpAuth().then(function(userInfo) {
            if(userInfo) {
                self.gotoAuthenticatedState(userInfo);
            } else {
                self.gotoUnauthenticatedState();
            }
        })
    }

    ko.applyBindings(new GoeViewModel());
});