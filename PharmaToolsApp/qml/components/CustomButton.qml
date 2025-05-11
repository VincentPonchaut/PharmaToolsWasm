import QtQuick
import QtQuick.Controls

Button {
    id: _theButton

    horizontalPadding: 20
    verticalPadding: 8

    scale: {
        if (!_theButton.enabled) {
            return 1
        }
        else if (_theButton.pressed) {
            return 0.95
        }
        else if (_theButton.hovered) {
            return 1.05
        }
        else {
            return 1
        }
    }

    property color color: colors.accent
    property alias textColor: _theButton.palette.buttonText
    
    // font.family: monoFont.name
//    font.family: headerFont.name
    font.pointSize: 16
    font.weight: _theButton.enabled && hovered ? Font.Bold
                                               : Font.DemiBold

    opacity: _theButton.enabled ? 1 : 0.5
    
    palette.buttonText: "white"
    background: Rectangle {
        id: _theBackground
        color: _theButton.enabled ? _theButton.color
                                  : "gray"
        radius: width
    }
}
