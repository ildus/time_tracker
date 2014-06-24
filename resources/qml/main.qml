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
    property int tagsCount: 0
    property var lastDayText: ""
    property var todayText: "No records today"

    property var activityIndex: null
    property var activityName: ""
    property var activityTags: ""
    property var activityStart: ""
    property var activityEnd: ""
    property var activityDescription: ""
    property var locale: Qt.locale()

    function showDropdown() {
        if (activityStart)
            dt1.setValue(Date.fromLocaleString(locale, activityStart, "d.M.yyyy h:m"))
        else
            dt1.setValue(null);

        if (activityEnd)
            dt2.setValue(Date.fromLocaleString(locale, activityEnd, "d.M.yyyy h:m"))
        else
            dt2.setValue(null);

        dropdown.visible = true
    }

    Window {
        id: dropdown
        title: "Editing"
        visible: false
        modality: Qt.WindowModal
        height: 270
        width: 450

        SequentialAnimation {
            id: shaking
            running: false
            property var target: null
            NumberAnimation { target: shaking.target; property: "x"; to: target.x - 5; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x + 5; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x - 3; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x + 3; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x - 1; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x + 1; duration: 50}
            NumberAnimation { target: shaking.target; property: "x"; to: target.x; duration: 50}

            function shake(obj) {
                shaking.target = obj
                shaking.start()
            }
        }

        RowLayout {
            id: wrow1
            height: 15
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 5

            TextField  {
                id: txtActivityName
                Layout.minimumWidth: 300
                focus: true
                placeholderText: "Activity"
                text: activityName
            }

            TextField  {
                id: txtActivityTags
                placeholderText: "Tags"
                Layout.fillWidth: true
                text: activityTags
            }
        }

        RowLayout {
            id: wrow2
            height: 15
            anchors.top: wrow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 5

            Datetimepicker {
                id: dt1
                placeholder: "Start"
                //width: 200
                Layout.preferredWidth: 200
                //anchors.left: parent.left
            }

            Datetimepicker {
                id: dt2
                placeholder: "End"
                Layout.preferredWidth: 200
                Layout.alignment: Qt.AlignRight
            }
        }

        Label {
            anchors.topMargin: 30
            anchors.leftMargin: 10
            anchors.left: parent.left
            anchors.top: wrow2.bottom
            id: lblDescription
            text: "Description"
        }

        RowLayout {
            id: wrow3
            anchors.top: lblDescription.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: wrow4.top
            anchors.margins: 10
            anchors.topMargin: 5
            spacing: 5

            TextArea {
                id: txtDescription
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: activityDescription
            }
        }

        RowLayout {
            id: wrow4
            height: 20
            anchors.margins: 10
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            Button {
                text: "Remove"
                onClicked: {
                    ctrl.removeActivity(activityIndex)
                    dropdown.visible = false
                }
                Layout.alignment: Qt.AlignLeft
            }

            Button {
                anchors.right: btnClose.left
                isDefault: true
                text: "Save activity"
                onClicked: {
                    if (!dt1.value) {
                        shaking.shake(dt1)
                        return
                    }
                    if (!dt2.value) {
                        shaking.shake(dt2)
                        return
                    }
                    if (!txtActivityName.text) {
                        shaking.shake(txtActivityName)
                        return
                    }

                    if (dt2.value <= dt1.value) {
                        shaking.shake(dt1)
                        return
                    }

                    ctrl.saveEditedActivity(activityIndex,
                                            txtActivityName.text,
                                            txtActivityTags.text,
                                            txtDescription.text,
                                            dt1.valueFormatted,
                                            dt2.valueFormatted)
                    dropdown.visible = false
                }
                Layout.alignment: Qt.AlignRight
            }

            Button {
                id: btnClose
                text: "Close"
                onClicked: dropdown.visible = false
                Layout.alignment: Qt.AlignRight
            }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: dropdown.visible = false
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
                anchors.right: parent.right
                anchors.leftMargin: 10

                ListModel {
                    id: tags
                }

                ListView {
                    width: parent.width

                    model: tagsCount
                    orientation: ListView.Horizontal
                    delegate: Label {
                        text: ctrl.getTag(model.index) + ' '
                        color: Qt.rgba(255, 0, 0, 0.8)
                    }
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
                if (txtActivity.text.length) {
                    ctrl.newActivity(txtActivity.text, txtTags.text)
                    txtActivity.text = ""
                    txtTags.text = ""
                }
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
            Layout.fillWidth: true
            Layout.fillHeight: true

            TableViewColumn{ role: "day"  ; title: "Day" ; width: 80}
            TableViewColumn{ role: "start"  ; title: "Start" ; width: 100 }
            TableViewColumn{ role: "activity" ; title: "Activity" ; width: row4.width - 325 }
            TableViewColumn{ role: "time" ; title: "Time"; width: 120}
            TableViewColumn{
                width: 20
                role: "actions"
                title: "Actions"
                delegate: Item {
                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "../images/edit.png"
                        smooth: true

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ctrl.editActivity(styleData.row)
                            }
                        }
                    }
                }
            }

            headerVisible: false
            model: ctrl.activitiesLen

            SystemPalette { id: palette; colorGroup: SystemPalette.Active }

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

            onDoubleClicked: {
                ctrl.copyActivity(row)
            }

            itemDelegate: Item {
                anchors.margins: 10
                anchors.fill: parent

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
            text: todayText
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