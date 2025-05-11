import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

Pane {
    id: itemTable

    // -------------------------------------------------------------
    // Data
    // -------------------------------------------------------------

    property var tableData: {
        "guid": {
            "role": "guid",
            "header": "Code produit",
            "columnWidth": 140,
            "textAlignment": Text.AlignRight
        },
        "desc": {
            "role": "desc",
            "header": "Désignation",
            "columnWidth": 440,
        },
        "locations": {
            "role": "locations",
            "header": "Emplacements",
            "columnWidth": 190,
        },
        "stock": {
            "role": "stock",
            "header": "Stock",
            "columnWidth": 90,
            "textAlignment": Text.AlignRight
        },
        "min_count": {
            "role": "min_count",
            "header": "Mini",
            "columnWidth": 80,
            "textAlignment": Text.AlignRight
        },
        "max_count": {
            "role": "max_count",
            "header": "Maxi",
            "columnWidth": 80,
            "textAlignment": Text.AlignRight
        },
        "provider": {
            "role": "provider",
            "header": "Fournisseur",
            "columnWidth": 290,
            "textAlignment": Text.AlignLeft
        },
        "ref": {
            "role": "ref",
            "header": "REF",
            "columnWidth": 200,
        },
        "qml": {
            "role": "qml",
            "header": "QML",
            "columnWidth": 100,
        },
        "ddi": {
            "role": "date_dernier_inventaire",
            "header": "Dernier inventaire",
            "columnWidth": 180,
            "textAlignment": Text.AlignRight
        },
    }

    property var extraFilter: (row) => true
    property list<TableModelColumn> columns: []
    property list<Action> actions: []
    property list<Action> extraHeaderActions: []

    property alias enableFilteringOnProviders: providerComboBox.visible
    property alias enablePreconisationsFilter: preconisationFilterButton.visible
    property bool flattenLocations: false
    property bool showTotalFooter: false

    property alias currentRow: _tableView.currentRow
    property var currentItem: tableModel.rows[currentRow]
    Binding on currentItem {
        when: currentRow > -1
        value: tableModel.rows[currentRow]
    }

    property var modelSource: database.inventory
    property int count: tableModel.rows.length - 1
    readonly property var rows: tableModel.rows.filter(function(row) {
        return typeof(row.dummy) === "undefined"
    })

    // -------------------------------------------------------------
    // Logic
    // -------------------------------------------------------------

    function columnIndexOf(colStr){
        let idx = -1;

        itemTable.columns.forEach((col, colIndex) => {
                                      if (col.display == colStr) {
                                          idx = colIndex
                                      }
                                  })
        //        let idx = Object.keys(tableData).indexOf(colStr)
        if (idx === -1) {
            console.error("Column not found:", colStr)
            return 999 // because of Delegate Chooser logic
        }
        return idx
    }


    function columnWidth(columnIndex) {
        let c = columnData(columnIndex)
        if (c) {
            return c.columnWidth
        }
        return 100
    }

    function columnData(columnIndex) {
        let column = itemTable.columns[columnIndex]
        if (column) {
            return tableData[column.display]
        }
        return null
    }

    function columnName(columnIndex) {
        let c = columnData(columnIndex)
        return c ? c.header : ""
    }

    function select(row) {
        _tableView.selectionModel.setCurrentIndex(tableModel.index(row,0), ItemSelectionModel.Current)
    }

    function selectNextRow() {
        if (tableModel.rows.length === 1) // only the dummy row
            return

        let nextRow = currentRow + 1
        if (nextRow < tableModel.rows.length - 1) {
            select(nextRow)
        }
        else {
            select(0)
        }
    }

    function selectPrevRow() {
        if (tableModel.rows.length === 1) // only the dummy row
            return

        let prevRow = currentRow - 1
        if (prevRow >= 0) {
            select(prevRow)
        }
        else {
            select(tableModel.rows.length - 2)
        }
    }

    function focusSearchTextField() {
        searchField.forceActiveFocus()
        searchField.selectAll()
    }

    signal activateCurrentRow(var currentRowData);
    onActivateCurrentRow: {
        if (actions.length > 0) {
            let action = actions[0]
            if (action) {
                action.trigger(this)
            }
        }
    }

    // -------------------------------------------------------------
    // View
    // -------------------------------------------------------------

    property string sortRole: Object.keys(tableData)[0]
    property bool ascending: true
    property bool preconisationFilter: false
    property string emplacementFilter: ""
    property bool centerTableView: true

    background: null
    topPadding: 20
    horizontalPadding: 20
    bottomPadding: 2
    
    Page {
        anchors.fill: parent
        background: null

        RowLayout {
            id: _rorororo
            // anchors.horizontalCenter: _tableView.horizontalCenter
            anchors.left: inventoryHeaderView.left
            width: _tableView.width
            spacing: 12

            SearchTextField {
                id: searchField
                Layout.preferredWidth: searchField.activeFocus ? 360 : 260

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Keys.onReturnPressed: activateCurrentRow(itemTable.currentItem)
                Keys.onUpPressed: selectPrevRow()
                Keys.onDownPressed: selectNextRow()

                onTextChanged: _tableView.contentY = 0
            }

            ComboBox {
                id: providerComboBox
                Layout.preferredWidth: 300
                editable: true

                model: {
                    let providers = database.inventory.map(function(item) {
                        return item.provider
                    })
                    let uniqueProviders = [...new Set(providers)]
                    return uniqueProviders
                }
            }

            MultiComboBox {
                id: _searchFieldKeyComboBox
                Layout.preferredWidth: 300

                selectedIndexes: [columnIndexOf("desc")] // TODO do not allow to uncheck if 0 selectedIndexes
                // selectedIndexes: [columnIndexOf("desc"), columnIndexOf("guid")]
                displayText: "Chercher dans: " + _searchFieldKeyComboBox.selectedIndexes.map(function(idx) {
                    return _searchFieldKeyComboBox.model[idx]
                }).join(", ")
                model: itemTable.columns.map((_, ind) => columnData(ind).header)

            }

            Repeater {
                model: itemTable.extraHeaderActions

                CustomButton {
                    action: modelData
                }
            }

            // >>>>>>>>>>>>>>>>>>>>>>>
            Item {
                Layout.fillWidth: true
            }
            // <<<<<<<<<<<<<<<<<<<<<<<

            Button {
                id: _emplacementFilterButton
                visible: emplacementFilter.length > 0

                property color locColor: _.getColorForLocationName(emplacementFilter)
                property color txtColor: _.getTextColorForLocationColor(locColor)

                text: "Filtre: " + emplacementFilter
                palette.buttonText: txtColor

                icon.source: images.cross
                icon.height: 16
                icon.width: 16
                icon.color: _emplacementFilterButton.txtColor

                horizontalPadding: 20
                verticalPadding: 12

                background: Rectangle {
                    color: _emplacementFilterButton.locColor
                    border.color: _emplacementFilterButton.txtColor
                    border.width: 2
                    radius: width
                }

                onClicked: {
                    emplacementFilter = ""
                }
            }

            CustomButton {
                text: "Imprimer"
                visible: emplacementFilter.length > 0
                icon.source: images.printer
            }

            Button {
                id: preconisationFilterButton
                text: "Préconisations (%1)".arg(database.preconisations.length)
                checkable: true
                checked: preconisationFilter

                horizontalPadding: 34
                Layout.alignment: Qt.AlignVCenter

                onClicked: {
                    preconisationFilter = !preconisationFilter
                }
            }
        }

        HorizontalHeaderView {
            id: inventoryHeaderView
            width: _tableView.width
            clip: true
            anchors.left: _tableView.left
            anchors.top: _rorororo.bottom
            anchors.topMargin: 16
            interactive: false

            syncView: _tableView
            // textRole: "modelData"
            // movableColumns: true

            delegate: Rectangle {
                implicitWidth: Math.min(100, childrenRect.width * 1.3)
                implicitHeight: 40
                color: "#F3F6F6"

                property var colData: {
                    if (!model.display)
                        return null
                    tableData[_tableView.model.columns[parseInt(model.display-1)].display]
                }

                Label {
                    id: _headerViewLabel
                    text: {
                        if (!colData)
                            return ""

                        let result = colData.header;

                        if (sortRole === colData.role) {
                            return result + (ascending ? " ▲" : " ▼")
                        }
                        return result
                    }

                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8

                    font.family: headerFont.name
                    font.weight: Font.DemiBold
                    font.pointSize: 14
                    font.underline: _headerViewLabelMouseArea.containsMouse

                    MouseArea {
                        id: _headerViewLabelMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            let thisRole = colData.role
                            if (sortRole === thisRole) {
                                ascending = !ascending
                            } else {
                                ascending = true
                                sortRole = thisRole
                            }
                        }
                    }
                }

                Line {
                    anchors.top: parent.top
                }
                Line {
                    anchors.bottom: parent.bottom
                }
            }
        }
        TableView {
            id: _tableView
            width: Math.min(childrenRect.width, parent.width)
            anchors.top: inventoryHeaderView.bottom
            anchors.bottom: parent.bottom
            // anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            Binding on anchors.horizontalCenter {
                when: centerTableView
                value: _tableView.parent.horizontalCenter
            }
            Binding on anchors.left {
                when: !centerTableView
                value: _tableView.parent.left
            }

            resizableColumns: true
            keyNavigationEnabled: true
            selectionModel: ItemSelectionModel {}
            selectionBehavior: TableView.SelectRows

            Keys.onReturnPressed: activateCurrentRow(itemTable.currentItem)

            model: TableModel {
                id: tableModel

                columns: itemTable.columns

                // TableModelColumn { display: "guid"; }
                // TableModelColumn { display: "desc" }
                // TableModelColumn { display: "locations" }
                // TableModelColumn { display: "stock" }
                // TableModelColumn { display: "min_count" }
                // TableModelColumn { display: "max_count" }
                // TableModelColumn { display: "provider" }
                // TableModelColumn { display: "ref" }
                // TableModelColumn { display: "qml" }

                rows: {
                    let actualModelSource = modelSource
                    if (flattenLocations) {
                        let fixed = [];
                        actualModelSource.forEach((item) => {
                                                item.locations.forEach((location) => {
                                                                           let newItem = JSON.parse(JSON.stringify(item))
                                                                           newItem.locations = [location]
                                                                           fixed.push(newItem)
                                                                       })
                                            })
                        actualModelSource = fixed
                    }

                    return actualModelSource.filter(function(row) {
                        if (emplacementFilter.length > 0 && row.locations[0].location !== emplacementFilter)
                            return false

                        const tokens = searchField.text.split(" ")
                        let acceptRow = true
                        for (let j = 0; j < tokens.length; j++)
                        {
                            let tokenMatchesAtLeastOneColumn = false
                            let token = tokens[j]

                            for (let i = 0; i < _searchFieldKeyComboBox.selectedIndexes.length; i++)
                            {
                                let idx = _searchFieldKeyComboBox.selectedIndexes[i]
                                let key = itemTable.columns[idx].display

                                // Recherche dans emplacements
                                if (key === "locations") {
                                    row.locations.forEach((location) => {
                                        if (location.location.toLowerCase().includes(token.toLowerCase())) {
                                            tokenMatchesAtLeastOneColumn = true
                                        }
                                    })
                                }
                                // Recherche par defaut
                                else if (row[key] && row[key].toString().toLowerCase().includes(token.toLowerCase())) {
                                    tokenMatchesAtLeastOneColumn = true
                                }
                            }

                            acceptRow = acceptRow && tokenMatchesAtLeastOneColumn
                        }

                        // _searchFieldKeyComboBox.selectedIndexes.forEach((idx) => {
                        //     print(">>>>>> filtering on:", itemTable.columns[idx].display)
                        //     let key = itemTable.columns[idx].display
                        //     acceptRow = acceptRow || fuzzySearchMulti(searchField.text, row[key])
                        // })
                        // return false;

                        return acceptRow
                    })
                    .filter(extraFilter)
                    .sort(function(a, b) {
                        let res = 0
                        if (sortRole === "guid")
                            res = a.guid - b.guid
                        else if (sortRole === "desc")
                            res = a.desc.localeCompare(b.desc)
                        else if (sortRole === "provider")
                            res = a.provider.localeCompare(b.provider)
                        else if (sortRole === "ref")
                            res = a.ref.localeCompare(b.ref)
                        else if (sortRole === "qml")
                            res = a.qml.localeCompare(b.qml)
                        else if (sortRole === "stock")
                            res = a.stock - b.stock;
                        else if (sortRole === "min_count")
                            res = a.min_count - b.min_count;
                        else if (sortRole === "max_count")
                            res = a.max_count - b.max_count;
                        else if (sortRole === "locations")
                            res = a.locations[0].location.localeCompare(b.locations[0].location)
                        else
                            res = a.guid - b.guid

                        return ascending ? res : -res
                    })
                    .concat({
                                "dummy": true,
                                "guid": "-",
                                "desc": "-",
                                "locations": [],
                                "stock": "-",
                                "min_count": "-",
                                "max_count": "-",
                                "provider": "-",
                                "ref": "-",
                                "qml": "-",
                                "ddi": "-",
                            })
                }
            }

            delegate: DelegateChooser {
                DelegateChoice {
                    row: tableModel.rows.length - 1

                    Cell {
                        implicitHeight: Number.MIN_VALUE
                        height: Number.MIN_VALUE

                        Rectangle {
                            anchors.fill: parent
                            color: "red"
                        }
                    }
                }

                DelegateChoice {
                    column: columnIndexOf("locations")
                    delegate: Cell {

                        RectangleText {
                            id: _emplacementCellDelegate
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter

                            text: {
                                if (model.modelData.length === 1)
                                    return model.modelData[0].location
                                else
                                    return "Multiple"
                                return model.modelData.map(function(item) {
                                    return item.location
                                }).join("\n")
                            }
                            color: _.getColorForLocationName(text)
                            font.underline: hovered

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    emplacementFilter = _emplacementCellDelegate.text
                                }
                            }
                        }
                    }
                }

                DelegateChoice {
                    column: columnIndexOf("stock")

                    Cell {
                        id: _stockCellDelegate
                        required property bool editing

                        Label {
                            text: display

                            anchors.fill: parent
                            leftPadding: 8
                            rightPadding: 30
                            elide: Text.ElideRight
                            horizontalAlignment: colData.textAlignment ? colData.textAlignment : Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            font.family: column !== monoFont.name
                        } // text

                        // TableView.editDelegate: Text {
                        //     text: display
                        // }

                        // TableView.editDelegate: TextField {
                        //     required property var display
                        //     visible: _stockCellDelegate.editing
                        //     anchors.fill: parent

                        //     text: display
                        //     font.family: monoFont.name
                        //     font.pointSize: 16

                        //     validator: IntValidator{}

                        //     TableView.onCommit: {
                        //         root.changeStock(rowData, parseInt(text))
                        //         display = parseInt(text)

                        //         // 'display = text' is short-hand for:
                        //         // let index = TableView.view.index(row, column)
                        //         // TableView.view.model.setData(index, "display", text)

                        //         // rowData.stock = parseInt(display)
                        //         // _tableView.commit()
                        //     }
                        // }
                    }
                }

                DelegateChoice {
                    Cell {
                        Label {
                            text: display

                            anchors.fill: parent
                            leftPadding: 8
                            rightPadding: 30
                            elide: Text.ElideRight

                            horizontalAlignment: colData.textAlignment ? colData.textAlignment : Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            font.family: monoFont.name
                        }

                        // ToolTip.visible: hovered
                        // ToolTip.text: rowData ? JSON.stringify(rowData, null, 2) : ""
                    }
                }
            }
        }

        Row {
            id: rowActionsRow
            anchors.left: _tableView.right
            anchors.leftMargin: 10
            spacing: 8
            visible: currentRow > -1

            y: _tableView.currentRow * 60 + inventoryHeaderView.y + inventoryHeaderView.height + 30 - _tableView.contentY - height / 2

            // property var rowData: tableModel.rows[rowIndex]

            Repeater {
                model: itemTable.actions

                RowActionButton {
                    action: modelData
                }
            }
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
                source: images.check
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

        footer: Pane {
            visible: showTotalFooter
            height: 50
            palette.window: "transparent"
            padding: 0

            Rectangle {
                color: "black"
                width: _tableView.width
                height: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: `${itemTable.rows.length} produit${itemTable.rows.length === 1 ? "":"s"} affiché${itemTable.rows.length === 1 ? "":"s"}`
                anchors.centerIn: parent
                width: _tableView.width
                font.family: monoFont.name
                font.pointSize: 16
            }

            Label {
                text: `Stock total: ${itemTable.rows.reduce((acc, item) => acc + item.stock, 0)}`
                width: _tableView.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: monoFont.name
                font.pointSize: 16
            }
        }
    }
    // ------------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------------

    component Line: Rectangle {
        color: "black"
        opacity: .15

        height: 1
        anchors.left: parent.left
        anchors.right: parent.right
    }

    component Cell: Control {
        id: _theCell
        required property int row
        required property int column
        required property bool selected
        required property bool current

        property var rowData: tableModel.rows[row]
        property var colData: {
            if (!tableModel.columns[column])
                return null
            tableData[tableModel.columns[column].display]
        }
        property bool isCurrent: _theCell.TableView.view && _theCell.row === _theCell.TableView.view.currentRow

        palette.text: isCurrent ? "white" : "black"
        font.bold: isCurrent

        implicitWidth: columnWidth(column)
        //        implicitWidth: childrenRect.width * 1.2
        // implicitWidth: Math.max(_tableView.columnWidth(column), childrenRect.width * 1.2)
        implicitHeight: 60
        clip: true

        onHoveredChanged: {
            if (hovered) {
                // console.log("Hovered cell:", model.modelData, reorderButton)
                // rowActionsRow.y = row * 60 + inventoryHeaderView.height + 15 - _tableView.contentY
                // rowActionsRow.rowIndex = row

                _tableView.selectionModel.setCurrentIndex(tableModel.index(row, column), ItemSelectionModel.Current)
            }
        }

        background: Rectangle {
            color: _theCell.isCurrent ? "#F3F6F6" : "white"
            // color: _theCell.isCurrent? colors.accent : hovered ? "#F3F6F6" : "white"
            // border.color: _theCell.isCurrent ? "black" : "transparent"
            // border.width: 1
        }

        /**
        ToolTip.visible: hovered
        ToolTip.text: colData ? JSON.stringify(colData, null, 2) : ""
//        ToolTip.text: rowData ? JSON.stringify(rowData, null, 2) : ""
        /**/

        Line {
            anchors.bottom: parent.bottom
        }
    }

    component RectangleText: Control {
        id: rectangleText

        property color color: "red"
        property alias radius: _theRectangle.radius
        property alias text: _theText.text

        horizontalPadding: 10
        verticalPadding: 6

        implicitWidth: _theText.implicitWidth + rectangleText.leftPadding + rectangleText.rightPadding
        implicitHeight: _theText.implicitHeight + rectangleText.topPadding + rectangleText.bottomPadding

        Rectangle {
            id: _theRectangle
            anchors.fill: parent
            color: rectangleText.color
            radius: 4
        }

        Text {
            id: _theText
            anchors.fill: parent

            text: qsTr("Rectangle Text")
            color: _.getTextColorForLocationColor(rectangleText.color)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font: rectangleText.font
        }
    }

    component RowActionButton: Button {
        horizontalPadding: 20
        verticalPadding: 8
        font.bold: hovered
        scale: hovered ? 1.1 : 1

        // icon.width: 20; icon.height: 20;

        palette.buttonText: "white"
        background: Rectangle {
            color: colors.accent
            radius: width
        }
    }

    QtObject {
        id: _

        function getColorForLocationName(locationName) {
            if (locationName === "Multiple")
                return "#FF0000" // Red for "Multiple"
            // return "#33FF0000" // Red for "Multiple"

            // Use the first letter of the location name to determine the color
            // using hash
            let hash = 0;
            for (let i = 0; i < 3; i++) {
                //            for (let i = 0; i < 6; i++) {
                hash = (hash << 5) - hash + locationName.charCodeAt(i);
                hash |= 0; // Convert to 32bit integer
            }
            let colorIndex = Math.abs(hash) % pastelColors.length;
            return pastelColors[colorIndex];
        }

        function getTextColorForLocationColor(locationColor) {
            return Qt.darker(locationColor, 3.5)

            // return Qt.hsva(locationColor.hslHue,
            //                1,
            //                locationColor.hsvValue > .5 ? 2 : .5,
            //                1)

            // return Qt.color(Please.make_contrast(Please.RGB_to_HSV({
            //                                                            r: locationColor.r * 255,
            //                                                            g: locationColor.g * 255,
            //                                                            b: locationColor.b * 255
            //                                                        })))

            //            return Qt.color(Please.make_contrast(locationColor))
        }

        function generatePastelColor(){
            return Qt.hsla(
                        Math.random(),
                        1,
                        0.9
                        )
            // return Qt.color(Please.make_color())
        }

        property var pastelColors: {
            let colors = []
            for (let i = 0; i < 1000; i++) {
                colors.push(generatePastelColor())
            }
            return colors
        }

        // property var pastelColors: [
        //     "#FF5733",
        //     "#33FF57",
        //     "#3357FF",
        //     "#FF33A1",
        //     "#A133FF",
        //     "#33FFA1",
        //     "#FFA133",
        //     "#33A1FF",
        //     "#FF33FF",
        //     "#A1FF33",
        //     "#FF33A1",
        //     "#A1A133",
        // ]
    }
}

