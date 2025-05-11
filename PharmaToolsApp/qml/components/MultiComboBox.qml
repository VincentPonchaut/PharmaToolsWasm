import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Material

ComboBox {
    id: comboBox

    property var selectedIndexes: []

    palette.window: "white"

    // ComboBox closes the popup when its items (anything AbstractButton derivative) are
    //  activated. Wrapping the delegate into a plain Item prevents that.
    delegate: Item {
        width: parent.width
        height: checkDelegate.height

        function toggle() { checkDelegate.toggle() }

        CheckDelegate {
            id: checkDelegate
            anchors.fill: parent

            text: model[comboBox.textRole]
            highlighted: comboBox.highlightedIndex == index

            checked: selectedIndexes.indexOf(index) !== -1
            onCheckedChanged: {
                if (checked) {
                    if (selectedIndexes.indexOf(index) === -1)
                        selectedIndexes.push(index)
                }
                else {
                    var idx = selectedIndexes.indexOf(index)
                    if (idx !== -1) {
                        selectedIndexes.splice(idx, 1)
                    }
                }
                comboBox.selectedIndexesChanged()
            }
        }
    }

    // override space key handling to toggle items when the popup is visible
    Keys.onSpacePressed: {
        if (comboBox.popup.visible) {
            var currentItem = comboBox.popup.contentItem.currentItem
            if (currentItem) {
                currentItem.toggle()
                event.accepted = true
            }
        }
    }

    Keys.onReleased: {
        if (comboBox.popup.visible)
            event.accepted = (event.key === Qt.Key_Space)
    }
}

