import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"

Pane {
    id: _pageInventory
    // -------------------------------------------------------------
    // Data
    // -------------------------------------------------------------

    // -------------------------------------------------------------
    // Logic
    // -------------------------------------------------------------

    function commander(itemData) {
        let qml = itemData.qml
        let stock = itemData.stock
        let mini = itemData.min_count

        // how many qml do I need to go over mini ?
        let qmlToOrder = Math.ceil((mini - stock) / qml)
        console.log("Commander %1 of %2 : stock goes from %3 to %4 and is thus above %5"
                    .arg(qmlToOrder)
                    .arg(qml)
                    .arg(stock)
                    .arg(stock + qmlToOrder * qml)
                    .arg(mini)
                    )

        let order = {
            "guid": itemData.guid,
            "desc": itemData.desc,
            "qml": qml,
            "quantite": qmlToOrder,
            "provider": itemData.provider,
            "ref": itemData.ref
        }
        enCours.commandes.push(order)
        enCours.commandesChanged()

        database.inventory.filter(itm => itm.guid === itemData.guid).forEach(itm => {
                                                                                 let newStock = itm.stock + qmlToOrder * qml
                                                                                 console.log("New stock for %1: %2".arg(itm.guid).arg(newStock))
                                                                                 itm.stock = newStock
                                                                             })
        database.inventoryChanged()

        _addedToOrderFeedback.animation.start()
    }

    function _makeEntry(itemData) {
        let entry = JSON.parse(JSON.stringify(itemData)) // copy
        entry["quantite"] = 0
        entry["location"] = itemData.locations[0]
        entry["UF"] = ""
        entry["initiales"] = ""
        entry["date"] = new Date().toLocaleDateString('fr-FR', {
                                                          year: 'numeric',
                                                          month: '2-digit',
                                                          day: '2-digit'
                                                      })

        return entry
    }

    function entree(itemData){
        print("Entrée for item: " + itemData.desc)

        let entry = _makeEntry(itemData)
        entry["type"] = "entree"

        enCours.entrees.push(entry)
        enCours.entreesChanged()

        gui.currentTabIndex = 1
    }
    function sortie(itemData){
        print("Sortie for item: " + itemData.desc)

        let entry = _makeEntry(itemData)
        entry["type"] = "sortie"

        enCours.sorties.push(entry)
        enCours.sortiesChanged()

        gui.currentTabIndex = 1
    }

    // -------------------------------------------------------------
    // View
    // -------------------------------------------------------------

    topPadding: 20
    horizontalPadding: 20
    bottomPadding: 2

    background: Rectangle {
        color: "white"
        radius: 20
        border.width: 2
        border.color: colors.accent
    }
    
    Page {
        anchors.fill: parent

        ItemTable {
            id: _itemTable
            anchors.fill: parent

            enablePreconisationsFilter: false
            enableFilteringOnProviders: false
            flattenLocations: true
            showTotalFooter: true

            columns: [
                TableModelColumn { display: "guid"; },
                TableModelColumn { display: "desc" },
                TableModelColumn { display: "ref" },
                TableModelColumn { display: "provider" },
                TableModelColumn { display: "locations" },
                TableModelColumn { display: "stock" },
                TableModelColumn { display: "ddi" }
            ]

            actions: [
                Action {
                    text: "Modifier"
                    icon.source: images.edit_stock
                    onTriggered: (source) => {
                                     _editStockDialog.item = _itemTable.currentItem
                                     _editStockDialog.open()
                                 }
                }
                // Action {
                //     text: "Commander"
                //     icon.source: "../icons/ico_inventory.svg"
                //     onTriggered: (source) => {
                //                      console.log("Test action triggered", source.parent.rowData.desc)
                //                      commander(source.parent.rowData)
                //                  }
                // },
                // Action {
                //     text: "Entrée"
                //     icon.source: "../icons/ico_inventory.svg"
                //     onTriggered: (source) => {
                //                      console.log("Test action triggered", source.parent.rowData.desc)
                //                      entree(source.parent.rowData)
                //                  }
                // },
                // Action {
                //     text: "Sortie"
                //     icon.source: "../icons/ico_inventory.svg"
                //     onTriggered: (source) => {
                //                      console.log("Test action triggered", source.parent.rowData.desc)
                //                      sortie(source.parent.rowData)
                //                  }
                // }
            ]
        }


        Rectangle {
            id: _addedToOrderFeedback
            opacity: 0

            width: childrenRect.width * 1.2
            height: 80
            radius: 10
            color: "green"

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 30

            Image {
                source: "../icons/ico_check.svg"
                sourceSize: Qt.size(36,36)

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 17
            }

            Text {
                text: "Ajouté a la commande"
                color: "white"

                leftPadding: 40
                anchors.centerIn: parent

                font.family: headerFont.name
                font.bold: true
                font.pointSize: 18
            }

            property Animation animation: SequentialAnimation {
                NumberAnimation {
                    targets: _addedToOrderFeedback
                    properties: "opacity"
                    duration: 100
                    from: 0
                    to: 1
                    easing.type: Easing.InQuad
                }

                PauseAnimation {
                    duration: 2000
                }


                NumberAnimation {
                    targets: _addedToOrderFeedback
                    properties: "opacity"
                    duration: 100
                    from: 1
                    to: 0
                    easing.type: Easing.OutQuad
                }
            }
        }
    } // Page

    // --------------------------------------------------------------
    // Popups
    // --------------------------------------------------------------

    Dialog {
        id: _editStockDialog
        title: "Modifier le stock"
        font.pointSize: 20
        // font.underline: true
        modal: true
        // visible: true

        x: _pageInventory.width / 2 - width / 2
        y: _pageInventory.height / 2 - height / 2
        topPadding: 20
        leftPadding: 40
        rightPadding: 40
        bottomPadding: 20

        property var item: null
        property var perimes: _editStockDialog.item?.perimes || [
                                  // {
                                  //     units: "10",
                                  //     peremptionDate: "01/01/2023",
                                  // },
                                  // {
                                  //     units: "22",
                                  //     peremptionDate: "02/03/2024",
                                  // }
                              ]

        onVisibleChanged: {
            _editStockDialog.focus = visible
            if (visible) {
                _stockTextField.clear()
                _stockTextField.forceActiveFocus()
            }
        }

        Column {
            anchors.fill: parent
            spacing: 16

            Label {
                text: "Modification du stock de\n<h4>%1</h4>".arg(_editStockDialog.item?.desc || "")
                textFormat: TextEdit.RichText
                horizontalAlignment: Text.AlignHCenter

                font.family: headerFont.name
                font.pointSize: 18
                font.weight: Font.Medium
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Label {
                    text: `${_editStockDialog.item?.stock || ""} \t→`
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: _stockTextField
                    width: 120

                    // text: _editStockDialog.item?.stock || ""
                    validator: IntValidator { bottom: -Number.MAX_VALUE }

                    font.pointSize: 18
                    font.family: headerFont.name
                    font.weight: Font.DemiBold

                    onTextChanged: {
                        if (!item || !item.stock)
                            return
                        item.stock = parseInt(text) // TODO
                    }
                    Keys.onReturnPressed: {
                        // TODO
                        _editStockDialog.close()
                    }
                }
            }

            Item { // Spacer
                width: 1
                height: 8
            }

            Label {
                text: "Périmés"
                visible: _editStockDialog.perimes.length > 0
                width: parent.width
                topPadding: 12

                font.bold: true
                font.underline: true

            }
            RoundButton {
                text: "Ajouter des Périmés"

                height: 32
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalPadding: 20
                verticalPadding: 0
                scale: pressed ? 0.95
                               : hovered ? 1.05 : 1

                font.family: monoFont.name
                font.pointSize: 16

                onClicked: {
                    console.log("Clicked on add perimes")
                    _editStockDialog.perimes.push({
                                                     units: "",
                                                     peremptionDate: "",
                                                 })
                    _editStockDialog.perimesChanged()

                    // Scroll to bottom
                    _editStockDialogPerimesListView.positionViewAtIndex(_editStockDialog.perimes.length - 1, ListView.Beginning)
                }
            }

            /**
            ScrollView {
                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.min(400,implicitHeight)

                Label {
                    width: parent.width
                    textFormat: Text.MarkdownText
                    font.family: monoFont.name
                    font.pointSize: 14

                    text: {
                        let result = ""
                        let source = (_editStockDialog.item?.perimes || [
                                          {
                                              name: "Un super produit",
                                              date: "01/01/2023",
                                          },
                                          {
                                              name: "Un produit tout nul",
                                              date: "02/03/2024",
                                          }
                                      ])

                        // Mardown table
                        result += "| Produit | Date de Péremption |\n"
                        result += "| --- | ---: |\n"
                        source.forEach(item => {
                            result += "| " + item.name + " | " + item.date + " |\n"
                        })

                        return result
                    }
                }
            }
            /*/
            ListView {
                id: _editStockDialogPerimesListView
                visible: _editStockDialog.perimes.length > 0
                width: parent.width * 0.7
                // height: 140
                height: Math.min(140, childrenRect.height)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: -1
                clip: true

                header: Rectangle {
                    color: "transparent"
                    height: 40
                    width: parent.width

                    RowLayout {
                        anchors.fill: parent
                        spacing: -1

                        MonoTextField {
                            text: "Quantité"
                            readOnly: true
                            Layout.preferredWidth: 90
                        }
                        MonoTextField {
                            text: "Date de péremption"
                            readOnly: true
                            Layout.fillWidth: true
                        }
                    }
                }

                model: _editStockDialog.perimes

                delegate: RowLayout {
                    width: parent.width
                    spacing: -1

                    MonoTextField {
                        text: modelData.units
                        Layout.preferredWidth: 90
                        horizontalAlignment: Text.AlignRight
                        validator: IntValidator { bottom: 0 }
                    }
                    MonoTextField {
                        text: modelData.peremptionDate
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        validator: RegularExpressionValidator {
                            regularExpression:  /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/
                        }
                    }
                }

                // ScrollBar.policy: ScrollBar.AlwaysOn
                // rightMargin: 10
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                    opacity: _editStockDialogPerimesListView.contentHeight > _editStockDialogPerimesListView.height ? 1 : 0
                    anchors.right: parent.right
                    // anchors.rightMargin: -width
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 10
                }
            }
            /**/

        } // Column

        footer: Pane {
            // background: null

            background: Rectangle {
                width: parent.width
                height: 1
                color: colors.accent
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                id: _editStockDialogButtonsRow
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 20

                CustomButton {
                    text: "Enregistrer"
                    icon.source: images.check
                    enabled: _stockTextField.text !== ""


                    color: enabled ? "green" : "gray"
                    onClicked: {
                        // TODO update and edit ddi
                        _editStockDialog.close()
                    }
                }

                CustomButton {
                    text: "Fermer"
                    icon.source: images.cross

                    onClicked: {
                        _editStockDialog.close()
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------

    component MonoTextField : TextField {
        id: _monoTextField
        implicitWidth: 164
        font.family: monoFont.name
        font.pointSize: 12

        onAccepted: _monoTextField.focus = false
        palette.base: _monoTextField.readOnly ? "#CCCCFC" : "#EFEFFE"

        // MouseEvents, YOU SHALL NOT PASS
        MouseArea {
            visible: _monoTextField.readOnly
            anchors.fill: parent
        }
    }
}









