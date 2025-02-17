/****************************************************************************
 **
 ** QPrompt
 ** Copyright (C) 2020-2022 Javier O. Cordero Pérez
 **
 ** This file is part of QPrompt.
 **
 ** This program is free software: you can redistribute it and/or modify
 ** it under the terms of the GNU General Public License as published by
 ** the Free Software Foundation, version 3 of the License.
 **
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 **
 ** You should have received a copy of the GNU General Public License
 ** along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **
 ****************************************************************************/

import QtQuick 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
//import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1 as Labs
import Qt.labs.settings 1.0

import com.cuperino.qprompt.document 1.0
import com.cuperino.qprompt.qmlutil 1.0

Kirigami.ApplicationWindow {
    id: root
    property bool __fullScreen: false
    property bool __autoFullScreen: false
    // The following line includes macOS among the list of platforms where full screen buttons are hidden. This is done intentionally because macOS provides its own full screen buttons on the window frame and global menu. We shall not mess with what users of each platform expect.
    property bool fullScreenPlatform: Kirigami.Settings.isMobile || ['android', 'ios', 'wasm', 'tvos', 'qnx', 'ipados', 'osx'].indexOf(Qt.platform.os)!==-1
    //readonly property bool __translucidBackground: !Material.background.a // === 0
    //readonly property bool __translucidBackground: !Kirigami.Theme.backgroundColor.a && ['ios', 'wasm', 'tvos', 'qnx', 'ipados'].indexOf(Qt.platform.os)===-1
    property bool __translucidBackground: true
    readonly property bool __isMobile: Kirigami.Settings.isMobile
    readonly property bool themeIsMaterial: Kirigami.Settings.style==="Material" // || Kirigami.Settings.isMobile
    // mobileOrSmallScreen helps determine when to follow mobile behaviors from desktop non-mobile devices
    readonly property bool mobileOrSmallScreen: Kirigami.Settings.isMobile || root.width < 1220
    //readonly property bool __translucidBackground: false
    // Scrolling settings
    property bool __scrollAsDial: false
    property bool __invertArrowKeys: false
    property bool __invertScrollDirection: false
    property bool __noScroll: false
    property bool __telemetry: true
    property bool forceQtTextRenderer: false
    property bool passiveNotifications: true
    property bool __throttleWheel: true
    property int __wheelThrottleFactor: 8
    //property int prompterVisibility: Kirigami.ApplicationWindow.Maximized
    property double __opacity: 1
    property int __iDefault: 3
    property int onDiscard: Prompter.CloseActions.Ignore
    property bool ee: false
    property bool theforce: false

    title: root.pageStack.currentItem.document.fileName + (root.pageStack.currentItem.document.modified?"*":"") + " - " + aboutData.displayName
    width: 1220  // Set at 1220 to show all functionality at a glance. Set to 1200 to fit both 1280 4:3 and 1200 height monitors. Keep at or bellow 1024 and at or above 960, for best usability with common 4:3 resolutions
    height: 728  // Keep and test at 728 so that it works well with 1366x768 screens.
    // Making width and height start maximized
    //width: screen.desktopAvailableWidth
    //height: screen.desktopAvailableHeight
    minimumWidth: Kirigami.Settings.isMobile ? 291 : 351 // 338
    minimumHeight: minimumWidth

    Settings {
        category: "mainWindow"
        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height
    }
    Settings {
        category: "scroll"
        property alias noScroll: root.__noScroll
        property alias scrollAsDial: root.__scrollAsDial
        property alias invertScrollDirection: root.__invertScrollDirection
        property alias invertArrowKeys: root.__invertArrowKeys
        property alias throttleWheel: root.__throttleWheel
        property alias wheelThrottleFactor: root.__wheelThrottleFactor
    }
    Settings {
        category: "editor"
        property alias forceQtTextRenderer: root.forceQtTextRenderer
    }
    Settings {
        category: "prompter"
        property alias stepsDefault: root.__iDefault
    }
    Settings {
        category: "background"
        property alias opacity: root.__opacity
        property alias transparency: root.__translucidBackground
    }
    Settings {
        category: "telemetry"
        property alias enabled: root.__telemetry
    }

    //// Theme management
    //Material.theme: themeSwitch.checked ? Material.Dark : Material.Light  // This is correct, but it isn't work working, likely because of Kirigami

    // Make backgrounds transparent
    //Material.background: "transparent"
    color: root.__translucidBackground ? "transparent" : "initial"
    // More ways to enforce transparency across systems
    //visible: true
    readonly property int hideDecorators: root.pageStack.currentItem.overlay.atTop && !root.pageStack.currentItem.viewport.forcedOrientation && parseInt(root.pageStack.currentItem.prompter.state)!==Prompter.States.Editing || Qt.platform.os==="osx" && root.pageStack.currentItem.prompterBackground.opacity!==1 ? Qt.FramelessWindowHint : Qt.Window
    flags: hideDecorators

    background: Rectangle {
        id: appTheme
        color: __backgroundColor
        opacity: root.pageStack.layers.depth > 1 || (!root.__translucidBackground || root.pageStack.currentItem.prompterBackground.opacity===1)
        //readonly property color __fontColor: parent.Material.theme===Material.Light ? "#212121" : "#fff"
        //readonly property color __iconColor: parent.Material.theme===Material.Light ? "#232629" : "#c3c7d1"
        //readonly property color __backgroundColor: __translucidBackground ? (parent.Material.theme===Material.Dark ? "#303030" : "#fafafa") : Kirigami.Theme.backgroundColor
        //readonly property color __backgroundColor: __translucidBackground ? (themeSwitch.checked ? "#303030" : "#fafafa") : Kirigami.Theme.backgroundColor
        property int selection: 0
        //readonly property color __backgroundColor: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 1)
        property color __backgroundColor: switch(appTheme.selection) {
            case 0: return Qt.rgba(Kirigami.Theme.backgroundColor.r/4, Kirigami.Theme.backgroundColor.g/4, Kirigami.Theme.backgroundColor.b/4, 1);
            case 1: return "#303030";
            case 2: return "#FAFAFA";
        }
    }

    // Full screen
    visibility: __fullScreen ? Kirigami.ApplicationWindow.FullScreen : (!__autoFullScreen ? Kirigami.ApplicationWindow.AutomaticVisibility : (parseInt(root.pageStack.currentItem.prompter.state)===Prompter.States.Editing ? Kirigami.ApplicationWindow.Maximized : Kirigami.ApplicationWindow.FullScreen))

    onWidthChanged: {
        root.pageStack.currentItem.footer.paragraphSpacingSlider.update()
    }

    // Open save dialog on closing
    onClosing: {
        root.onDiscard = Prompter.CloseActions.Quit
        if (root.pageStack.currentItem.document.modified) {
            closeDialog.open()
            close.accepted = false
        }
    }

    function loadAboutPage() {
        root.pageStack.layers.clear()
        root.pageStack.layers.push(aboutPageComponent, {aboutData: aboutData})
    }
    function loadRemoteControlPage() {
        root.pageStack.layers.clear()
        root.pageStack.layers.push(remoteControlPageComponent, {})
    }
    function loadTelemetryPage() {
        root.pageStack.layers.clear()
        root.pageStack.layers.push(telemetryPageComponent)
    }

    // Left Global Drawer
    globalDrawer: Kirigami.GlobalDrawer {
        id: globalMenu

        property int bannerCounter: 0
        // isMenu: true
        title: aboutData.displayName
        titleIcon: ["android"].indexOf(Qt.platform.os)===-1 ? "qrc:/images/qprompt.png" : "qrc:/images/qprompt-logo-wireframe.png"
        bannerVisible: true
        onBannerClicked: {
            bannerCounter++;
            // Enable easter eggs.
            if (!(bannerCounter%10))
                ee = true
        }
        actions: [
            Kirigami.Action {
                text: i18nc("Main menu and global menu actions", "&New")
                iconName: "document-new"
                shortcut: StandardKey.New
                onTriggered: root.pageStack.currentItem.document.newDocument()
            },
            Kirigami.Action {
                text: i18nc("Main menu and global menu actions", "&Open")
                iconName: "document-open"
                shortcut: StandardKey.Open
                onTriggered: {
                    root.onDiscard = Prompter.CloseActions.Open
                    root.pageStack.currentItem.document.open()
                }
            },
            Kirigami.Action {
                text: i18nc("Main menu and global menu actions", "&Save")
                iconName: "document-save"
                shortcut: StandardKey.Save
                onTriggered: {
                    root.onDiscard = Prompter.CloseActions.Ignore
                    root.pageStack.currentItem.document.saveDialog()
                }
            },
            Kirigami.Action {
                text: i18nc("Main menu and global menu actions", "Save &As")
                iconName: "document-save-as"
                shortcut: StandardKey.SaveAs
                onTriggered: {
                    root.onDiscard = Prompter.CloseActions.Ignore
                    root.pageStack.currentItem.document.saveAsDialog()
                }
            },
            Kirigami.Action {
                visible: false
                text: i18nc("Main menu actions", "&Recent Files")
                iconName: "document-open-recent"
                //Kirigami.Action {
                    //text: i18n("View Action 1")
                    //onTriggered: showPassiveNotification(i18n("View Action 1 clicked"))
                //}
            },
            Kirigami.Action {
                text: i18nc("Main menu actions. Menu regarding input settings.", "&Controls Settings")
                iconName: "transform-browse" // "hand"
                Kirigami.Action {
                    visible: ["android", "ios", "tvos", "ipados", "qnx"].indexOf(Qt.platform.os)===-1
                    text: i18nc("Main menu and global menu actions. Opens dialog to configure keyboard inputs.", "Keyboard Inputs")
                    iconName: "key-enter" // "keyboard"
                    onTriggered: {
                        root.pageStack.currentItem.keyConfigurationOverlay.open()
                    }
                }
                Kirigami.Action {
                    visible: ["android", "ios", "tvos", "ipados", "qnx"].indexOf(Qt.platform.os)===-1
                    text: i18nc("Open 'scroll settings' from main menu and global menu actions", "Scroll throttle settings")
                    iconName: "gnumeric-object-scrollbar" // "keyboard"
                    onTriggered: wheelSettings.open()
                }
                Kirigami.Action {
                    text: i18nc("Main menu and global menu actions. Have up arrow behave like down arrow and vice versa while prompting.", "Invert &arrow keys")
                    enabled: !root.__noScroll
                    iconName: "circular-arrow-shape"
                    checkable: true
                    checked: root.__invertArrowKeys
                    onTriggered: root.__invertArrowKeys = !root.__invertArrowKeys
                }
                Kirigami.Action {
                    text: i18nc("Main menu and global menu actions. Invert scroll direction while prompting.", "Invert &scroll direction")
                    enabled: !root.__noScroll
                    iconName: "gnumeric-object-scrollbar"
                    checkable: true
                    checked: root.__invertScrollDirection
                    onTriggered: root.__invertScrollDirection = !root.__invertScrollDirection
                }
                Kirigami.Action {
                    text: i18nc("Main menu and global menu actions. Have touchpad and mouse wheel scrolling adjust velocity instead of scrolling like most other apps.", "Use scroll as velocity &dial")
                    enabled: !root.__noScroll
                    iconName: "filename-bpm-amarok"
                    // ToolTip.text: i18n("Use mouse and touchpad scroll as speed dial while prompting")
                    checkable: true
                    checked: root.__scrollAsDial
                    onTriggered: root.__scrollAsDial = !root.__scrollAsDial
                }
                Kirigami.Action {
                    text: i18nc("Main menu and global menu actions. Touchpad scrolling and mouse wheel use have no effect while prompting.", "Disable scrolling while prompting")
                    iconName: "paint-none"
                    checkable: true
                    checked: root.__noScroll
                    onTriggered: root.__noScroll = !root.__noScroll
                }
            },
            Kirigami.Action {
                text: i18nc("Main menu actions", "Other &Settings")
                iconName: "configure"
//                 Kirigami.Action {
//                     text: i18n("Telemetry")
//                     iconName: "document-send"
//                     onTriggered: {
//                         root.loadTelemetryPage()
//                     }
//                 }
                Kirigami.Action {
                    id: hideFormattingToolsAlwaysSetting
                    text: i18nc("Main menu actions", "Always hide formatting tools")
                    iconName: "newline"
                    checkable: true
                    checked: root.pageStack.currentItem.footer.hideFormattingToolsAlways
                    onTriggered: root.pageStack.currentItem.footer.hideFormattingToolsAlways = !root.pageStack.currentItem.footer.hideFormattingToolsAlways
                }
                Kirigami.Action {
                    id: hideFormattingToolsWhilePromptingSetting
                    enabled: !hideFormattingToolsAlwaysSetting.checked
                    text: i18nc("Main menu actions. Hides formatting tools while not in edit mode.", "Auto hide formatting tools")
                    iconName: "list-remove"
                    checkable: true
                    checked: root.pageStack.currentItem.footer.hideFormattingToolsWhilePrompting
                    onTriggered: root.pageStack.currentItem.footer.hideFormattingToolsWhilePrompting = !root.pageStack.currentItem.footer.hideFormattingToolsWhilePrompting
                }
                Kirigami.Action {
                    id: enableOverlayContrastSetting
                    text: i18nc("Main menu actions. Disables contrast effect for the reading region overlay.", "Disable overlay contrast")
                    //iconName: "edit-opacity"
                    iconSource: "qrc:/icons/edit-opacity.svg"
                    checkable: true
                    checked: root.pageStack.currentItem.overlay.disableOverlayContrast
                    onTriggered: root.pageStack.currentItem.overlay.disableOverlayContrast = !root.pageStack.currentItem.overlay.disableOverlayContrast
                }
                Kirigami.Action {
                    id: transparencySetting
                    property bool dirty: false
                    visible: ["android", "ios", "tvos", "ipados", "qnx"].indexOf(Qt.platform.os)===-1
                    text: i18n("Disable background transparency")
                    //iconName: "contrast"
                    iconSource: "qrc:/icons/contrast.svg"
                    checkable: true
                    checked: !root.__translucidBackground
                    onTriggered: {
                        root.__translucidBackground = !root.__translucidBackground;
                        if (!transparencySetting.dirty) {
                            transparencySetting.dirty = true;
                            restartDialog.visible = true;
                        }
                    }
                }
                Kirigami.Action {
                    id: subpixelSetting
                    text: i18nc("Main menu actions. QPrompt switches between two text rendering techniques when the base font size exceeds 120px. Enabling this option forces QPrompt to always use the default renderer, which features smoother sub-pixel animations.", "Force sub-pixel text renderer past 120px")
                    // Hiding option because only Qt text renderer is used on devices of greater pixel density, due to bug in rendering native fonts while scaling is enabled.
                    visible: ['android', 'ios', 'wasm', 'tvos', 'qnx', 'ipados'].indexOf(Qt.platform.os)===-1 && screen.devicePixelRatio === 1.0
                    iconName: "format-font-size-more"
                    checkable: true
                    checked: root.forceQtTextRenderer
                    onTriggered: root.forceQtTextRenderer = !root.forceQtTextRenderer
                }
//                 Kirigami.Action {
//                     text: i18nc("Main menu actions", "Restore factory defaults")
//                     iconName: "edit-clear-history"
//                     onTriggered: {
//                         showPassiveNotification(i18n("Feature not yet implemented"))
//                     }
//                 }
            },
            Kirigami.Action {
                text: i18nc("Main menu actions. Load about page.", "Abou&t %1", aboutData.displayName)
                iconName: "help-about"
                onTriggered: loadAboutPage()
            },
            Kirigami.Action {
                visible: !Kirigami.Settings.isMobile
                text: i18nc("Main menu and global menu actions", "&Quit")
                iconName: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: close()
            },
            // Global shortcuts
            // On ESC pressed, return to PrompterEdit mode.
            Kirigami.Action {
                visible: false
                onTriggered: {
                    // Close all sub pages
                    if (root.pageStack.layers.depth > 1) {
                        root.pageStack.layers.clear();
                        root.pageStack.currentItem.prompter.restoreFocus()
                    }
                    // Close open drawers
                    else if (root.pageStack.currentItem.markersDrawer.drawerOpen)
                        root.pageStack.currentItem.markersDrawer.toggle()
                    // Close open overlay sheets
                    else if (root.pageStack.currentItem.countdownConfiguration.sheetOpen)
                        root.pageStack.currentItem.countdownConfiguration.close()
                    else if (root.pageStack.currentItem.keyConfigurationOverlay.sheetOpen)
                        root.pageStack.currentItem.keyConfigurationOverlay.close()
                    else if (root.pageStack.currentItem.namedMarkerConfiguration.sheetOpen)
                        root.pageStack.currentItem.namedMarkerConfiguration.close()
                    else if (wheelSettings.sheetOpen)
                        wheelSettings.close()
                    // Close find, compare against enabled instead of isOpen to prevent closing find while it is invisible.
                    else if (root.pageStack.currentItem.find.enabled)
                        root.pageStack.currentItem.find.close()
                    // If editing while prompting, return focus to prompter, thus leaving edit while prompting mode.
                    else if (parseInt(root.pageStack.currentItem.prompter.state)===Prompter.States.Prompting && root.pageStack.currentItem.editor.focus)
                        root.pageStack.currentItem.prompter.focus = true;
                    // Return to edit mode if prompter is in focus
                    else if (root.pageStack.currentItem.prompter.focus)
                        root.pageStack.currentItem.prompter.cancel()
                    // In any other situation, restore focus to the prompter
                    else
                       root.pageStack.currentItem.prompter.restoreFocus()
                }
                shortcut: StandardKey.Cancel
            },
            Kirigami.Action {
                visible: false
                onTriggered: root.__fullScreen = !root.__fullScreen
                shortcut: StandardKey.FullScreen
            }
        ]
        topContent: RowLayout {
            Button {
                text: i18nc("Main menu and global actions. Load document that welcomes users.", "Load &Welcome")
                flat: true
                onClicked: {
                    root.pageStack.currentItem.document.loadGuide()
                    globalMenu.close()
                }
            }
            // Button {
            //     text: i18nc("Main menu and global actions.", "Remote")
            //     flat: true
            //     onClicked: {
            //         root.pageStack.layers.push(remoteControlPageComponent, {})
            //         globalMenu.close()
            //     }
            // }
            // Button {
            //     id: themeSwitch
            //     text: i18nc("Main menu and global actions.", "Dark &Mode")
            //     flat: true
            //     onClicked: {
            //         appTheme.selection = (appTheme.selection + 1) % 3;
            //         const bg = Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 1);
            //         console.log(bg);
            //         // If the system theme is active, and its background is either black or the exact same as that of either the material light o dark theme's, skip the system theme.
            //         if (appTheme.selection===0 && (Qt.colorEqual(bg, "#000000") || Qt.colorEqual(bg, "#FAFAFA") || Qt.colorEqual(bg, "#303030")))
            //             appTheme.selection = (appTheme.selection + 1) % 3
            //         showPassiveNotification(i18n("Feature not fully implemented"))
            //     }
            // }
        }
        content: [
            Button {
                visible: {
                    const date = new Date();
                    return ee || date.getMonth()===4 && date.getDate()===4
                }
                text: i18n("Darth mode")
                flat: true
                checkable: true
                checked: root.theforce
                onClicked: {
                    root.theforce = !root.theforce
                    globalMenu.close()
                }
            }
        ]
        WheelSettingsOverlay{
            id: wheelSettings
        }
    }

    // Right Context Drawer
    contextDrawer: Kirigami.ContextDrawer {
        id: contextDrawer
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel)=>root.pageStack.currentItem.viewport.mouse.wheel(wheel)
        }
    }
    MouseArea {
        height: 40
        anchors.left: parent.left
        anchors.right: parent.right
        acceptedButtons: Qt.NoButton
        onWheel: (wheel)=>root.pageStack.currentItem.viewport.mouse.wheel(wheel)
    }

    // Top bar foreground hack for window dragging
    WindowDragger {
        anchors {
            top: parent.top;
            left: parent.left;
        }
        window: root
        height: 40
        width: 120
        enabled: !Kirigami.Settings.isMobile && pageStack.globalToolBar.actualStyle !== Kirigami.ApplicationHeaderStyle.None
        onClicked: {
            root.pageStack.layers.clear();
        }
    }

    // Kirigami PageStack and PageRow
    pageStack.globalToolBar.toolbarActionAlignment: Qt.AlignHCenter
    pageStack.initialPage: prompterPageComponent
    // Auto hide global toolbar on fullscreen
    pageStack.globalToolBar.style: Kirigami.Settings.isMobile ? (root.pageStack.layers.depth > 1 ? Kirigami.ApplicationHeaderStyle.Titles : Kirigami.ApplicationHeaderStyle.None) : (parseInt(root.pageStack.currentItem.prompter.state)!==Prompter.States.Editing && (visibility===Kirigami.ApplicationWindow.FullScreen || root.pageStack.currentItem.overlay.atTop) ? Kirigami.ApplicationHeaderStyle.None : Kirigami.ApplicationHeaderStyle.ToolBar)

    // The following is not possible in the current version of Kirigami, but it should be:
    //pageStack.globalToolBar.background: Rectangle {
        //color: appTheme.__backgroundColor
    //}
    //property alias root.pageStack.currentItem: root.pageStack.currentItem
    //property alias root.pageStack.currentItem: root.pageStack.layers.currentItem
    // End of Kirigami PageStack configuration

    // Patch current page's events to outside its scope.
    //Connections {
        //target: pageStack.currentItem
        ////onTest: {  // Old syntax, use to support 5.12 and lower.
        //function onTest(data) {
            //console.log("Connection successful, received:", data)
        //}
    //}

    /*Binding {
        //target: pageStack.layers.item
        //target: pageStack.initialPage
        //target: pageStack.layers.currentItem
        //target: prompter
        property: "italic"
        value: root.italic
    }*/

    onFrameSwapped: {
        // Thus runs from here because there's no event that occurs on each bit of scroll, and this takes much less CPU than a timer, is more precise and scales better.
        root.pageStack.currentItem.prompter.markerCompare()
        // Update Projections
        if (projectionManager.isEnabled && root.visible/* && projectionManager.model.count*/)
            // Recount projections on each for loop iteration to prevent value from going stale because a window was closed from a different thread.
            for (var i=0; i<projectionManager.projections.count; i++) {
                const w = projectionManager.projections.objectAt(i)
                if (w!==null)
                    w.update();
                else
                    break;
            }
    }

    ProjectionsManager {
        id: projectionManager
        backgroundColor: root.pageStack.currentItem.prompterBackground.color
        backgroundOpacity: root.pageStack.currentItem.prompterBackground.opacity
        // Forward to prompter and not editor to prevent editing from projection windows
        forwardTo: root.pageStack.currentItem.viewport
    }

    // Prompter Page Component {
    Component {
        id: prompterPageComponent
        PrompterPage {}
    }

    // Page Components
    Component {
        id: aboutPageComponent
        AboutPage {}
    }
    Component {
        id: remoteControlPageComponent
        RemotePage {}
    }
    Component {
        id: telemetryPageComponent
        TelemetryPage {}
    }

    // Dialogues
    Labs.MessageDialog {
        id: restartDialog
        title: i18nc("Restart application_name", "Restart %1", aboutData.displayName)
        text: i18nc("application needs to restart for this change to fully take effect.\n\nWould you like to restart application now? All changes to document will be lost.", "%1 needs to restart for this change to fully take effect.\n\nWould you like to restart %1 now? All changes to document will be lost.", aboutData.displayName)
        buttons: Labs.MessageDialog.Yes | Labs.MessageDialog.No
        onYesClicked: {
            qmlutil.restartApplication()
        }
    }

    Labs.MessageDialog {
        id : closeDialog
        title: i18nc("Title for save before closing dialog", "Save Document")
        text: i18n("Save changes to document before closing?")
        //icon: StandardIcon.Question
        buttons: (Labs.MessageDialog.Save | Labs.MessageDialog.Discard | Labs.MessageDialog.Cancel)
        //standardButtons: StandardButton.Save | StandardButton.Discard | StandardButton.Cancel
        onDiscardClicked: {
        // onDiscard: {
            //switch (parseInt(root.onDiscard)) {
                //case Prompter.CloseActions.LoadGuide: root.pageStack.currentItem.document.loadGuide(); break;
                //case Prompter.CloseActions.LoadNew: root.pageStack.currentItem.document.newDocument(); break;
                //case Prompter.CloseActions.Quit: Qt.quit();
                ////case Prompter.CloseActions.Quit:
                ////default: Qt.quit();
            //}

            //document.saveAs(saveDialog.fileUrl)
            //root.pageStack.currentItem.document.isNewFile = true
            switch (parseInt(root.onDiscard)) {
                case Prompter.CloseActions.LoadGuide:
                    root.pageStack.currentItem.document.modified = false
                    root.pageStack.currentItem.document.loadGuide();
                    break;
                case Prompter.CloseActions.LoadNew:
                    root.pageStack.currentItem.document.modified = false
                    root.pageStack.currentItem.document.newDocument();
                    break;
                case Prompter.CloseActions.Open:
                    root.pageStack.currentItem.openDialog.open();
                    break;
                case Prompter.CloseActions.Quit: Qt.quit();
                    break;
                case Prompter.CloseActions.Ignore:
                default: break;
            }
        }
        //onSaveClicked: root.pageStack.currentItem.document.saveDialog(true)
        onAccepted:
        {
            root.pageStack.currentItem.document.saveDialog(parseInt(root.onDiscard)===Prompter.CloseActions.Quit)
        }
    }
    QmlUtil {
        id: qmlutil
    }
}
