import QtQuick
import QtQuick.Controls

Page {

    property string username: ""
    property string password: ""
    property bool loggedIn: false
    property bool invalidCredentials: false

    function attemptLogin() {
        if (username === "admin" || username === "pharmacien") {
            loggedIn = (username === password)
        }
        invalidCredentials = !loggedIn
    }

    header: Label {
        text: "PharmaTools"
        visible: !loggedIn

        padding: 40
        font.pointSize: 40
        horizontalAlignment: Text.AlignHCenter
    }

    Page {
        width: 400
        height: 300
        anchors.centerIn: parent

        header: Label {
            text: "Connexion"

            padding: 30
            font.pointSize: 22
            horizontalAlignment: Text.AlignHCenter
        }

        background: Rectangle {
            color: "#F0F0F0"
            radius: 10
            border.color: "black"
            border.width: 2
        }

        Column {
            anchors.centerIn: parent
            // flow: Grid.TopToBottom
            // columns: 1
            spacing: 20
            scale: 1.2

            TextField {
                id: usernameField
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                placeholderText: "Identifiant"
                text: username
                onTextChanged: username = text

                onAccepted: passwordField.forceActiveFocus()
            }
            TextField {
                id: passwordField
                width: parent.width
                placeholderText: "Mot de passe"
                text: password
                echoMode: TextInput.Password
                onTextChanged: password = text

                onAccepted: attemptLogin()
            }
            Button {
                text: "Login"
                enabled: username.length > 0 && password.length > 0
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: attemptLogin()
            }
            Label {
                text: "Les identifiants sont incorrects"
                // visible: invalidCredentials
                opacity: invalidCredentials ? 1 : 0
                color: "red"
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Actual Content to be loaded when logging is done
    Loader {
        id: _mainLoader
        source: "main.qml"
        active: loggedIn
        anchors.fill: parent

        onLoaded: {
            _mainLoader.item.onLoggedIn(username)
            _mainLoader.item.logOutRequested.connect(function() {
                // Reset the login page
                username = ""
                password = ""

                loggedIn = false
                // _mainLoader.source = ""
            })
        }
    }
}
