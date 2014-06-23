import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Window 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtGraphicalEffects 1.0

Rectangle {
    z: 2
    id: baseItem
    property var value: null
    property var valueFormatted: null
    property string placeholder: ""
    property string defaultFormat: "dd.MM.yyyy hh:mm"

    onValueChanged: {
        valueFormatted = Qt.formatDateTime(value, defaultFormat)
    }

    function setValue(dt) {
        if (dt) {
            value = dt
            txt.text = Qt.formatDateTime(value, defaultFormat)
            datePicker.selectedDate = dt
        } else {
            value = null
            txt.text = ""
        }
    }

    SystemPalette { id: palette; colorGroup: SystemPalette.Active }

    Component.onCompleted: {
        parent.z = 1
    }

    TextField {
        id: txt
        placeholderText: placeholder
        width: 200
        //inputMask: "09.09.9999 09:09"
        property var locale: Qt.locale()

        onTextChanged: {
            var dt = Date.fromLocaleString(locale, text, "d.M.yyyy h:m")
            if (isNaN(dt.getTime())) {
                textColor = "red"
                baseItem.value = null
            }
            else {
                textColor = palette.windowText
                baseItem.value = dt
                datePicker.selectedDate = dt
            }
        }

        Rectangle {
            id: txtBtn
            width: 20
            anchors.margins: 2
            anchors.top: txt.top
            anchors.right: txt.right
            height: txt.height - 4
            //border.width: 1
            //border.color: "gray"
            radius: 1

            Image {
                anchors.margins: 4
                anchors.fill: parent;
                source: "../images/calendar.png"
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    block.visible = !block.visible
                }
            }
        }
    }

    Rectangle {
        id: block
        visible: false
        anchors.top: txt.bottom
        anchors.left: txt.left
        anchors.right: txt.right
        height: 200

        border {
            width: 1;
            color: Qt.rgba(0, 0, 0, 0.2);
        }

        Calendar {
            id: datePicker
            anchors.margins: 4
            anchors.fill: parent

            onClicked: {
                value = selectedDate
                block.visible = false
                txt.text = Qt.formatDateTime(value, defaultFormat)
            }

            style: CalendarStyle {
                gridVisible: false
                gridColor: "white"
                navigationBar: Item {
                    height: 25

                    Button {
                        id: previousMonth
                        width: parent.height - 2
                        height: width
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: (parent.height - height) / 2
                        iconSource: "../images/arrow-left.png"
                        onClicked: control.showPreviousMonth()
                    }
                    Label {
                        id: dateText
                        text: styleData.title
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: previousMonth.right
                        anchors.leftMargin: 2
                        anchors.right: nextMonth.left
                        anchors.rightMargin: 2
                    }
                    Button {
                        id: nextMonth
                        width: parent.height - 2
                        height: width
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: (parent.height - height) / 2
                        iconSource: "../images/arrow-right.png"

                        onClicked: control.showNextMonth()
                    }
                }

                dayDelegate: Rectangle {
                    color: styleData.date !== undefined && styleData.selected ? selectedDateColor : "white"/*"transparent"*/
                    readonly property color sameMonthDateTextColor: "black"
                    readonly property color selectedDateColor: __syspal.highlight
                    readonly property color selectedDateTextColor: "white"
                    readonly property color differentMonthDateTextColor: Qt.darker("darkgrey", 1.4);
                    readonly property color invalidDateColor: "#dddddd"

                    Label {
                        font.pixelSize: 12
                        id: dayDelegateText
                        text: styleData.date.getDate()
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignRight
                        color: {
                            var theColor = invalidDateColor;
                            if (styleData.valid) {
                                // Date is within the valid range.
                                theColor = styleData.visibleMonth ? sameMonthDateTextColor : differentMonthDateTextColor;
                                if (styleData.selected)
                                    theColor = selectedDateTextColor;
                            }
                            theColor;
                        }
                    }
                }
            }
        }

        // Button {
        //     id: btnSelector
        //     x: 0
        //     //anchors.bottom: parent.bottom
        //     width: parent.width
        //     state: "DATE"

        //     onClicked: {
        //         state == "DATE"? state = "TIME" : state = "DATE"
        //     }

        //     states: [
        //         State {
        //             name: "DATE"
        //             PropertyChanges { target: imgSelector; source: "../images/calendar.png"}
        //             PropertyChanges { target: datePicker; visible: true}
        //             PropertyChanges { target: block; height: 230}
        //             AnchorChanges { target: btnSelector; anchors.bottom: parent.bottom}
        //         },
        //         State {
        //             name: "TIME"
        //             PropertyChanges { target: imgSelector; source: "../images/time.png"}
        //             PropertyChanges { target: datePicker; visible: false}
        //             PropertyChanges { target: block; height: 160}
        //             AnchorChanges { target: btnSelector; anchors.top: parent.top}
        //         }
        //     ]

        //     Image {
        //         id: imgSelector
        //         anchors.centerIn: parent;
        //         source: "../images/time.png"
        //         smooth: true
        //         width: 12
        //         height: 12
        //     }
        // }
    }
}