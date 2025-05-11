import QtQuick
import QtQuick.Controls

TextField {
    id: _searchTextFieldControl
    implicitHeight: 50
    placeholderText: "Rechercher..."
    
    leftPadding: 50
    font.family: headerFont.name
    font.pointSize: 16
    font.weight: Font.DemiBold
    
    background: Rectangle {
        radius: width
        color: _searchTextFieldControl.enabled ? "white" : "#353637"
        border.color: _searchTextFieldControl.activeFocus ? colors.accent
                                                          : "#33000000"
        border.width: _searchTextFieldControl.activeFocus ? 2 : 1
        
        Image {
            source: "../../icons/ico_search.svg"
            
            anchors.verticalCenter: parent.verticalCenter
            x: 15 // oui, plus de hardcode, PLUS !
        }
    }
}
