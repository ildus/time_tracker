import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

ApplicationWindow {
    title: "Time Tracker"
    width: 640
    height: 480

    property var activityStarted: false
    property var currentActivity: ""
    property var duration: ""
    property var tags: []

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

        ListModel {
           id: taskModel
           ListElement{ day: "Today"; start: "11:00" ; activity: "Counters (mf #1231)"; time: "1h 23m"}
           ListElement{ start: "13:00" ; activity: "Something important"; time: "1h 23m"}
           ListElement{ start: "22:00" ; activity: "Analytics"; time: "1h 23m"}

           ListElement{ day: "Yesterday"; start: "09:00" ; activity: "Work work work"; time: "1h 23m"}
           ListElement{ start: "15:00" ; activity: "Surfing"; time: "1h 23m"}

           ListElement{ day: "15 Feb 2014"; start: "09:00" ; activity: "Pets"; time: "1h 23m"}
           ListElement{ start: "15:00" ; activity: "Surfing"; time: "1h 23m"}
        }

        TableView {
            TableViewColumn{ role: "day"  ; title: "Day" ; width: 100}
            TableViewColumn{ role: "start"  ; title: "Start" ; width: 100 }
            TableViewColumn{ role: "activity" ; title: "Activity" ; width: 300 }
            TableViewColumn{
                role: "time" ;
                title: "Time" ;
            }
            headerVisible: false
            model: taskModel

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