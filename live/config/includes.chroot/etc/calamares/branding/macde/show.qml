import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 18000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: hero
            source: "welcome.svg"
            width: 500; height: 300
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: hero.horizontalCenter
            anchors.top: hero.bottom
            width: 620
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.Center
            text: qsTr("MacDE installs Debian 12 with GNOME tuned for Intel MacBook 2011-2012.<br/>The live desktop is ready and the installed system keeps the same UX profile.")
        }
    }

    Slide {
        Column {
            anchors.centerIn: parent
            width: 620
            spacing: 12

            Text {
                width: parent.width
                text: qsTr("What is ready in this live image")
                font.pixelSize: 28
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Top bar, bottom dock, fonts, wallpaper, and a clean GNOME profile are preconfigured.")
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("The image also includes Broadcom Wi-Fi support, Intel microcode, TLP and mbpfan for the target MacBook.")
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("When installation finishes, Calamares removes the live-only installer packages from the target system.")
            }
        }
    }
}
