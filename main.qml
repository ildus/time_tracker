import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2

ApplicationWindow {
    title: "Time Tracker"
    width: 640
    height: 480

    property var activityStarted: false
    property var currentActivity: ""
    property var duration: ""
    property var tags: []
    property var lastDayText: ""

    Window {
        id: dropdown
        title: "Editing"
        visible: false
        width: 400
        height: 300
        Label {
            text: "Some text"
        }
    }

    menuBar: MenuBar {
        Menu {
            title: "Tracking"
            MenuItem { text: "Preferences" }
            MenuItem { text: "Close" }
        }
    }

    RowLayout {
        id: row1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 5
        height: 60

        Item {
            visible: activityStarted
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: 40

            Label {
                anchors.top: parent.top
                id: lblCurrentActivity
                text: currentActivity
                font.pixelSize: 22
                font.bold: true
            }

            Label {
                anchors.top: lblCurrentActivity.bottom
                anchors.left: parent.left
                font.pixelSize: 12
                font.bold: true
                text: duration
            }

            Item {
                anchors.left: lblCurrentActivity.right
                anchors.leftMargin: 10

                RowLayout {
                    id: rowTags
                }
            }

        }

        Label {
            visible: !activityStarted
            text: "No activity"
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
        }

        Button {
            id: btnStopTracking
            text: "Stop tracking"
            enabled: activityStarted
            onClicked: {
                ctrl.stopActivity()
                txtActivity.focus = true
            }
            Layout.alignment: Qt.AlignRight
        }
    }

    RowLayout {
        id: row2
        anchors.top: row1.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 5

        TextField  {
            id: txtActivity
            Layout.minimumWidth: 300
            focus: true
            placeholderText: "Activity"
        }

        TextField  {
            id: txtTags
            placeholderText: "Tags"
            Layout.fillWidth: true
        }

        Button {
            id: btnStartTracking
            text: "Start tracking"
            enabled: !activityStarted
            onClicked: {
                ctrl.newActivity(txtActivity.text, txtTags.text)
                txtActivity.text = ""
                txtTags.text = ""
            }
        }
    }

    RowLayout {
        id: row3
        anchors.top: row2.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        anchors {topMargin: 20}
        spacing: 5

        Label {
            text: "Latest activities"
            font.bold: true
        }
    }

    RowLayout {
        id: row4
        anchors.top: row3.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: row5.top
        anchors.margins: 10
        spacing: 5

        TableView {
            TableViewColumn{ role: "day"  ; title: "Day" ; width: 100}
            TableViewColumn{ role: "start"  ; title: "Start" ; width: 100 }
            TableViewColumn{ role: "activity" ; title: "Activity" ; width: 300 }
            TableViewColumn{
                role: "time" ;
                title: "Time" ;
            }

            headerVisible: false
            model: ctrl.activitiesLen

            Menu {
                id: contextMenu
                MenuItem {
                    text: "Edit"
                    onTriggered: {
                        dropdown.visible = true;
                    }
                }
                MenuItem {
                    text: "Delete"
                }
            }
            itemDelegate: Item {
                anchors.margins: 10
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onClicked: {
                        contextMenu.popup()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#300006"
                    text: {
                        var row = styleData.row, col = styleData.column;
                        if (col == 2) {
                            return ctrl.activity(row).name
                        } else if (col == 3) {
                            return ctrl.activity(row).duration
                        } else if (col == 0) {
                            return ctrl.activity(row).dayName
                        } else if (col == 1) {
                            return ctrl.activity(row).timePeriod
                        }
                        return ""
                    }
                    Component.onCompleted: {
                        lastDayText = "";
                    }
                }
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    RowLayout {
        id: row5
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 5

        Label {
            text: "No records today"
        }

        Button {
            text: "Add earlier activity"
            Layout.alignment: Qt.AlignRight
            anchors.right: btnOverview.left
        }

        Button {
            id: btnOverview
            text: "Show overview"
            Layout.alignment: Qt.AlignRight
        }
    }
}