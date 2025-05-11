import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"

Page {
    id: _pageEntrees

    // ------------------------------------------------------
    // Data
    // ------------------------------------------------------

    property var currentEntree: ({})

    // ------------------------------------------------------
    // Logic
    // ------------------------------------------------------

    function prepareEntree() {
        currentEntree["initials"] = "CM" // TODO fetch from root login
        currentEntree["uf"] = "Cette bonne vieille UF"
        currentEntree["date"] = new Date().toLocaleDateString("fr-FR", {
                                                                  year: 'numeric',
                                                                  month: '2-digit',
                                                                  day: '2-digit'
                                                              })
        currentEntree["title"] = "Entrée du %1".arg(currentEntree["date"])
        currentEntree["items"] = [
                    {
                        "desc": "FLACON VERSABLE CHLORURE SODIUM 0.9% 1L (GR)",
                        "ref": "B220561",
                        "quantity": 999
                    },
                    {
                        "desc": "TAMPON HEMOSTATIQUE 4X2CM COALGAN-H (GR)",
                        "ref": "1020",
                        "quantity": 167
                    },
                    {
                        "desc": "SONDE RECTALE CH.28 (GR)",
                        "ref": "199 2801 1",
                        "quantity": 167
                    }
                ]

        _pageEntrees.currentEntreeChanged()
    }

    Component.onCompleted: {
        prepareEntree()
    }

    // ------------------------------------------------------
    // View
    // ------------------------------------------------------

    padding: 20
    background: Rectangle {
        color: colors.lightBackground
        radius: 20
        // border.width: 2
        // border.color: colors.accent
    }
    
    // Left Pane ---------------------------------------------
    Page {
        id: _pageEntreesLeftPane
        
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.4
        z: 9
        
        padding: 0
        // palette.window: colors.contentLightBackground
        
        background: Rectangle {
            color: colors.contentLightBackground
            radius: 20
            border.width: 2
            border.color: colors.accent
        }
        
        header: Pane {
            background: null
            padding: 30

            Header {
                text: "Créer une Entrée"
            }
        }

        Pane {
            anchors.fill: parent
            background: null
            padding: 0

            Grid {
                id: _pageEntreesLeftPaneGrid
                anchors.horizontalCenter: parent.horizontalCenter
                flow: Grid.TopToBottom
                spacing: 10
                rows: _pageEntreesLeftPaneRepeater.count

                Repeater {
                    id: _pageEntreesLeftPaneRepeater
                    model: [
                        {
                            "name": "Date",
                            "key": "date",
                        },
                        {
                            "name": "Intitulé",
                            "key": "title",
                        },
                        {
                            "name": "Inititiales",
                            "key": "initials",
                        },
                        {
                            "name": "Code service",
                            "key": "uf",
                        },
                    ]

                    Label {
                        text: modelData.name
                        height: 40
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Repeater {
                    id: _pageEntreesLeftPaneRepeater2
                    model: _pageEntreesLeftPaneRepeater.model

                    TextField {
                        text: currentEntree[modelData.key]
                        placeholderText: "Saisir " + modelData.name
                        height: 40
                    }
                }
            }
        } // Pane

        footer: Pane {
            background: null
            height: parent.height - _pageEntreesLeftPaneGrid.childrenRect.height - 100
            // palette.window: "red"
            padding: 0

            ItemTable {
                id: _itemTableEntree
                anchors.fill: parent
                background: null

                enableFilteringOnProviders: false
                enablePreconisationsFilter: false
                centerTableView: true

                columns: [
                    TableModelColumn { display: "desc" },
                    TableModelColumn { display: "ref" }
                ]
                actions: [
                    Action {
                        text: "Ajouter"
                        icon.source: "../icons/add.svg"
                        onTriggered: (source) => {
                                         console.log("Add action triggered", JSON.stringify(_itemTableEntree.currentItem))
                                         _dialog.item = _itemTableEntree.currentItem
                                         _dialog.open()
                                         // TODO implement add action
                                     }
                    }
                ]
            }
        }
    }

    // Right Pane---------------------------------------------
    Page {
        id: _pageEntreesRightPane

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: _pageEntreesLeftPane.right
        anchors.leftMargin: 30
        anchors.bottom: parent.bottom

        padding: 0

        header: Pane {
            background: null
            padding: 30
            Header {
                text: "Produits a ranger"
            }
        }

        background: Rectangle {
            color: "white"
            radius: 20
            border.width: 2
            border.color: colors.accent
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "black"
            opacity: 0.3
        }

        Pane {
            anchors.fill: parent
            background: null
            // palette.window: Qt.rgba(Math.random(), Math.random(), Math.random(), 0.5)
            horizontalPadding: 40
            verticalPadding: 20

            // Rectangle { anchors.fill: _listView; color: "purple" }

            ListView {
                id: _listView
                // anchors.top: parent.top
                // anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: 300
                width: 1000

                model: currentEntree["items"]
                spacing: 16

                delegate: Row {
                    id: _itemDelegate
                    height: 40
                    spacing: 20

                    required property var modelData

                    Header {
                        text: "%1".arg(modelData.desc)
                        width: 400
                        elide: Text.ElideRight

                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: 14
                        font.weight: Font.Medium
                    }

                    TextField {
                        id: _itemDelegateTextField
                        text: modelData.quantity
                        placeholderText: "Saisir quantité"
                        validator: IntValidator { bottom: 0 }

                        onTextChanged: {
                            modelData.quantity = parseInt(text)
                            console.log("Quantity changed to %1".arg(modelData.quantity))
                        }
                    }

                    ComboBox {
                        id: _itemDelegateEmplacementComboBox
                        enabled: _itemDelegateEmplacementComboBox.count > 1
                        width: 200

                        model: {
                            // Trouver tous les emplacements où le produit est présent
                            let result =  database.inventory
                            .filter((item) => {
                                        return item.ref === _itemDelegate.modelData.ref
                                    })
                            .map((item) => {
                                     return item.locations.map((location) => {
                                                                   return location.location
                                                               })
                                 })
                            .flat()
                            .filter((value, index, self) => {
                                        return self.indexOf(value) === index
                                    })

                            return result
                        }
                    }

                }
            }

        } // Pane

        footer: Pane {
            height: 110
            background: null
            padding: 30

            Rectangle {
                width: parent.width
                height: 1
                y: -31
                color: "black"
                opacity: 0.2
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                // leftPadding: 40

                CustomButton {
                    text: "Lancer la liste"
                    icon.source: images.check
                    color: "green"
                    height: 50
                    font.pointSize: 18

                    onClicked: {
                        let html = ""
                        // Generate a default HTML file
                        html += "<html>"
                        html += "<head>"
                        html += "<title>" + currentEntree["title"] + "</title>"
                        html += "<style>"
                        html += "body { font-family: Arial, sans-serif; }"
                        html += "h1 { color: #333; }"
                        html += "table { border-collapse: collapse; width: 100%; }"
                        html += "th, td { border: 1px solid #ddd; padding: 8px; }"
                        html += "th { background-color: #f2f2f2; }"
                        html += "</style>"
                        html += "</head>"
                        html += "<body>"
                        html += "<h1>" + currentEntree["title"] + "</h1>"
                        html += "<h2>Retour de [" + currentEntree["uf"] + "]</h2>"
                        html += "<table>"
                        html += "<tr>"
                        html += "<th>Produit</th>"
                        html += "<th>Référence</th>"
                        html += "<th>Quantité</th>"
                        html += "<th>Emplacement</th>"
                        html += "</tr>"
                        currentEntree["items"].forEach((item) => {
                            html += "<tr>"
                            html += "<td>" + item.desc + "</td>"
                            html += "<td>" + item.ref + "</td>"
                            html += "<td>" + item.quantity + "</td>"
                            html += "<td>" + item.desc + "</td>"
//                            html += "<td>" + _itemDelegateEmplacementComboBox.modelData + "</td>"
                            html += "</tr>"
                        })
                        html += "</table>"
                        html += "</body>"
                        html += "</html>"

                        PrintHelper.printHtml(html)
                    }
                }
            }
        }
    }

    /**
    TextArea {
        visible: true
        text: {
            let txt = "DEBUG\n"
            txt += JSON.stringify(currentEntree["items"], null, 2)
            return txt
        }
        anchors.right: parent.right
        height: 400
        z: 999

        background: Rectangle {
            color: "black"
        }
        color: "red"
        font.family: monoFont.name
    }
    /**/

    // ------------------------------------------------------
    // Dialogs & Popups
    // ------------------------------------------------------

    Dialog {
        id: _dialog
        modal: true
        // visible: true

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        padding: 30

        property var item: null
        property int quantity: 0

        function addToEntree() {
            if (!item || quantity === 0)
                return

            console.log("Adding %1 to entree with quantity %2".arg(item.desc).arg(quantity))
            currentEntree["items"].push({
                                            "desc": item.desc,
                                            "ref": item.ref,
                                            "quantity": quantity
                                        })
            _pageEntrees.currentEntreeChanged()
            _dialog.close()
            _itemTableEntree.focusSearchTextField()
        }

        onVisibleChanged: {
            if (visible) {
                _dialogTextField.forceActiveFocus()
                _dialogTextField.selectAll()
            }
        }

        header: Pane {
            background: null

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Header {
                    text: "Ajouter"; anchors.horizontalCenter: parent.horizontalCenter
                    //                text: "Ajouter %1".arg(_dialog.item.desc)
                }

                Header {
                    text: "%1".arg(_dialog.item?.desc || "")
                    font.pointSize: 16
                    font.weight: Font.Medium
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            Label {
                text: "Quantité:"
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id: _dialogTextField
                placeholderText: "Saisir quantité"
                validator: IntValidator { bottom: 0 }

                text: String(_dialog.quantity)
                onTextChanged: {
                    _dialog.quantity = parseInt(text)
                }
                onAccepted: {
                    _dialog.addToEntree()
                }
            }
        }
    }

    Dialog {
        id: _dialogListeLancee
        modal: true
        // visible: true

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        padding: 30

        height: _pageEntrees.height
        width: /* A4 ratio */ height * 0.707

        header: Column {
            padding: 40
            spacing: 10

            Header {
                text: currentEntree["title"] + " par " + currentEntree["initials"]
                font.underline: true
            }
            Header {
                text: "Retour de [" + currentEntree["uf"] + "]"
                font.pointSize: 18
                leftPadding: 8
            }
        }
    }
}

























