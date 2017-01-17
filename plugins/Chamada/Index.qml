import QtQuick 2.7
import QtQuick.Controls 2.0

import "../../qml/components/"

Page {
    id: page
    title: qsTr("Courses in progress")

    property var json: {}
    property var configJson: {}

    function request() {
        jsonListModel.source += "section_time_in_progress/" + userProfileData.id
        jsonListModel.load()
    }

    Component.onCompleted: request();

    Connections {
        target: window
        onPageChanged: if (currentPage.title === page.title) request();
    }

    Connections {
        target: jsonListModel
        onStateChanged: {
            if (jsonListModel.state === "ready" && currentPage.title === page.title) {
                var jsonTemp = jsonListModel.model.get(0);
                json = jsonTemp;
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        visible: jsonListModel.state === "loading"
    }

    Column {
        visible: !busyIndicator.visible
        spacing: 25
        anchors { top: parent.top; topMargin: 15; horizontalCenter: parent.horizontalCenter }

        Column {
            spacing: 5
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                font { pointSize: 14; weight: Font.DemiBold }
                text: json !== undefined ? (json.course_section.course.code + " - " + json.course_section.course.name) : ""
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                font { pointSize: 12; weight: Font.DemiBold }
                text: json !== undefined ? (json.section_time_start_time + " - " + json.section_time_finish_time) : ""
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Column {
            spacing: 5

            Label {
                text: {
                    if (jsonListModel.state === "running")
                        qsTr("Checkin for courses in progress...")
                    else if (json)
                        qsTr("Do you want register attendance?")
                    else
                        qsTr("None courses in progress!")
                }
                anchors.horizontalCenter: parent.horizontalCenter
                font { pointSize: 16; weight: Font.Bold }
            }

            CustomButton {
                enabled: json !== undefined && jsonListModel.state !== "running"
                text: qsTr("Student attendance")
                textColor: appSettings.theme.colorAccent
                backgroundColor: appSettings.theme.colorPrimary
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    var attendanceDate = new Date().toDateString();
                    pushPage(configJson.root_folder+"/RealizarChamada.qml", {"attendanceDate":attendanceDate,"lesson_time_id": json.id, "classes_id": json.course_section.id});
                }
            }
        }
    }

    CustomButton {
        enabled: jsonListModel.state !== "running"
        text: qsTr("My courses")
        textColor: appSettings.theme.colorAccent
        backgroundColor: appSettings.theme.colorPrimary
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 15 }
        onClicked: pushPage(configJson.root_folder+"/TurmasDoProfessor.qml", {})
    }
}
