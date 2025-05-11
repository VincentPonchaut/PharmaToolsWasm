import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.VectorImage

import Qt.labs.qmlmodels

import "./components"

Page {
    palette.window: "transparent"
    padding: 0

    ItemTable {
        id: _productPageTable
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.44
        rightPadding: 40
        
        enableFilteringOnProviders: false
        enablePreconisationsFilter: false
        
        columns: [
            TableModelColumn { display: "desc" },
            TableModelColumn { display: "ref" }
        ]

        background: Rectangle {
            color: "white"
            radius: 20
            border.width: 2
            border.color: colors.accent
        }
    }
    
    Page {
        id: _productPageDetailsPane
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: _productPageTable.right
        
        // padding: 40
        // topPadding: 100
        horizontalPadding: 40

        palette.window: colors.lightBackground

        header: Pane {
            horizontalPadding: 40

            Row {
                visible: _productPageTable.currentRow >= 0
                spacing: 12

                Rectangle {
                    width: 50
                    height: 50
                    radius: width
                    anchors.verticalCenter: parent.verticalCenter

                    color: colors.accent

                    RecoloredImage {
                        id: sourceIcon
                        anchors.fill: parent
                        anchors.margins: 10
                        source: images.item
                        color: "white"
                    }
                }

                Label {
                    text: {
                        if (!_productPageTable.currentItem) {
                            return ""
                        }
                        return _productPageTable.currentItem.desc
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    font.pointSize: 26
                    font.family: headerFont.name
                    font.weight: Font.DemiBold
                }
            }
        }

        Page {
            anchors.fill: parent
            horizontalPadding: 40
            topPadding: 20
            bottomPadding: 0

            background: Rectangle {
                border.color: colors.accent
                border.width: 2
                color: "white"
                radius: 12
            }

            header: TabBar {
                id: _productPageDetailsPaneTabBar
                height: 60
                spacing: -16
                // clip: true

                CustomTabButton {
                    text: "Info"
                }
                CustomTabButton {
                    text: "Historique"
                }
                CustomTabButton {
                    text: "Dotation"
                }
            }

            Page {
                visible: _productPageTable.currentRow >= 0
                anchors.fill: parent
                padding: 0
                background: null

                StackLayout {
                    id: _productPageDetailsStack
                    anchors.fill: parent
                    currentIndex: _productPageDetailsPaneTabBar.currentIndex

                    Grid {
                        width: _productPageDetailsStack.width
                        height: _productPageDetailsStack.height
                        anchors.margins: 50
                        flow: Grid.TopToBottom
                        rows: _fieldRepeater.count + 1
                        spacing: 20

                        Repeater {
                            id: _fieldRepeater
                            model: [
                                { name: "GEF", key: "guid" },
                                { name: "Description", key: "desc" },
                                { name: "Fournisseur", key: "provider" },
                                { name: "Référence", key: "ref" },
                                { name: "Min count", key: "min_count" },
                                { name: "Max count", key: "max_count" },
                                { name: "QML", key: "qml" },
                                { name: "Stock Total", key: "total_count" },
                                // { name: "Stock Disponible", key: "available_stock" },
                                // { name: "Stock Réservé", key: "reserved_stock" },
                                // { name: "Stock Commandé", key: "ordered_stock" },
                                // { name: "Stock En attente", key: "waiting_stock" },
                                // { name: "Stock En transit", key: "transit_stock" },
                                { name: "Emplacements", key: "locations" }
                            ]

                            Label {
                                text: modelData.name
                                height: 40
                                verticalAlignment: Text.AlignVCenter

                                font.pointSize: 18
                                font.family: headerFont.name
                                font.weight: Font.DemiBold
                            }
                        }
                        Button {
                            text: "Modifier"
                        }

                        Repeater {
                            model: _fieldRepeater.model

                            DelegateChooser {
                                role: "key"

                                DelegateChoice {
                                    roleValue: "locations"

                                    Label {
                                        text: {
                                            const locs = _productPageTable.currentItem?.locations || []
                                            if (locs.length === 0) {
                                                return "Aucun emplacement"
                                            }
                                            else {
                                                // return locs.map(loc => `${loc.location} : ${loc.amount}`).join("\n")

                                                // Same as markdown table
                                                let result = ""
                                                result += "| Emplacement | Quantité |\n"
                                                result += "|-------------|----------|\n"
                                                locs.forEach(loc => {
                                                                 result += `| ${loc.location} | ${loc.amount} |\n`
                                                             })

                                                return result
                                            }
                                        }
                                        textFormat: Text.MarkdownText
                                        font.pointSize: 20
                                    }
                                }

                                DelegateChoice {
                                    TextField {
                                        id: _fieldTextField
                                        width: parent.width * 0.5
                                        height: 40

                                        text: _productPageTable.currentItem ? _productPageTable.currentItem[modelData.key]
                                                                            : ""
                                        readOnly: modelData.key === "guid" ||
                                                  modelData.key === "total_count"

                                        font.pointSize: 18
                                        font.family: headerFont.name
                                        font.weight: Font.DemiBold

                                        background: Rectangle {
                                            color: colors.lightBackground
                                            border.color: colors.accent
                                            border.width: 1
                                        }

                                        Rectangle {
                                            visible: _fieldTextField.readOnly
                                            anchors.fill: parent
                                            color: "black"
                                            opacity: 0.2
                                        }

                                        onTextChanged: {
                                            if (!_productPageTable.currentItem)
                                                return

                                            _productPageTable.currentItem[modelData.key] = text
                                        }
                                    }
                                }
                            }
                        }

                        Item {}
                    }

                    Label {
                        text: "Onglet en construction ..."
                        font.pointSize: 20
                        font.family: headerFont.name
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "Onglet en construction ..."
                        font.pointSize: 20
                        font.family: headerFont.name
                        font.weight: Font.DemiBold
                    }
                }

                footer: Pane {
                    id: _productPageDetailsPaneFooter
                    height: 80
                    padding: 0

                    background: Item {
                        Rectangle {
                            height: 2
                            width: parent.width + 80
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: colors.accent
                        }
                    }

                    Row {
                        id: _productPageDetailsPaneFooterRow
                        anchors.fill: parent
                        spacing: 12

                        Button {
                            text: "Désactiver ce produit"

                            palette.button: "red"
                            palette.buttonText: "white"
                            font.family: headerFont.name
                            font.bold: true

                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Button {
                        //     text: "Annuler"
                        //     onClicked: _productPageTable.currentRow = -1
                        //     width: 200
                        //     height: 50
                        // }

                        // Button {
                        //     text: "Enregistrer"
                        //     width: 200
                        //     height: 50
                        //     onClicked: console.log("Enregistrer")
                        // }
                    }
                }
            }

            Label {
                text: "Sélectionnez un produit pour afficher ses informations"
                visible: _productPageTable.currentRow < 0
                anchors.centerIn: parent

                font.family: headerFont.name
                font.pointSize: 24
                font.weight: Font.DemiBold
                color: "#3d3d3d"
            }
        }
    }

    // ------------------------------------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------------------------------------

    component CustomTabButton: TabButton {
        id: _tabButton
        height: checked ? 60 : 55
        //        height: checked ? 60 : (60 - 5*TabBar.index)
        font.pointSize: 18
        font.family: headerFont.name
        font.weight: checked ? Font.Bold :
                               Font.Medium
        anchors.bottom: parent.bottom
        z: _tabButton.checked ? 999 : -TabBar.index

        contentItem: Text {
            text: _tabButton.text
            font: _tabButton.font
            opacity: enabled ? 1.0 : 0.3
            color: _tabButton.checked ? "white" : "black"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            // width: parent.width * 1.002
            color: _tabButton.checked ? colors.accent : "lightgray"
            opacity: enabled ? 1 : 0.3
            border.color: colors.accent
            border.width: 2
            radius: 16
            clip: true

            Rectangle {
                height: 30
                color: parent.color
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.bottom
                anchors.leftMargin: 2
                anchors.rightMargin: 2

                // Tu iras en enfer pour ça
                Rectangle {
                    width: 2
                    color: _tabButton.background.border.color
                    anchors.left: parent.left
                    anchors.leftMargin: -2
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
                Rectangle {
                    width: 2
                    color: _tabButton.background.border.color
                    anchors.right: parent.right
                    anchors.rightMargin: -2
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
            Rectangle {
                color: _tabButton.background.border.color
                height: 2
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

}





