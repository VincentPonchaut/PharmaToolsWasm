import QtQuick
import Qt5Compat.GraphicalEffects

Item {

    // from the Image
    property alias source: _image.source
    property alias fillMode: _image.fillMode
    property alias sourceSize: _image.sourceSize

    // from the ColorOverlay
    property alias color: _colorOverlay.color

    // Mimic Image behavior
    implicitWidth: _image.implicitWidth
    implicitHeight: _image.implicitHeight

    Image {
        id: _image
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(width,height) // for sharp svg
        visible: false
        cache: false
    }

    ColorOverlay {
        id: _colorOverlay
        anchors.fill: _image
        source: _image
        color: "white"
    }
}
