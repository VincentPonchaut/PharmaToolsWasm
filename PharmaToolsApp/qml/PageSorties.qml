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

    function modifySortie(field, value) {
        selectedItem[field] = value
        _pageSorties.selectedItemChanged()

        // Also modify the database
        database.sorties[database.sorties.indexOf(selectedItem)][field] = value
        database.sortiesChanged()
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
        
        property var validatedItems: selectedItem.items.filter(item => item.validated === true)
        property var notYetValidatedItems: selectedItem.items.filter(item => item.validated === false)

        // ----------------------
        // Left part
        // ----------------------
        ColumnLayout {
            id: _detailsPaneDelegateLeftPart
            // anchors.fill: parent
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * 0.56
            spacing: 30

            // 1. Afficher les champs de la sortie (editables ou non)
            GroupBox {
                id: _sortieDetailsBox
                title: "Informations"

                Layout.fillWidth: true
                Layout.preferredHeight: 180

                GridLayout {
                    id: _sortieDetails
                    anchors.fill: parent
                    columns: 4

                    LabelChamp { text: "Intitulé" }
                    TextField {
                        text: selectedItem.label;
                        onTextEdited: modifySortie("label", text)
                    }
                    // Filler {}

                    LabelChamp { text: "Date" }
                    TextField {
                        text: new Date(selectedItem.date).toLocaleDateString('fr-FR');
                        onTextEdited: modifySortie("date", text)
                    }
                    // Filler {}

                    LabelChamp { text: "Utilisateur" }
                    TextField {
                        text: selectedItem.user;
                        onTextEdited: modifySortie("user", text)
                    }
                    // Filler {}

                    LabelChamp { text: "Unité fonctionnelle" }
                    TextField {
                        text: selectedItem.functional_unit;
                        onTextEdited: modifySortie("functional_unit", text)
                    }
                    // Filler {}
                }

                DisablingOverlay {
                    id: _disabledOverlay
                    visible: selectedItem.status !== "new"

                    anchors.fill: parent
                    anchors.margins: -12
                }
            }

            // 2. Afficher les produits (mouvements?)
            Items {
                title: "A Valider"
                icon: images.hourglass
                model: notYetValidatedItems
                showValidationHeader: true

                // Blink where focus is needed
                blinking: selectedItem.status === "new" || notYetValidatedItems.length > 0

                tableActions: Action {
                    text: "Lancer cette liste"
                    enabled: notYetValidatedItems.length > 0
                    // enabled: selectedItem.status === "new" && notYetValidatedItems.length > 0
                    icon.source: "../icons/ico_check.svg"
                    onTriggered: (source) => {
                                     _dialogListeLancee.open()
                                 }
                }
                rowActions: Action {
                    text: ""
                    icon.source: images.check
                    enabled: selectedItem.status === "lancé" || selectedItem.status === "non validé"
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
                        enabled: (selectedItem.status === "lancé" || selectedItem.status === "non validé")
                                 && notYetValidatedItems.length === 0
                        icon.source: "../icons/ico_check.svg"
                        onTriggered: (source) => {
                                         console.assert(false, "Finaliser action triggered", source)
                                         _finaliserDialog.open()
                                     }
                    }
                }

                DisablingOverlay {
                    visible: selectedItem.status === "new" && notYetValidatedItems.length === 0
                    opacity: 0.65
                    anchors.fill: parent
                }
            }
        }

        // ----------------------
        // Right part
        // ----------------------
        Pane {
            visible: selectedItem.status === "new"

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.44
            // padding: 0
            // leftPadding: -70

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
                    anchors.verticalCenterOffset: -parent.height * 0.13
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
                    TableModelColumn { display: "guid" },
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
        //     text: JSON.stringify(selectedItem, null, 2)
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
            property var columnChars: [
                80,
                360,
                80,
                80
            ]
            property var columnAlignments: [
                Text.AlignRight,
                Text.AlignLeft,
                Text.AlignRight,
                Text.AlignRight
            ]

            section.property: "location"
            section.delegate: Label {
                text: "" + section
                width: parent.width
                height: 90
                //                text: "Emplacement : " + section
                topPadding: 30
                font.pointSize: 20
                font.underline: false
                font.bold: true

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "black"
                    opacity: 0.5
                    y: 60
                }

                RowLayout {
                    y: 60
                    width: parent.width
                    height: 50

                    Item {
                        Layout.preferredWidth: 40
                    }

                    Repeater {
                        model: [
                            "Code Produit",
                            "Produit",
                            "REF",
                            "Quantité"
                        ]

                        Label {
                            text: modelData
                            font.pointSize: 16
                            font.bold: true
                            font.underline: true
                            horizontalAlignment: Text.AlignHCenter
                            topPadding: 10

                            Layout.preferredWidth: _dialogListeLanceeListView.columnChars[index]
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            delegate: Item {
                id: _dialogListeLanceeListViewDelegate
                width: parent.width
                height: 50

                required property var modelData
                property var theItem: database.findByGuid(modelData.guid)


                RowLayout {
                    anchors.fill: parent

                    CheckBox {
                        // anchors.verticalCenter: parent.verticalCenter
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Repeater {
                        model: [
                            theItem.guid,
                            theItem.desc,
                            theItem.ref,
                            modelData.count,
                        ]

                        Label {
                            id: _lalala
                            required property var modelData
                            required property int index
                            // height: parent.height
                            // width: columnChars[_lalala.index]
                            Layout.preferredWidth: _dialogListeLanceeListView.columnChars[_lalala.index]
                            Layout.fillHeight: true

                            text: String(modelData)
//                            text: String(modelData).padEnd(_dialogListeLanceeListViewDelegate.columnChars[_lalala.index]," ")

                            topPadding: 20
                            bottomPadding: 20
                            leftPadding: 50

                            font.family: monoFont.name
                            font.pointSize: 14
                            font.weight: Font.DemiBold

                            horizontalAlignment: _dialogListeLanceeListView.columnAlignments[_lalala.index]
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
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

                        let html = ""
                        // Generate a default HTML file
                        html += "<html>"
                        html += "<head>"
                        html += "<title>" + selectedItem["label"] + "</title>"
                        html += "<style>"
                        html += "body { font-family: Arial, sans-serif; }"
                        html += "h1 { color: #333; }"
                        html += "table { border-collapse: collapse; width: 100%; font-size: 12px; }"
                        html += "th, td { border: 1px solid #ddd; padding: 8px; }"
                        html += "th { background-color: #f2f2f2; }"
                        html += "</style>"
                        html += "</head>"
                        html += "<body>"
                        html += "<h1>" + selectedItem["label"] + "</h1>"
                        html += "<h4>Par : " + selectedItem["user"] + "</h4>"
                        html += "<h4>Service : " + selectedItem["functional_unit"] + "</h4>"
                        html += "<table>"
                        html += "<tr>"
                        html += "<th>Produit</th>"
                        html += "<th>Référence</th>"
                        html += "<th>Quantité</th>"
                        html += "<th>Emplacement</th>"
                        html += "</tr>"
                        selectedItem["items"].forEach((item) => {
                                                          let itemData = database.findByGuid(item.guid)
                                                          html += "<tr>"
                                                          html += "<td>" + itemData.desc + "</td>"
                                                          html += "<td>" + itemData.ref + "</td>"
                                                          html += "<td>" + item.count + "</td>"
                                                          html += "<td>" + item.location + "</td>"
                                                          //                            html += "<td>" + _itemDelegateEmplacementComboBox.modelData + "</td>"
                                                          html += "</tr>"
                                                      })
                        html += "</table>"
                        html += "</body>"
                        html += "</html>"

                        PrintHelper.printHtml(html)
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
                    text: _validateLineDialog.lineToValidate ? "" + database.findByGuid(_validateLineDialog.lineToValidate.guid).desc
                                                             : ""
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
                            when: _validateLineDialog.lineToValidate && !isNaN(_validateLineDialog.lineToValidate.count)
                            value: _validateLineDialog.lineToValidate ? String(_validateLineDialog.lineToValidate.count)
                                                                      : ""
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
                        if (!_validateLineDialog.lineToValidate)
                            return ""

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
                width: parent.width
                // palette.window: colors.accent // TODO padding

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    CustomButton {
                        text: "Oui"
                        font.pointSize: 12
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
                        font.pointSize: 12
                        icon.source: images.cross
                        color: "#8b8b8e"
                        onClicked: _validateLineDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: _finaliserDialog
        modal: true
        // visible: true

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2

        padding: 20
        height: 250
        width: 650

        onAccepted: {
            // TODO finaliser la liste
            console.log("Finaliser la liste")
            masterPaneModel = masterPaneModel.filter(item => item.id !== selectedItem.id)
            selectedItem = null
        }

        Page {
            anchors.fill: parent
            clip: true

            header: Header {
                text: "Finaliser la liste"
                font.underline: true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Label {
                    text: "Êtes-vous sûr de vouloir finaliser cette liste ?"
                    width: parent.width
                    font.pointSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: "Elle sera supprimée des Sorties en cours"
                    width: parent.width
                    font.pointSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            footer: Pane {
                width: parent.width
                // palette.window: colors.accent // TODO padding

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    CustomButton {
                        text: "Oui"
                        font.pointSize: 12
                        icon.source: images.check
                        color: "green"
                        onClicked: {
                            _finaliserDialog.accepted()
                            _finaliserDialog.close()
                            // TODO finaliser la liste
                        }
                    }

                    CustomButton {
                        text: "Annuler"
                        font.pointSize: 12
                        icon.source: images.cross
                        color: "#8b8b8e"
                        onClicked: _finaliserDialog.close()
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

            LabelMono {
                text: texts[0]
                Layout.preferredWidth: 110
                horizontalAlignment: Text.AlignRight
            }

            // Line {}
            LabelMono {
                text: texts[1]
                Layout.preferredWidth: 360
            }

            // Line{}
            LabelMono {
                text: texts[2]
                Layout.preferredWidth: 140
            }

            // Line{}
            LabelMono {
                text: texts[3]
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignRight
            }

            // Line{}
            LabelMono {
                visible: texts.length > 4
                text: texts[4] ?? ""
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
        property bool showValidationHeader: false

        Layout.preferredWidth: _sortieItems.parent.width
        Layout.fillWidth: true
        Layout.fillHeight: true

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
                        _sortieItemDelegate.modelData.guid,
                        database.findByGuid(_sortieItemDelegate.modelData.guid).desc,
                        _sortieItemDelegate.modelData.location ?? "",
                        _sortieItemDelegate.modelData.count,
                        // String(_sortieItemDelegate.index)
                    ]
                    actions: _sortieItems.rowActions
                    rowIndex: _sortieItemDelegate.index
                }
            }

            header: TableRow {
                width: parent.width
                font.bold: true
                font.underline: true
                palette.window: colors.lightBackground
                texts: [
                    "Code Produit",
                    "Produit",
                    "Emplacement",
                    "Quantité",
                ].concat(_sortieItems.showValidationHeader ? ["Validation"] : [])
                rowIndex: -1
            }
        }
    }

}
