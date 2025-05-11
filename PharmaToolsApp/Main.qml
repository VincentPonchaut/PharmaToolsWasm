import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1920
    height: 1200
    title: qsTr("Pharmatools")

    Loader {
        // source: "qml/main.qml"
        source: "qml/mainLogin.qml"
        anchors.fill: parent
    }
}
