var userAuthenticated = false;

/************** CLOUDKIT ITEMS **************/
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

        self.gotoAuthenticatedState = function(userInfo) {
            document.getElementById("fb-button").style.display = "block";
            container
                .whenUserSignsOut()
                .then(self.gotoUnauthenticatedState);
        };

        self.gotoUnauthenticatedState = function(error) {
            userAuthenticated = false;
            clearLocalStorage();
            document.getElementById("fb-button").style.display = "none";
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
/************** CLOUDKIT ITEMS END **************/

/************** FACEBOOK ITEMS **************/

// Load the SDK asynchronously
(function(d, s, id) {
    var js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return;
    js = d.createElement(s); js.id = id;
    js.src = "//connect.facebook.net/en_US/sdk.js";
    fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

window.fbAsyncInit = function() {
    FB.init({
        appId      : '1549697168604262',
        cookie     : true,  // enable cookies to allow the server to access
                            // the session
        xfbml      : true,  // parse social plugins on this page
        version    : 'v2.5' // use graph api version 2.5
    });

    FB.getLoginStatus(function(response) {
        handleFacebookLoginResponse(response);
    });
};

/* Once the user logins in, this method is called first to handle the initial response. */
function checkLoginState() {
    FB.getLoginStatus(function(response) {
        handleFacebookLoginResponse(response);
    });
}

/* Checks the response to ensure that the user is connected, then calls on retrieveFacebookUserID. */
function handleFacebookLoginResponse(response) {
    if (response.status === 'connected') {
        console.log(response);
        retrieveFacebookUserID();
    } else {
        userAuthenticated = false;
        clearLocalStorage()
    }
}

/*  Retrieves the facebook user from cloudkit. */
function retrieveFacebookUserID() {
    var params = {"fields": "id, name, first_name, last_name, picture.type(large), email"};
    FB.api('/me', check, params);
}

/************** FACEBOOK ITEMS END**************/

var publicDB;

/* Given the user's Facebook ID, attempts to retrieve the user from the public database. */
function check(response) {
    publicDB = CloudKit.getDefaultContainer().publicCloudDatabase;
    document.getElementById("Note").textContent = "Loading...";
    var userQuery = { recordType: "User",
        filterBy: [{
            fieldName: "Facebook_ID",
            comparator:'EQUALS',
            fieldValue: {value: response.id}
        }]
    };
    return publicDB.performQuery(userQuery).then(function(user) {
        if (user._results.length != 0) {
            localStorage["Username"] = user._results[0].fields.Name.value;
            localStorage["Facebook_ID"] = user._results[0].fields.Facebook_ID.value;
            localStorage["ID"] = user._results[0].fields.ID.value;
            localStorage["recordName"] = user._results[0].recordName;
            userAuthenticated = true;
            login()
        } else {
            createUserAccount(response)
        }
    })
}

/* Given the user's Facebook details, will create the user a Goe account. */
function createUserAccount(facebookResponse) {
    hashCode = function(s){
        return s.split("").reduce(function(a,b){a=((a<<5)-a)+b.charCodeAt(0);return a&a},0);
    };
    var newUser = { recordType: "User",
        fields: {
            Details: {value: ["Welcome to Goe! Adjust me with the edit button in the upper right corner."]},
            Email: {value: facebookResponse.email},
            Name: {value: facebookResponse.first_name+"."+facebookResponse.last_name},
            Facebook_ID: {value: facebookResponse.id},
            Goe_Rating: {value: 0},
            Password: {value: "NA"},
            Status: {value: 0},
            ID: {value: hashCode(facebookResponse.first_name+"."+facebookResponse.last_name+"."+facebookResponse.id).toString()}
        }
    };
    publicDB.saveRecord(newUser).then(function(response) {
        //handle errors
        var userReference = response._results[0].recordName;
        var userID = response._results[0].fields.ID.value;
        var userName = response._results[0].fields.Name.value;
        createUserProfile({userID: userID, userReference: userReference, userName: userName});
    })
}

/* Given the user's CKReference value, creates and saves the user a profile. */
function createUserProfile(user) {
    var newUserProfile = { recordType: "Profile",
        fields: {
            User_ID: {value: user.userID},
            User_Name: {value: user.userName},
            User: {value: {
                recordName: user.userReference,
                action: "DELETE_SELF"
            }}
        }
    };
    publicDB.saveRecord(newUserProfile).then(function(response) {
        //handle errors
        login()
    })
}

/* Provided the other items are all randy dandy, will log the user into the app. */
function login() {
    if ((userAuthenticated) && (localStorage["recordName"] != "")) {
        window.location.href = "LoggedIn/index.html";
    } else {
        document.getElementById("Note").textContent = "There's an error...";
    }
}

/* Goes through and clears out all the sensitive variables stored in local storage. */
function clearLocalStorage() {
    localStorage["Facebook_ID"] = "";
    localStorage["ID"] = "";
    localStorage["recordName"] = "";
}

function handleFileSelect(event) {
    var assetFile = event.target.files[0];
    var test = { recordType: "User",
        fields: {
            Picture: {value: assetFile}
        }};
    publicDB.saveRecord(test).then(function(response) {
        //handle errors
    })
}