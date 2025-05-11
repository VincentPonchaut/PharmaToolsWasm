import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"

Page {
    id: _pagePreconisations
    padding: 20
    background: Rectangle {
        color: "white"
        radius: 20
        border.width: 2
        border.color: colors.accent
    }

    // -----------------------------------------
    // Data
    // -----------------------------------------

    property var selectedProviders: []
    property var currentOrder: []

    // -----------------------------------------
    // Logic
    // -----------------------------------------

    function prepareOrder() {
        // Start with visible rows
        let rows = _itemTable.rows

        // For every row, we calculate the order quantity
        // => enough qml to go over max_count
        // qml is a quantity (number of items in a batch)
        currentOrder = rows.map(
                    (row) => {
                        let howManyQmlToOrder = Math.ceil((row.max_count - row.stock) / row.qml)
                        let orderEntry = JSON.parse(JSON.stringify(row)) // clone
                        orderEntry.orderQuantity = howManyQmlToOrder

                        return orderEntry
                    })
    }
    
    // -----------------------------------------
    // View
    // -----------------------------------------

    Page {
        anchors.fill: parent
        
        
        ItemTable {
            id: _itemTable
            anchors.fill: parent
            
            enablePreconisationsFilter: false
            enableFilteringOnProviders: false
            
            columns: [
                TableModelColumn { display: "guid"; },
                TableModelColumn { display: "desc" },
                TableModelColumn { display: "ref" },
                TableModelColumn { display: "provider" },
                TableModelColumn { display: "stock" },
                TableModelColumn { display: "min_count" },
                TableModelColumn { display: "max_count" },
                TableModelColumn { display: "qml" }
            ]
            extraFilter: (row) => {
                             if (row.stock >= row.min_count) {
                                 return false
                             }
                             if (_pagePreconisations.selectedProviders.length == 0) {
                                 return true
                             }
                             if (_pagePreconisations.selectedProviders.indexOf(row.provider) === -1) {
                                 return false
                             }
                             return true

                         }
            sortRole: "stock"

            actions: [
                Action {
                    text: "Commander"
                    icon.source: images.inventory
                    onTriggered: (source) => {
                                     // TODO dialog
                                 }
                }
            ]
            
            extraHeaderActions: [
                Action {
                    text: "Fournisseurs..." + (selectedProviders.length > 0 ? " (" + selectedProviders.length + ")" : "")
                    icon.source: images.filter
                    onTriggered: (source) => {
                                     _providerFilterDialog.open()
                                 }
                }
            ]
        }

        footer: Pane {

            Row {
                // anchors.right: parent.right
                anchors.horizontalCenter: parent.horizontalCenter

                CustomButton {
                    text: "Commander Tous (%1 éléments)".arg(_itemTable.count)
                    enabled: _itemTable.count > 0

                    icon.source: images.check
                    color: "green"
                    font.family: headerFont.name
                    font.pointSize: 18
                    font.bold: true

                    onClicked: {
                        // TODO
                        prepareOrder();
                        _orderAllDialog.open()
                        console.log("Commander tous")
                    }
                }
            }
        }

    } // Page

    // ------------------------------------------------------
    // Dialogs
    // ------------------------------------------------------

    Dialog {
        id: _providerFilterDialog
        modal: true
        title: "Fournisseurs"

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        height: 420
        padding: 0

        property var selectedProviders: []
        onVisibleChanged: {
            if (visible) {
                // Set the selected providers to the current selected providers
                selectedProviders = _pagePreconisations.selectedProviders
                searchField.forceActiveFocus()
            }
        }

        onAccepted: {
            _pagePreconisations.selectedProviders = _providerFilterDialog.selectedProviders
            print("Selected providers: ", _providerFilterDialog.selectedProviders)
        }

        header: Pane {
            horizontalPadding: 20
            topPadding: 20
            bottomPadding: 0
            // palette.window: "red"
            background: null

            Column {
                spacing: 16

                Label {
                    text: "<h1>Sélectionnez les fournisseurs à afficher :</h1>"
                }

                SearchTextField {
                    id: searchField
                    placeholderText: "Rechercher..."
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: _listView.width * 0.77
                }

                Flow {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: _providerFilterDialog.selectedProviders

                        Rectangle {
                            id: _rect
                            implicitWidth: _label.implicitWidth
                            implicitHeight: _label.implicitHeight
                            radius: width
                            color: colors.accent

                            Label {
                                id: _label

                                text: "" + modelData
                                color: "white"
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 4
                                bottomPadding: 4
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: colors.accent
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: colors.contentLightBackground
        }

        ListView {
            id: _listView
            anchors.fill: parent
            clip: true
            model: database.providersWithPreconisations.filter((provider) => {
                                                                   return provider.toLowerCase().indexOf(searchField.text.toLowerCase()) !== -1
                                                               })

            delegate: CheckDelegate {
                id: checkDelegate
                width: _listView.width * 0.77
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

                text: modelData
                checked: _providerFilterDialog.selectedProviders.indexOf(modelData) !== -1
                onCheckedChanged: {
                    if (checked) {
                        if (_providerFilterDialog.selectedProviders.indexOf(modelData) === -1) {
                            _providerFilterDialog.selectedProviders.push(modelData)
                            searchField.text = ""
                        }
                    }
                    else {
                        var idx = _providerFilterDialog.selectedProviders.indexOf(modelData)
                        if (idx !== -1) {
                            _providerFilterDialog.selectedProviders.splice(idx, 1)
                        }
                    }
                    _providerFilterDialog.selectedProvidersChanged()
                }
            }
        }

        footer: Pane {
            // height: childrenRect.height
            background: Item {
                Rectangle {
                    width: parent.width
                    height: 1
                    color: colors.accent
                }
            }

            Row {
                spacing: 8
                Button {
                    text: "OK"
                    onClicked: _providerFilterDialog.accept()
                }
                Button {
                    text: "Vider"
                    enabled: _providerFilterDialog.selectedProviders.length > 0
                    onClicked: {
                        _providerFilterDialog.selectedProviders = []
                    }
                }
            }
        }
    }

    Dialog {
        id: _orderAllDialog

        modal: true
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        width: 980
        height: 480
        horizontalPadding: 10
        topPadding: 0
        bottomPadding: 0

        header: Label {
            text: "Commander %1 articles".arg(currentOrder.length)
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 20

            font.bold: true
            font.pointSize: 24
            font.family: headerFont.name
        }

        ListView {
            id: _providerFilterDialogListView
            anchors.fill: parent
            model: currentOrder
            spacing: 0
            clip: true

            delegate: Pane {
                width: _providerFilterDialogListView.width
                height: _providerFilterDialogDelegateTextField.implicitHeight + 16
                padding: 8
                palette.window: index % 2 == 0 ? colors.contentLightBackground : "white"

                Label {
                    id: _providerFilterDialogDelegateLabel
                    text: modelData.desc

                    anchors.left: parent.left
                    anchors.right: _providerFilterDialogDelegateTextField.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: _providerFilterDialogDelegateTextField.verticalCenter
                    // horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight

                    ToolTip.visible: hovered
                    ToolTip.text: modelData.desc

                    font.family: monoFont.name
                }

                TextField {
                    id: _providerFilterDialogDelegateTextField
                    anchors.right: parent.right
                    anchors.rightMargin: _providerFilterDialogDelegateStockChangeLabel.implicitWidth + 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 90

                    text: modelData.orderQuantity
                    // displayText: modelData.orderQuantity + "* qml[" + modelData.qml + "]"

                    validator: IntValidator {
                        bottom: 0
                    }
                    onTextChanged: {
                        let value = parseInt(text)
                        if (isNaN(value)) {
                            value = 0
                        }
                        modelData.orderQuantity = value
                    }
                }

                Label {
                    id: _providerFilterDialogDelegateStockChangeLabel
                    text: "x qml(%3) : %1 → %2"
                    .arg(String(modelData.stock).padStart(10, " "))
                    .arg(String(modelData.stock + modelData.orderQuantity * modelData.qml).padEnd(10, " "))
                    .arg(String(modelData.qml).padStart(5, " "))

                    anchors.left: _providerFilterDialogDelegateTextField.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16

                    font.family: monoFont.name

                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        footer: Pane {
            height: 60
            background: null
            horizontalPadding: 30
            topPadding: 0
            bottomPadding: 10

            Rectangle {
                id: _providerFilterDialogFooterLine
                width: parent.width
                height: 1
                color: colors.accent
            }

            Row {
                spacing: 8
                anchors.right: parent.right
                anchors.top: _providerFilterDialogFooterLine.bottom
                anchors.topMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                CustomButton {
                    text: "Valider"
                    icon.source: images.check
                    color: "green"
                    onClicked: {
                        // TODO
                        console.log("Order all dialog accepted")
                        _orderAllDialog.accept()
                    }
                }
                CustomButton {
                    text: "Annuler"
                    icon.source: images.cross
                    onClicked: _orderAllDialog.reject()
                }
            }
        }
    }
}
