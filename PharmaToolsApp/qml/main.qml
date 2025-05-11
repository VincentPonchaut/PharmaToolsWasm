import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import "./components"
import "./fakedata.js" as FakeData

Page {
    id: root
    anchors.fill: parent

    // --------------------------------------------------------------
    // Data
    // --------------------------------------------------------------

    property url baseUrl: "http://localhost:3000"

    QtObject {
        id: database

        property var inventory: []
        property var entrees: []
        property var sorties: []

        property var preconisations: {
            return inventory.filter(item => item.stock < item.min_count)
        }

        property var emplacements: {
            // all unique locations from inventory
            return inventory.map(item => item.locations)
            .reduce((acc, locs) => acc.concat(locs), [])
            .map(loc => loc.location)
            .filter((value, index, self) => self.indexOf(value) === index)
            .sort()
        }

        property var providers: {
            // all unique providers from inventory
            return inventory.map(item => item.provider)
            .filter((value, index, self) => self.indexOf(value) === index)
            .filter(value => value !== "")
            .sort()
        }

        property var providersWithPreconisations: {
            return database.preconisations.map(item => item.provider)
            .filter((value, index, self) => self.indexOf(value) === index)
            .filter(value => value !== "")
            .sort()
        }

        function findByGuid(guid) {
            return database.inventory.find(item => item.guid == guid)
        }
        function quantityAtLocation(guid, location) {
            let item = database.inventory.find(item => item.guid == guid)
            if (item) {
                let loc = item.locations.find(loc => loc.location == location)
                if (loc) {
                    return loc.current_amount
                }
            }
            return 0
        }
    }

    property string errorString: ""

    QtObject {
        id: gui

        property int currentTabIndex: 0
        property real stockModifPercentageShowWarningThreshold: 0.1
        property int peremptionMonthLimitThreshold: 6
        property string username: "CM"

        function shouldShowWarningForDelta(stockBefore, stockAfter) {
            if (stockBefore === 0) {
                return stockAfter > 0
            } else if (stockAfter === 0) {
                return stockBefore > 0
            } else {
                var delta = Math.abs(stockAfter - stockBefore)
                var percentage = delta / stockBefore
                return percentage > gui.stockModifPercentageShowWarningThreshold
            }
        }
    }

    QtObject {
        id: enCours

        property var entrees: [
            {
                "desc": "FLACON VERRE BICARBONATE SODIUM 4,2% 250ML",
                "guid": 321365,
                "locations": [
                    {
                        "current_amount": 0,
                        "initial_amount": 37,
                        "location": "SOL. 17.  1"
                    }
                ],
                "max_count": 20,
                "min_count": 10,
                "provider": "B.BRAUN MEDICAL",
                "qml": 10,
                "ref": "B05414",
                "stock": 37,
                "type": "entree",
                "quantite": 0,
                "location": {
                    "current_amount": 0,
                    "initial_amount": 37,
                    "location": "SOL. 17.  1"
                },
                "UF": "",
                "initiales": "",
                "date": "13/04/2025"
            },
            {
                "desc": "FLACON VERRE BICARBONATE SODIUM 4,2% 250ML",
                "guid": 321365,
                "locations": [
                    {
                        "current_amount": 0,
                        "initial_amount": 37,
                        "location": "SOL. 17.  1"
                    }
                ],
                "max_count": 20,
                "min_count": 10,
                "provider": "B.BRAUN MEDICAL",
                "qml": 10,
                "ref": "B05414",
                "stock": 37,
                "type": "entree",
                "quantite": 0,
                "location": {
                    "current_amount": 0,
                    "initial_amount": 37,
                    "location": "SOL. 17.  1"
                },
                "UF": "",
                "initiales": "",
                "date": "13/04/2025"
            }
        ]
        property var sorties: [
            {
                "desc": "FLACON VERRE BICARBONATE SODIUM 4,2% 250ML",
                "guid": 321365,
                "locations": [
                    {
                        "current_amount": 0,
                        "initial_amount": 37,
                        "location": "SOL. 17.  1"
                    }
                ],
                "max_count": 20,
                "min_count": 10,
                "provider": "B.BRAUN MEDICAL",
                "qml": 10,
                "ref": "B05414",
                "stock": 37,
                "type": "entree",
                "quantite": 0,
                "location": {
                    "current_amount": 0,
                    "initial_amount": 37,
                    "location": "SOL. 17.  1"
                },
                "UF": "",
                "initiales": "",
                "date": "13/04/2025"
            }
        ]
        property var commandes: []
    }

    // --------------------------------------------------------------
    // Logic
    // --------------------------------------------------------------
    // function testURLs() {
    //     // Test all possible resource paths
    //     console.log("Testing path 1:", "qrc:/PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 2:", "qrc:/PharmaToolsApp/inventory.json")
    //     console.log("Testing path 3:", "qrc:/inventory.json")
    //     console.log("Testing path 4:", "qrc:/PharmaToolsApp/1.0/qml/inventory.json")
    //     console.log("Testing path 5:", "qrc:///PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 6:", "qrc:///PharmaToolsApp/inventory.json")
    //     console.log("Testing path 7:", "qrc:///inventory.json")
    //     console.log("Testing path 8:", "file:qml/inventory.json")
    //     console.log("Testing path 9:", "file:inventory.json")
    //     console.log("Testing path 10:", ":PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 11:", ":PharmaToolsApp/inventory.json")
    //     console.log("Testing path 12:", ":inventory.json")
    //     console.log("Testing path 13:", ":/PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 14:", ":/PharmaToolsApp/inventory.json")
    //     console.log("Testing path 15:", ":/inventory.json")
    //     console.log("Testing path 16:", "qrc:/qt/qml/PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 17:", "qrc:/qt/qml/PharmaToolsApp/inventory.json")
    //     console.log("Testing path 18:", "qt.resource.data:/PharmaToolsApp/qml/inventory.json")
    //     console.log("Testing path 19:", "qt.resource.data:/PharmaToolsApp/inventory.json")

    //     // Check resolved URLs for each path
    //     console.log("Resolved URL 1:", Qt.resolvedUrl("qrc:/PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 2:", Qt.resolvedUrl("qrc:/PharmaToolsApp/inventory.json"))
    //     console.log("Resolved URL 3:", Qt.resolvedUrl("qrc:/inventory.json"))
    //     console.log("Resolved URL 4:", Qt.resolvedUrl("qrc:/PharmaToolsApp/1.0/qml/inventory.json"))
    //     console.log("Resolved URL 5:", Qt.resolvedUrl("qrc:///PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 6:", Qt.resolvedUrl("qrc:///PharmaToolsApp/inventory.json"))
    //     console.log("Resolved URL 7:", Qt.resolvedUrl("qrc:///inventory.json"))
    //     console.log("Resolved URL 8:", Qt.resolvedUrl("file:qml/inventory.json"))
    //     console.log("Resolved URL 9:", Qt.resolvedUrl("file:inventory.json"))
    //     console.log("Resolved URL 10:", Qt.resolvedUrl(":PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 11:", Qt.resolvedUrl(":PharmaToolsApp/inventory.json"))
    //     console.log("Resolved URL 12:", Qt.resolvedUrl(":inventory.json"))
    //     console.log("Resolved URL 13:", Qt.resolvedUrl(":/PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 14:", Qt.resolvedUrl(":/PharmaToolsApp/inventory.json"))
    //     console.log("Resolved URL 15:", Qt.resolvedUrl(":/inventory.json"))
    //     console.log("Resolved URL 16:", Qt.resolvedUrl("qrc:/qt/qml/PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 17:", Qt.resolvedUrl("qrc:/qt/qml/PharmaToolsApp/inventory.json"))
    //     console.log("Resolved URL 18:", Qt.resolvedUrl("qt.resource.data:/PharmaToolsApp/qml/inventory.json"))
    //     console.log("Resolved URL 19:", Qt.resolvedUrl("qt.resource.data:/PharmaToolsApp/inventory.json"))

    //     // Test paths that look most promising based on the resolved URLs
    //     testJsonPath(":/PharmaToolsApp/qml/inventory.json");
    //     testJsonPath(":/inventory.json");
    //     testJsonPath("qrc:/PharmaToolsApp/qml/inventory.json");
    //     testJsonPath("qrc:/inventory.json");
    //     testJsonPath("file:qml/inventory.json");
    //     testJsonPath("qrc:/qt/qml/PharmaToolsApp/qml/inventory.json");

    //     // Also try the Module URI format
    //     testJsonPath("PharmaToolsApp/qml/inventory.json");

    //     // Try with a specific prefix that matches your resource file structure
    //     testJsonPath(":/qml/inventory.json");
    // }
    // function testJsonPath(url) {
    //     var xhr = new XMLHttpRequest();
    //     xhr.open("GET", url, true);
    //     xhr.onreadystatechange = function() {
    //         if (xhr.readyState === XMLHttpRequest.DONE) {
    //             if (xhr.status === 200) {
    //                 try {
    //                     var data = JSON.parse(xhr.responseText);
    //                     console.log("SUCCESS loading JSON from:", url);
    //                     console.log("JSON data preview:", JSON.stringify(data).substring(0, 100) + "...");
    //                 } catch (e) {
    //                     console.log("ERROR parsing JSON from:", url, "Error:", e);
    //                 }
    //             } else {
    //                 console.log("FAILED loading JSON from:", url, "Status:", xhr.status);
    //             }
    //         }
    //     };
    //     xhr.send();
    // }

    function onLoggedIn(username) {
        console.log("User logged in:", username)
        gui.username = username
    }
    signal logOutRequested();

    Component.onCompleted: {
        console.log("Component loaded");

        // testURLs()
        // --------------------------------------
        // Inventaire
        // --------------------------------------
        //         var xhr = new XMLHttpRequest()
        //         /**
        //         xhr.open("GET", baseUrl + "/items", true)
        //         /*/
        //        xhr.open("GET", "qrc:/qt/qml/PharmaToolsApp/qml/inventory.json", true)
        // //        xhr.open("GET", "file:///Users/vincent/dev/pharmatools/app/qml/inventory.json", true)
        //         /**/
        //         xhr.send()

        //         // The callback is triggered whenever readyState changes
        //         xhr.onreadystatechange = function() {
        //             // DONE = 4
        //             if (xhr.readyState === XMLHttpRequest.DONE) {
        //                 if (xhr.status === 200) {
        //                     database.inventory = sanitizeInventory(JSON.parse(xhr.responseText))
        //                     console.log("Inventory loaded successfully")
        //                     // console.log("Response text:", xhr.responseText)
        //                 } else {
        //                     root.errorString = "Error loading inventory: " + xhr.statusText
        //                     // console.log("Request error. Status:", xhr.status)
        //                 }
        //             }
        //         }
        database.inventory = sanitizeInventory(FakeData.inventory)

        // --------------------------------------
        // Entrees/Sorties
        // --------------------------------------
        database.sorties = FakeData.sorties
    }

    function sanitizeInventory(inventoryRef) {
        // Iterate over every entry and calculate a new key "stock" that is the sum of the "initialAmount" from the "locations" key array value
        inventoryRef.forEach(item => {
                                 let sum = 0
                                 item.locations.forEach(location => {
                                                            sum += location.amount
                                                        })
                                 item.stock = sum

                                 // Additionally, we are going to add a fake "date_dernier_inventaire"
                                 item.ddi = new Date().toLocaleDateString('fr-FR', {
                                                                              year: 'numeric',
                                                                              month: '2-digit',
                                                                              day: '2-digit'
                                                                          })
                             })
        return inventoryRef
    }

    function changeStock(rowData, newStock) {
        console.assert(rowData.locations.length === 1,
                       ">>>>>>>>>>>> Calling changeStock with multiple locations. You are a worm <<<<<<<<<<<<<<<")
        print("Changing stock for item: " + rowData.desc + " to " + newStock)

        database.inventory.forEach(item => {
                                       if (item.guid === rowData.guid) {
                                           item.locations[0].initial_amount = newStock
                                       }
                                   })
        database.inventory = sanitizeInventory(database.inventory)
    }

    /**
    Text {
        id: _debug
        // text: JSON.stringify(database.emplacements, null, 2)
       text: JSON.stringify(inventory, null, 2)

        anchors.fill: parent
        color: "red"
        font.pointSize: 17
        z: 999

        Rectangle { anchors.fill: parent; color: "black"; z: -1}
    }
    /**/

    function u(url) {
        print("Resolving URL:", url)
        let basePath = "qrc:/qt/qml/PharmaToolsApp/";

        // Run from qml pad
        if (typeof(appIsBundled) == "undefined") {
            basePath = "file:///Users/vincent/dev/pharmatools/app/"
        }

        console.log("Resolved URL:", Qt.resolvedUrl(basePath + url))
        return Qt.resolvedUrl(basePath + url)
    }

    // --------------------------------------------------------------
    // View
    // --------------------------------------------------------------

    QtObject {
        id: colors
        property color accent: "#022326"
        property color lightBackground: "#EFEFEF"
        property color contentLightBackground: "#F5F5F5"
    }

    QtObject {
        id: images
        property url inventory: Qt.resolvedUrl("../icons/ico_inventory.svg")
        property url item: Qt.resolvedUrl("../icons/ico_beaker.svg")
        property url check: Qt.resolvedUrl("../icons/ico_check.svg")
        property url cross: Qt.resolvedUrl("../icons/ico_cross.svg")
        property url printer: Qt.resolvedUrl("../icons/ico_print.svg")
        property url edit_stock: Qt.resolvedUrl("../icons/ico_edit_stock.svg")
        property url filter: Qt.resolvedUrl("../icons/ico_filter.svg")
        property url label: Qt.resolvedUrl("../icons/ico_label.svg")
        property url plus: Qt.resolvedUrl("../icons/ico_plus.svg")
        property url hourglass: Qt.resolvedUrl("../icons/ico_hourglass.svg")
    }

    FontLoader {
        id: headerFont
        source: u("fonts/Montserrat-VariableFont_wght.ttf")
    }
    FontLoader {
        id: monoFont
        source: u("fonts/RobotoMono-VariableFont_wght.ttf")
    }
    FontLoader {
        id: narrowFont
        source: u("fonts/PTSansNarrow-Regular.ttf")
    }

    // Header -------------------------------------------------------
    header: Pane {
        height: 70 + topPadding + bottomPadding
        horizontalPadding: 30
        topPadding: 20
        bottomPadding: 0

        palette.window: "#EFEFEF"
        Rectangle {
            anchors.fill: parent
            color: colors.accent
            // radius: 8
            radius: width
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Item {
                Layout.preferredWidth: 10
            }

            Label {
                text: "PharmaTools"
                color: "white"

                Layout.alignment: Qt.AlignVCenter

                font.family: headerFont.name
                font.pointSize: 30
                font.weight: Font.DemiBold
            }

            Item {
                Layout.preferredWidth: 10
            }

            Repeater {
                model: [
                    {
                        name: "Produit",
                        icon: "../icons/ico_inventory.svg"
                    },
                    {
                        name: "Inventaire",
                        icon: "../icons/ico_inventory.svg"
                    },
                    {
                        name: "Périmés",
                        icon: "../icons/ico_warning.svg"
                    },
                    {
                        name: "Sorties",
                        icon: "../icons/ico_inout.svg"
                    },
                    {
                        name: "Entrées",
                        icon: "../icons/ico_inout.svg"
                    },
                    {
                        name: "Commandes",
                        icon: "../icons/ico_order.svg"
                    },
                    {
                        name: "Réception",
                        icon: "../icons/ico_inout.svg"
                    },
                    {
                        name: "Etiquettes",
                        icon: "../icons/ico_order.svg"
                    },
                ]

                HeaderButton {
                    text: modelData.name
                    checked: gui.currentTabIndex === index

                    icon.source: modelData.icon

                    onClicked: {
                        gui.currentTabIndex = index
                    }

                    Rectangle {
                        id: _commandesBadge
                        visible: modelData.name === "Commande" && enCours.commandes.length > 0

                        x: 10; y: 2; z: 9
                        width: 18
                        height: 18
                        radius: width
                        color: "red"

                        Text {
                            text: enCours.commandes.length
                            color: "white"

                            anchors.centerIn: parent
                            font.family: monoFont.name
                            font.pointSize: 13
                            font.bold: true

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation {
                                        target: _commandesBadge
                                        property: "scale"
                                        to: 1.5;
                                        duration: 600
                                        easing.type: Easing.OutElastic
                                    }
                                    NumberAnimation {
                                        target: _commandesBadge
                                        property: "scale"
                                        to: 1;
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Déconnexion"
                flat: true
                palette.windowText: "white"

                Layout.rightMargin: 30

                font.family: headerFont.name
                font.underline: hovered
                font.pointSize: 12
                font.weight: Font.DemiBold

                onClicked: {
                    root.logOutRequested()
                }
            }
        }
    }
    
    // Content ------------------------------------------------------jkl
    Pane {
        anchors.fill: parent
        horizontalPadding: 40
        // bottomPadding: 20

        background: Rectangle {
            color: "#EFEFEF"
        }

        SwipeView {
            anchors.fill: parent
            currentIndex: gui.currentTabIndex
            interactive: false
            padding: 0
            clip: true

            PageProduit {
            }

            PageInventory {
            }

            // Périmés
            InProgress {}

            // Page Sorties
            PageSorties {
            }

            // Page Entrées
            PageEntrees {
            }

            // Page Commandes
            PagePreconisations {
            }

            // Page Réception
            InProgress {}

            // Page Etiquettes
            InProgress {}

            // PageEntreesSorties {
            // }

            // Pane {
            //     /**
            //     Flow {
            //         anchors.fill: parent
            //         spacing: 20

            //         Repeater {
            //             model: database.emplacements.sort()

            //             ToolButton {
            //                 width: 100
            //                 height: 100
            //                 palette.base: "red"

            //                 text: "" + modelData
            //             }
            //         }
            //     }
            //     /*/
            //     ListView {
            //         id: listView
            //         anchors.fill: parent
            //         model: database.emplacements.sort()

            //         delegate: ItemDelegate {
            //             text: "" + modelData
            //             width: parent.width
            //         }
            //     }

            //     // Row {
            //     //     id: _roroFightThePower
            //     //     anchors.fill: parent
            //     //     spacing: 10

            //     //     property var uniqueFirstFields: {
            //     //         return database.emplacements.map(item => String(item).substring(0,3))
            //     //         .filter((value, index, self) => self.indexOf(value) === index)
            //     //     }
            //     //     property var uniqueSecondFields: {
            //     //         return database.emplacements.map(item => String(item).substring(3,6))
            //     //         .filter((value, index, self) => self.indexOf(value) === index)
            //     //     }
            //     //     property var uniqueThirdFields: {
            //     //         return database.emplacements.map(item => String(item).substring(6,9))
            //     //         .filter((value, index, self) => self.indexOf(value) === index)
            //     //     }
            //     //     property var uniqueFourthFields: {
            //     //         return database.emplacements.map(item => String(item).substring(9,12))
            //     //         .filter((value, index, self) => self.indexOf(value) === index)
            //     //     }

            //     //     Repeater {
            //     //         model: [
            //     //             _roroFightThePower.uniqueFirstFields,
            //     //             _roroFightThePower.uniqueSecondFields,
            //     //             _roroFightThePower.uniqueThirdFields,
            //     //             _roroFightThePower.uniqueFourthFields
            //     //         ]
            //     //         ComboBox {
            //     //             editable: true
            //     //             currentIndex: 0
            //     //             model: modelData
            //     //         }
            //     //     }
            //     // } // Row

            //     // Text {
            //     //     text: JSON.stringify(database.emplacements.map(item => String(item).substring(0,3)), null, 2)
            //     //     font.family: monoFont.name
            //     // }
            //     /**/
            // }

            // Rectangle {
            //     color: "blue"
            // }
        }
    }

    // Footer -------------------------------------------------------
    // footer: Pane {
    //     // height: 200
    //     palette.window: "#3d3d3d"
    // }

    // --------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------

    ButtonGroup {
        id: buttonGroup
    }
    component HeaderButton: Button {
        id: headerButton
        checkable: true
        horizontalPadding: 20
        verticalPadding: 10

        background: Rectangle {
            visible: headerButton.checked
            color: "#EFEFEF"
            radius: width
        }

        text: qsTr("Header Button")
        font.family: headerFont.name
        font.pointSize: 18
        font.weight: headerButton.checked ? Font.DemiBold
                                          : Font.Normal
        palette.buttonText: "white"
        palette.brightText: "black"

        ButtonGroup.group: buttonGroup
    }

    component InProgress: Pane {
        Label {
            text: "En construction..."
            anchors.centerIn: parent
            font.family: monoFont.name
            font.pointSize: 30
            color: "red"
        }
    }

    QtObject {
        id: jsExtensions

        Component.onCompleted: {
            // Polyfill for String.prototype.padStart
            if (!String.prototype.padStart) {
                String.prototype.padStart = function(targetLength, padString) {
                    targetLength = targetLength >> 0;
                    padString = String(padString !== undefined ? padString : ' ');
                    if (this.length >= targetLength) {
                        return String(this);
                    }
                    let padLen = targetLength - this.length;
                    while (padString.length < padLen) {
                        padString += padString;
                    }
                    return padString.slice(0, padLen) + String(this);
                };
            }

            // Polyfill for String.prototype.padEnd
            if (!String.prototype.padEnd) {
                String.prototype.padEnd = function(targetLength, padString) {
                    targetLength = targetLength >> 0;
                    padString = String(padString !== undefined ? padString : ' ');
                    if (this.length >= targetLength) {
                        return String(this);
                    }
                    let padLen = targetLength - this.length;
                    while (padString.length < padLen) {
                        padString += padString;
                    }
                    return String(this) + padString.slice(0, padLen);
                };
            }

            // Array.flat
            if (!Array.prototype.flat) {
                Array.prototype.flat = function(depth) {
                    let arr = this;
                    depth = depth || 1;
                    return arr.reduce((acc, val) => {
                                          if (Array.isArray(val) && depth > 0) {
                                              return acc.concat(val.flat(depth - 1));
                                          } else {
                                              return acc.concat(val);
                                          }
                                      }, []);
                };
            }
        }
    }

    // Utility object for file operations
    QtObject {
        id: fileUtils

        function openFile(fileUrl) {
            var request = new XMLHttpRequest();
            request.open("GET", fileUrl, false);
            request.send(null);
            return request.responseText;
        }

        function saveFile(fileUrl, text) {
            var request = new XMLHttpRequest();
            request.open("PUT", fileUrl, false);
            request.send(text);
            return request.status;
        }
    }
}
