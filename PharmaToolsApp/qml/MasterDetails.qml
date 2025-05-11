import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"

SplitView {
    id: _masterDetails

    // ---------------------------------------------------------------
    // Data
    // ---------------------------------------------------------------

    // Selection
    property var selectedItem

    // UI config
    property int masterPaneWidth: _masterDetails.width * 0.25
    property int masterPaneMinimumWidth: 300
    property alias masterPaneModel: _masterPaneListView.model
    property alias masterPaneDelegate: _masterPaneListView.delegate
    property string masterPaneDisplayRole: "intitule"
    property alias masterPaneTitle: _masterPane.title
    property var masterPaneDelegateFormatter: (qmlItem, modelData) => {}

    property alias detailsPaneTitle: _detailsPane.title
    property alias detailsPaneDelegate: _detailsPaneRepeater.delegate

    property bool canCreate: false
    property var createCallback: () => { print("Create callback not set") }

    // ---------------------------------------------------------------
    // Logic
    // ---------------------------------------------------------------

    // ---------------------------------------------------------------
    // View
    // ---------------------------------------------------------------

    handle: Item{}

    Panel {
        id: _masterPane
        title: "Master"
        objectName: "masterPane"

        SplitView.preferredWidth: masterPaneWidth
        SplitView.minimumWidth: masterPaneMinimumWidth
        SplitView.fillHeight: true

        ListView {
            id: _masterPaneListView
            anchors.fill: parent

            delegate: ItemDelegate {
                width: _masterPaneListView.width
                height: 50

                required property var modelData
                onModelDataChanged: {
                    masterPaneDelegateFormatter(this, modelData)
                }

                text: modelData[masterPaneDisplayRole]
                highlighted: selectedItem ? selectedItem["id"] === modelData["id"]
                                          : false

                font.family: headerFont.name
                font.weight: highlighted ? Font.Bold
                                         : Font.Medium
                font.pointSize: 16

                onClicked: {
                    selectedItem = modelData
                }
            }
        }
    }

    Panel {
        id: _detailsPane
        title: "Details"

        SplitView.fillWidth: true
        SplitView.fillHeight: true

        Repeater {
            id: _detailsPaneRepeater
            model: selectedItem ? [selectedItem] : 0

            delegate: ScrollView {
                anchors.fill: parent

                TextArea {
                    readOnly: true
                    text: JSON.stringify(modelData,null,2)
                    font.family: monoFont.name
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------

    component Panel: Page {
        id: _panel
        background: null
        padding: 10

        // property alias title: _panelHeader.text
        default property alias _data: _innerContent.data

        Page {
            id: _innerPage
            anchors.fill: parent

            background: Rectangle {
                color: "white"
                border.color: colors.accent
                border.width: 2
                radius: 16
            }

            header: Header {
                id: _panelHeader
                text: _panel.title
                // font.pointSize: 20
                leftPadding: _panelHeader.compactMode ? 18 : 30
                rightPadding: _panelHeader.leftPadding
                topPadding: 20
                bottomPadding: 20

                property int compactBreakpoint: 360
                property bool compactMode: _panelHeader.width <= compactBreakpoint

                CustomButton {
                    visible: canCreate && _panel.objectName === "masterPane"

                    text: _panelHeader.compactMode ? ""
                                                   : "Créer"
                    icon.source: images.plus
                    height: 36

                    Binding on leftPadding{ value: 6; when: _panelHeader.compactMode }
                    Binding on rightPadding{ value: 6; when: _panelHeader.compactMode }

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: _panelHeader.rightPadding

                    onClicked: {
                        createCallback()
                    }
                }
            }

            Item {
                id: _innerContent
                anchors.fill: parent
                anchors.leftMargin: _panelHeader.leftPadding
                anchors.rightMargin: _panelHeader.rightPadding
                anchors.topMargin: 2
                anchors.bottomMargin: _panelHeader.bottomPadding
            }
        }
    }
}
