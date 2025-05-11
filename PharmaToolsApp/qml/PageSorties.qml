import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"

MasterDetails {
    id: _pageSorties

    // ---------------------------------------------------------------
    // Logic
    // ---------------------------------------------------------------

    function validateLineInCurrent(lineIndex) {
        let line = selectedItem.items.filter(item => item.validated === false)[lineIndex]
        if (!line) {
            console.assert(false, "Line not found in current item")
            return
        }

        console.log("Validating line", line)
        _validateLineDialog.lineToValidate = line
        _validateLineDialog.open()
    }

    function linesAreEqual(lineA, lineB) {
        // TODO je peux pas identifier sans un identifiant de ligne
        return lineA.guid === lineB.guid && lineA.location === lineB.location
    }

    function pushLineModifications(line) {
        for (let i = 0; i < selectedItem.items.length; i++) {
            if (linesAreEqual(selectedItem.items[i], line)) {
                selectedItem.items[i] = line
                selectedItem.items[i].validated = true
                break
            }
        }

        _pageSorties.selectedItemChanged()
    }
    
    // ---------------------------------------------------------------
    // View
    // ---------------------------------------------------------------

    masterPaneWidth: _pageSorties.width * 0.2
    masterPaneModel: database.sorties
    masterPaneTitle: "Sorties en cours"
    masterPaneDisplayRole: "label"
    masterPaneDelegateFormatter: (qmlItem, modelData) => {
                                     if (modelData.status === "new") {
                                         qmlItem.font.italic = true
                                     }
                                     else if (modelData.status === "lancé" || modelData.status === "non validé") {
                                         qmlItem.icon.source = images.hourglass
                                     }
                                     else if (modelData.status === "validé") {
                                         qmlItem.color = "green"
                                     }
                                 }
    
    canCreate: true
    createCallback: () => {
                        console.log("Create callback")
                        const today = new Date(Date.now())
                        const todayStr = today.toLocaleDateString('fr-FR', {
                                                                      weekday: "long",
                                                                      year: "numeric",
                                                                      month: "long",
                                                                      day: "numeric",
                                                                  })
                        database.sorties.push({
                                                  id: database.sorties.length,
                                                  user: gui.username,
                                                  date: today.toString(),
                                                  label: "Sortie du " + todayStr,
                                                  functional_unit: "",
                                                  status: "new",
                                                  items: []
                                              })
                        database.sortiesChanged()

                        selectedItem = database.sorties[database.sorties.length - 1]
                    }
    
    detailsPaneTitle: _pageSorties.selectedItem?.label || ""
    detailsPaneDelegate: Rectangle {
        color: "transparent"
        anchors.fill: parent
        
        required property var modelData
        property var validatedItems: modelData.items.filter(item => item.validated === true)
        property var notYetValidatedItems: modelData.items.filter(item => item.validated === false)

        // ----------------------
        // Left part
        // ----------------------
        ColumnLayout {
            id: _detailsPaneDelegateLeftPart
            // anchors.fill: parent
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            spacing: 30

            // 1. Afficher les champs de la sortie (editables ou non)
            GroupBox {
                id: _sortieDetailsBox
                title: "Informations"

                Layout.preferredWidth: 430
                Layout.preferredHeight: 180

                GridLayout {
                    id: _sortieDetails
                    anchors.fill: parent
                    columns: 3

                    LabelChamp { text: "Intitulé" }
                    TextField { text: modelData.label; onTextChanged: selectedItem.label = text }
                    Filler {}

                    LabelChamp { text: "Date" }
                    TextField { text: new Date(modelData.date).toLocaleDateString('fr-FR'); onTextChanged: selectedItem.date = text }
                    Filler {}

                    LabelChamp { text: "Utilisateur" }
                    TextField { text: modelData.user; onTextChanged: selectedItem.user = text }
                    Filler {}

                    LabelChamp { text: "Unité fonctionnelle" }
                    TextField { text: modelData.functional_unit; onTextChanged: selectedItem.functional_unit = text }
                    Filler {}
                }

                DisablingOverlay {
                    id: _disabledOverlay
                    visible: modelData.status !== "new"

                    anchors.fill: parent
                    anchors.margins: -12
                }
            }

            // 2. Afficher les produits (mouvements?)
            Items {
                title: "A Valider"
                icon: images.hourglass
                model: notYetValidatedItems

                // Blink where focus is needed
                blinking: modelData.status === "new" || notYetValidatedItems.length > 0

                tableActions: Action {
                    text: "Lancer cette liste"
                    // enabled: modelData.status === "new" && notYetValidatedItems.length > 0
                    icon.source: "../icons/ico_check.svg"
                    onTriggered: (source) => {
                                     _dialogListeLancee.open()
                                 }
                }
                rowActions: Action {
                    text: ""
                    icon.source: images.check
                    enabled: modelData.status === "lancé" || modelData.status === "non validé"
                    onTriggered: (source) => {
                                     // console.log("Ok action triggered", source, source.rowIndex)
                                     validateLineInCurrent(source.rowIndex)
                                 }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: _ikals.implicitHeight

                Items {
                    id: _ikals
                    title: "Validés"
                    icon: images.check
                    model: validatedItems
                    anchors.fill: parent
                    blinking: _finaliserAction.enabled

                    tableActions: Action {
                        id: _finaliserAction
                        text: "Finaliser"
                        enabled: (modelData.status === "lancé" || modelData.status === "non validé")
                                 && notYetValidatedItems.length === 0
                        icon.source: "../icons/ico_check.svg"
                        onTriggered: (source) => {
                                         console.assert(false, "Finaliser action triggered", source)
                                     }
                    }
                }

                DisablingOverlay {
                    visible: modelData.status === "new" && notYetValidatedItems.length === 0
                    opacity: 0.65
                    anchors.fill: parent
                }
            }
        }

        // ----------------------
        // Right part
        // ----------------------
        Pane {
            visible: modelData.status === "new"

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 770
            // padding: 0
            leftPadding: -70

            scale: 0.9
            anchors.rightMargin: -60

            background: Rectangle {
                color: "#EFEFFE"
                radius: 16

                Rectangle {
                    id: _tip
                    color: parent.color
                    height: 60
                    width: height
                    rotation: -45
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -parent.height * 0.07
                    anchors.horizontalCenter: parent.left
                }
            }

            ItemTable {
                id: _itemSelectorTable
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
                                         console.log("Add action triggered", JSON.stringify(_itemSelectorTable.currentItem))
                                         _dialog.item = _itemSelectorTable.currentItem
                                         _dialog.open()
                                         // _dialog.accepted.connect(_itemSelectorTable.focusSearchTextField)
                                         // TODO implement add action
                                     }
                    }
                ]
                Connections {
                    target: _dialog
                    function onAccepted() {
                        _itemSelectorTable.focusSearchTextField()
                    }
                }
            }

        }
        // // Debug...
        // Label {
        //     text: JSON.stringify(modelData, null, 2)
        //     font.family: monoFont.name
        //     anchors.right: parent.right
        // }
        
    }

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

        function addToCurrent() {
            if (!item || quantity === 0)
                return

            console.log("Adding %1 to current with quantity %2".arg(item.desc).arg(quantity))

            // Test: Find a location that contains the item
            let itemData = database.findByGuid(item.guid)
            if (!itemData) {
                console.assert(false, "Item not found in database")
                return
            }
            let location = itemData.locations[0].location

            selectedItem["items"].push({
                                           "count": quantity,
                                           "guid": item.guid,
                                           "location": location,
                                           "validated": false
                                       })
            _pageSorties.selectedItemChanged()
            _dialog.close()
            _dialog.accepted()
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
                    _dialog.addToCurrent()
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

        height: _pageSorties.height
        width: /* A4 ratio */ height * 0.707

        header: Column {
            padding: 40
            spacing: 10

            Header {
                text: selectedItem["label"] + " par " + selectedItem["user"]
                font.underline: true
            }
        }

        ListView {
            id: _dialogListeLanceeListView
            anchors.fill: parent

            model: selectedItem["items"].filter(item => item.validated === false)
            property int maxCountLetters: {
                let max = 0
                _dialogListeLanceeListView.model.forEach(item => {
                                                             if (String(item.count).length > max) {
                                                                 max = String(item.count).length
                                                             }
                                                         })
                return max
            }

            section.property: "location"
            section.delegate: Label {
                text: "" + section
                //                text: "Emplacement : " + section
                topPadding: 20
                font.pointSize: 20
                font.underline: true
                font.bold: true
            }

            delegate: Label {
                text: {
                    // Code produit, dénomination, Ref, xQuantité
                }
//                text: String(modelData.count).padStart(_dialogListeLanceeListView.maxCountLetters, " ") + " x " + database.findByGuid(modelData.guid).desc
                // height: 60

                topPadding: 20
                bottomPadding: 20
                leftPadding: 50

                font.family: monoFont.name
                font.pointSize: 14
                font.weight: Font.DemiBold

                verticalAlignment: Text.AlignVCenter

                CheckBox {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        footer: Pane {
            padding: 40
            background: Rectangle {
                color: colors.accent
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                CustomButton {
                    text: "Imprimer et commencer"
                    icon.source: images.printer
                    color: "green"
                    onClicked: {
                        _dialogListeLancee.close()
                        selectedItem.status = "lancé"
                        _pageSorties.selectedItemChanged()
                    }
                }

                CustomButton {
                    text: "Annuler"
                    color: "#8b8b8e"
                    onClicked: _dialogListeLancee.close()
                }
            }
        }
    }

    Dialog {
        id: _validateLineDialog
        modal: true
        // visible: true

        // property var lineToValidate: selectedItem.items.filter(item => item.validated === false)[0]
        property var lineToValidate: null

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        padding: 20
        height: 360
        width: 650

        Page {
            anchors.fill: parent
            clip: true

            header: Header {
                text: "Validation de la ligne"
                font.underline: true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Label {
                    text: "Êtes-vous sûr de vouloir valider cette modification ?"
                    width: parent.width
                    font.pointSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                LabelMono {
                    text: "" + database.findByGuid(_validateLineDialog.lineToValidate.guid).desc
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    height: _validateLineDialogTextField.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Label {
                        text: "Déplacer"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: _validateLineDialogTextField
                        width: 120

                        horizontalAlignment: Text.AlignRight
                        validator: IntValidator { bottom: 0 }

                        Binding on text {
                            when: !isNaN(_validateLineDialog.lineToValidate.count)
                            value: String(_validateLineDialog.lineToValidate.count)
                        }
                        onTextChanged: {
                            if (text.length === 0) {
                                // text = "0"
                                return
                            }
                            _validateLineDialog.lineToValidate.count = parseInt(text)
                            _validateLineDialog.lineToValidateChanged()
                        }
                    }

                    Label {
                        text: "unités"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                LabelMono {
                    text: {
                        let qtyAvant = database.quantityAtLocation(_validateLineDialog.lineToValidate.guid)
                        let qtyApres = qtyAvant - _validateLineDialog.lineToValidate.count

                        qtyAvant = String(qtyAvant).padStart(10, " ")
                        qtyApres = String(qtyApres).padStart(10, " ")

                        return `Stock avant : ${qtyAvant}\nStock apres : ${qtyApres}`
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: monoFont.name
                }

            }

            footer: Pane {
                // palette.window: colors.accent // TODO padding

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    CustomButton {
                        text: "Oui"
                        icon.source: images.check
                        color: "green"
                        onClicked: {
                            _validateLineDialog.accepted()
                            _validateLineDialog.close()
                            _pageSorties.pushLineModifications(_validateLineDialog.lineToValidate)
                        }
                    }

                    CustomButton {
                        text: "Annuler"
                        icon.source: images.cross
                        color: "#8b8b8e"
                        onClicked: _validateLineDialog.close()
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------
    Component.onCompleted: {
        /**/
        // selectedItem = database.sorties[2]
        /*/
        createCallback()

        _later.callback = () => {
            _pageSorties.selectedItem["items"].push({
                                                        "count": "1234",
                                                        "guid": 200509,
                                                        "location": "SOL.  6.  2",
                                                        "validated": false
                                                    })
            _pageSorties.selectedItem["items"].push({
                                                        "count": "12",
                                                        "guid": 200510,
                                                        "location": "SOL.  6.  2",
                                                        "validated": false
                                                    })
            _pageSorties.selectedItem["items"].push({
                                                        "count": "999",
                                                        "guid": 808280,
                                                        "location":  "ENT. 29.  3",
                                                        "validated": false
                                                    })
            _pageSorties.selectedItemChanged()
        }
        _later.start()
        /**/
    }
    Timer {
        id: _later
        interval: 50
        property var callback: null
        running: false
        onTriggered: {
            if (callback) {
                callback()
                callback = null
            }
        }
    }

    component Filler: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    component LabelChamp: Header {
        // Layout.fillWidth: true
        Layout.fillHeight: true

        font.pointSize: 12
        leftPadding: 20
        rightPadding: 20

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    component DisablingOverlay: Rectangle {
        anchors.fill: parent

        color: "white"
        opacity: 0.3

        MouseArea {
            anchors.fill: parent
        }
    }

    component LabelMono: Label {
        font.family: monoFont.name
        font.pointSize: 11
        elide: Text.ElideRight
    }
    component Line: Rectangle {
        color: "black"
        opacity: 0.5
        Layout.preferredWidth: 1
        Layout.fillHeight: true

        Rectangle {
            width: 1
            height: parent.height
            anchors.bottom: parent.bottom

            color: "black"
            // opacity: 0.5
        }
    }

    component TableRow: Pane {
        id: _tableRowComponent
        required property var texts
        required property int rowIndex
        property list<Action> actions: []

        RowLayout {
            id: _tableRow
            width: parent.width
            spacing: 30

            // Line {}
            LabelMono {
                text: texts[0]
                Layout.preferredWidth: 280
            }

            // Line{}
            LabelMono {
                text: texts[1]
                Layout.preferredWidth: 100
            }

            // Line{}
            LabelMono {
                text: texts[2]
                Layout.preferredWidth: 70
                horizontalAlignment: Text.AlignRight
            }

            // Line{}
            LabelMono {
                visible: texts.length > 3
                text: texts[3] ?? ""
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
            }
            Repeater {
                model: actions

                Item {
                    Layout.preferredWidth: 90
                    Layout.fillHeight: true

                    CustomButton {
                        action: modelData
                        anchors.horizontalCenter: parent.horizontalCenter

                        property int rowIndex: _tableRowComponent.rowIndex

                        height: 28
                        verticalPadding: 2
                        horizontalPadding: 2

                        color: "green"
                        font.pointSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }

    component Items: GroupBox {
        id: _sortieItems
        // title: "Produits"
        clip: true
        font.family: headerFont.name
        font.pointSize: 20
        font.bold: true

        property alias model: _sortieItemsListView.model
        property list<Action> tableActions: []
        property list<Action> rowActions: []
        property alias blinking: _animation.running
        property url icon: images.check

        Layout.preferredWidth: 680
        Layout.fillHeight: true
        // Layout.rightMargin: _sortieItems.width * 0.3

        label: Row {
            width: _sortieItems.availableWidth
            spacing: 2

            RecoloredImage {
                source: _sortieItems.icon
                color: colors.accent
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
            }
            Header {
                // x: control.leftPadding
                text: _sortieItems.title
                font.pointSize: 20
                color: colors.accent
                elide: Text.ElideRight
            }
        }

        SequentialAnimation on palette.mid {
            id: _animation
            running: false
            loops: Animation.Infinite

            ColorAnimation {
                to: colors.accent
                duration: 1300
            }

            ColorAnimation {
                to: "red"
                duration: 1300
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.bottomMargin: 15

            Repeater {
                model: _sortieItems.tableActions

                CustomButton {
                    height: 28
                    verticalPadding: 1
                    horizontalPadding: 8
                    action: modelData
                    font.weight: Font.DemiBold
                }
            }
        }

        ListView {
            id: _sortieItemsListView
            anchors.fill: parent
            spacing: 0
            clip: true

            delegate: Pane {
                id: _sortieItemDelegate
                width: parent.width
                height: 50
                padding: 0

                required property var modelData
                required property int index

                TableRow {
                    id: _sortiesItemDelegateTableRow
                    font.bold: false
                    width: parent.width
                    texts: [
                        database.findByGuid(_sortieItemDelegate.modelData.guid).desc,
                        _sortieItemDelegate.modelData.location ?? "",
                        _sortieItemDelegate.modelData.count,
                        // String(_sortieItemDelegate.index)
                    ]
                    // Oula le karma qu'on va se taper apres ca
                    .concat(_sortieItems.rowActions.length === 0 ? [(_sortieItemDelegate.modelData.validated ? "✅" : "❌")]
                    : [])
                    actions: _sortieItems.rowActions
                    rowIndex: _sortieItemDelegate.index
                }
            }

            header: TableRow {
                font.bold: true
                font.underline: true
                palette.window: colors.lightBackground
                texts: [
                    "Produit",
                    "Emplacement",
                    "Quantité",
                    "Validation"
                ]
                rowIndex: -1
            }
        }
    }

}
