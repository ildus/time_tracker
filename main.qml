import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

ApplicationWindow {
    title: "Time Tracker"
    width: 640
    height: 480

    MenuBar {
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

        Label {
            text: "No activity"
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }

        Button {
            text: "Stop tracking"
            enabled: false
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
            Layout.minimumWidth: 300
            focus: true
            placeholderText: "Activity"
        }

        TextField  {
            placeholderText: "Tags"
            Layout.fillWidth: true
        }

        Button {
            text: "Start tracking"
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
           ListElement{ start: "11:00" ; activity: "Counters"; time: "1h 23m"}
           ListElement{ start: "13:00" ; activity: "Something important"; time: "1h 23m"}
           ListElement{ start: "22:00" ; activity: "Analytics"; time: "1h 23m"}
        }

        TableView {
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