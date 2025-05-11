import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

Pane {

    // --------------------------------------------------------------
    // Data
    // --------------------------------------------------------------

    // --------------------------------------------------------------
    // Logic
    // --------------------------------------------------------------

    // --------------------------------------------------------------
    // View
    // --------------------------------------------------------------
    padding: 20
    background: Rectangle {
        color: "white"
        radius: 20
        border.width: 2
        border.color: colors.accent
    }

    Page {
        anchors.fill: parent
        padding: 40
        
        header: Page {
            bottomPadding: 40
            
            header: Pane {
                bottomPadding: 20
                
                Button {
                    text: "Entrées/Sorties/Réceptions"
                    
                    flat: true
                    icon.source: "../icons/ico_inout.svg"
                    icon.width: 40
                    icon.height: 40
                    
                    font.family: headerFont.name
                    font.pointSize: 40
                    font.weight: Font.DemiBold
                    
                    MouseArea {
                        anchors.fill: parent
                    }
                }
            }
            
            Rectangle {
                anchors.fill: parent
                color: "red"
            }
            
            Row {
                x: 40
                spacing: 13

                Label {
                    text: "Intitulé de la Cueillette:"

                    font.family: headerFont.name
                    font.pointSize: 18
                    font.weight: Font.DemiBold

                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    text: "Cueillette du jour"
                    // placeholderText: "JJ/MM/AAAA"
                }
                
                Label {
                    text: "Initiales:"
                    
                    font.family: headerFont.name
                    font.pointSize: 22
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                TextField {
                    id: _ioInitialsTextField
                    placeholderText: "Saisir vos initiales..."
                }
                
                Item {
                    width: 20
                    height: 1
                }
                
                Label {
                    text: "Date:"
                    
                    font.family: headerFont.name
                    font.pointSize: 18
                    font.weight: Font.DemiBold
                    
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                TextField {
                    id: _ioDateTextField
                    placeholderText: "JJ/MM/AAAA"
                }

                Label {
                    text: "Code service:"

                    font.family: headerFont.name
                    font.pointSize: 18
                    font.weight: Font.DemiBold

                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    placeholderText: "Code service..."
                }

                Button {
                    text: "Créer"
                }
            }
        }

        Column {
            anchors.fill: parent
            spacing: 30

            IOGroupBox {
                id: _entreesGroupBox
                title: "Entrées"

                anchors.left: parent.left
                anchors.right: parent.right

                IOTableView {
                    anchors.fill: parent
                    rows: enCours.entrees
                }
            }

            IOGroupBox {
                id: _sortiesGroupBox
                title: "Sorties"

                anchors.left: parent.left
                anchors.right: parent.right

                IOTableView {
                    anchors.fill: parent
                    rows: enCours.sorties
                }
            }
        }

        footer: Pane {
            width: parent.width
            height: 200
            // palette.window: colors.contentLightBackground

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                BigButton {
                    id: _ioValidateButton
                    text: "Valider la cueillette"
                    icon: _ioValidateButton.validated ? "../icons/ico_check.svg" : ""
                    palette.button: currentlyValidating ? "darkgray" : "green"
                    palette.buttonText: "white"

                    property bool currentlyValidating: false
                    property bool validated: false
                    Timer {
                        id: fakeHEHEHEHE
                        interval: 3000
                        onTriggered: {
                            _ioValidateButton.currentlyValidating = false
                            _ioValidateButton.validated = true
                        }
                    }

                    function validate() {
                        _ioValidateButton.currentlyValidating = true
                        fakeHEHEHEHE.start()
                    }
                    onClicked: validate()

                    Binding on text {
                        when: _ioValidateButton.currentlyValidating
                        value: "Patientez..."
                    }
                    Binding on text {
                        when: _ioValidateButton.validated
                        value: "Cueillette validée"
                    }
                }

                BigButton {
                    enabled: _ioValidateButton.validated
                    text: "Commencer la Cueillette"
                    icon: "../icons/ico_cueillette.svg"
                    palette.button: colors.accent
                }
            }
        }
    }

    // --------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------

    component IOGroupBox: GroupBox {
        id: _ioGroupBoxInline
        title: "Entrées"

        anchors.left: parent.left
        anchors.right: parent.right
        height: 500
        padding: 40

        background: Rectangle {
            y: _ioGroupBoxInline.topPadding - _ioGroupBoxInline.bottomPadding
            width: parent.width
            height: parent.height - _ioGroupBoxInline.topPadding + _ioGroupBoxInline.bottomPadding
            color: colors.contentLightBackground
            border.color: colors.accent
            border.width: 2
            radius: 8
        }

        label: Label {
            width: _ioGroupBoxInline.availableWidth

            text: _ioGroupBoxInline.title
            color: colors.accent
            elide: Text.ElideRight

            font.family: headerFont.name
            font.pointSize: 24
            font.weight: Font.DemiBold
        }
    }

    component IOTableView: Item {
        anchors.fill: parent
        property alias rows: _ioTableModelInline.rows

        HorizontalHeaderView {
            id: _ioTableViewHeaderViewInline
            syncView: _ioTableViewInline
            anchors.left: _ioTableViewInline.left
            anchors.right: _ioTableViewInline.right

            delegate: Label {
                text: "" + ["type", "guid", "desc", "quantite", "location", "quantite_actuelle", "quantite_max", "UF", "initiales", "date"][parseInt(display)-1]

                leftPadding: 18
                bottomPadding: 18

                font.family: headerFont.name
                font.pointSize: 20
                font.weight: Font.DemiBold
            }
        }
        TableView {
            id: _ioTableViewInline
            // anchors.left: parent.left
            // anchors.right: parent.right
            width: childrenRect.width
            anchors.top: _ioTableViewHeaderViewInline.bottom
            anchors.bottom: parent.bottom

            model: TableModel {
                id: _ioTableModelInline
                TableModelColumn { display: "type" }
                TableModelColumn { display: "guid" }
                TableModelColumn { display: "desc" }
                TableModelColumn { display: "quantite" }
                TableModelColumn { display: "location" }
                TableModelColumn { display: "quantite_actuelle" }
                TableModelColumn { display: "quantite_max" }
                TableModelColumn { display: "UF" }
                TableModelColumn { display: "initiales" }
                TableModelColumn { display: "date" }
            }

            delegate: DelegateChooser {

                DelegateChoice {
                    // roleValue: "location"
                    column: 4

                    Pane {
                        id: _entreesLocDelegateInline
                        required property int row
                        required property int column
                        property var rowData: enCours.entrees[row]

                        implicitWidth: 300
                        height: 50
                        padding: 0

                        ComboBox {
                            enabled: _entreesLocDelegateInline.rowData.locations.length > 1

                            model: _entreesLocDelegateInline.rowData.locations.map(loc => loc.location)
                            currentIndex: 0

                            // editable: true
                            anchors.fill: parent
                            anchors.leftMargin: -1
                            anchors.topMargin: -1
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: -1
                            anchors.topMargin: -1

                            color: "transparent"
                            border.width: 1
                            border.color: "gray"
                        }
                    }
                } // DelegateChoice

                DelegateChoice {
                    column: 5 // quantite_actuelle

                    Pane {
                        required property int row
                        required property int column
                        property var rowData: enCours.entrees[row]

                        implicitWidth: 200
                        height: 50
                        padding: 0

                        TextField {
                            text: "" + rowData.locations[0].initial_amount
                            readOnly: true

                            anchors.fill: parent
                            anchors.leftMargin: -1
                            anchors.topMargin: -1
                        }
                    }
                } // DelegateChoice

                DelegateChoice {
                    column: 6 // quantite_max

                    Pane {
                        required property int row
                        required property int column
                        property var rowData: enCours.entrees[row]

                        implicitWidth: 300
                        height: 50
                        padding: 0

                        TextField {
                            text: {
                                let guid = rowData.guid
                                return database.inventory.filter(item => item.guid === guid)[0]["max_count"]
                            }

                            anchors.fill: parent
                            anchors.leftMargin: -1
                            anchors.topMargin: -1
                        }
                    }
                } // DelegateChoice

                DelegateChoice {
                    Pane {
                        implicitWidth: column === 2 ? 450 : 100
                        height: 50
                        padding: 0

                        TextField {
                            text: column === 8 ? _ioInitialsTextField.text :  display
                            anchors.fill: parent
                            anchors.leftMargin: -1
                            anchors.topMargin: -1

                            onTextChanged: {
                                display = text
                            }

                            palette.mid: String(display).length > 0 ? "gray":"red"
                        }
                    }
                } // DelegateChoice
            }
        }
    } // IOTableView

    component BigButton: Pane {
        id: _ioValidateButtonInline
        implicitWidth: _ioValidateLabelInline.implicitWidth + leftPadding + rightPadding + _ioValidateCheckImageInline.implicitWidth + 8
        implicitHeight: _ioValidateLabelInline.implicitHeight + topPadding + bottomPadding
        scale: enabled && _ioValidateButtonInlineMouseArea.containsMouse ? 1.1
                                                                         : 1

        property alias text: _ioValidateLabelInline.text
        property alias icon: _ioValidateCheckImageInline.source
        signal clicked()

        padding: 20
        palette.buttonText: "white"

        background: Rectangle {
            color: _ioValidateButtonInline.enabled ? parent.palette.button:
                                                     "lightgray"
            radius: 10
        }

        Image {
            id: _ioValidateCheckImageInline
            sourceSize: Qt.size(36,36)

            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            id: _ioValidateLabelInline

            anchors.left: _ioValidateCheckImageInline.right
            anchors.leftMargin: 8

            font.family: headerFont.name
            font.pointSize: 20
            font.weight: Font.DemiBold
            color: parent.palette.buttonText
        }

        MouseArea {
            id: _ioValidateButtonInlineMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onClicked: _ioValidateButtonInline.clicked()
        }
    } // Pane
}
