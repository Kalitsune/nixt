// Panel entry point, rebuilt around the daemon's actual capabilities:
//   - current wallpaper + active collection at a glance
//   - "Change now", with real success/failure feedback
//   - the collection list fetched from the daemon, pick one to filter
// No free-text filter field: the daemon can enumerate collections, so an
// invalid value cannot be typed in by hand any more.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    // SmartPanel contract
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property var main: pluginApi?.mainInstance
    readonly property bool ready: main !== null && main !== undefined

    readonly property var collections: main?.collections ?? []
    readonly property string activeFilter: main?.filter ?? ""
    readonly property bool daemonDown: ready ? !main.daemonReachable : false

    // "Any collection" plus one row per collection.
    readonly property var rows: {
        var out = [{
                "label": tr("panel.any-collection", "Any collection"),
                "value": "",
                "icon": "dice"
            }];
        for (var i = 0; i < collections.length; i++) {
            out.push({
                "label": collections[i],
                "value": collections[i],
                "icon": "folder"
            });
        }
        return out;
    }

    property real contentPreferredWidth: 360 * Style.uiScaleRatio
    property real contentPreferredHeight: Math.min(460, 190 + rows.length * 34) * Style.uiScaleRatio

    anchors.fill: parent

    function tr(key, fallback) {
        return ready ? main.tr(key, fallback) : fallback;
    }

    // Collections are only fetched while the panel is open (a GitHub-backed
    // root costs an API call), and refreshed on each open so a repo push
    // shows up without restarting the shell.
    Component.onCompleted: {
        if (ready) {
            main.refresh();
            main.loadCollections(true);
        }
    }

    Item {
        id: panelContainer
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // ---- header: icon, title, current wallpaper ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                    icon: root.daemonDown ? "wallpaper-off" : "wallpaper"
                    pointSize: Style.fontSizeXL
                    color: root.daemonDown ? Color.mError : Color.mPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    NText {
                        text: root.tr("panel.title", "Wallpaper")
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                    }

                    NText {
                        Layout.fillWidth: true
                        text: {
                            if (root.daemonDown)
                                return root.tr("panel.daemon-down", "Daemon not running");
                            var name = root.main?.currentName ?? "";
                            return name === "" ? root.tr("panel.no-wallpaper", "No wallpaper set yet") : name;
                        }
                        pointSize: Style.fontSizeXS
                        color: root.daemonDown ? Color.mError : Color.mOnSurfaceVariant
                        elide: Text.ElideMiddle
                    }
                }

                NBusyIndicator {
                    running: root.main?.busy ?? false
                    visible: running
                    size: Style.baseWidgetSize * 0.6
                }
            }

            NButton {
                Layout.fillWidth: true
                text: root.tr("actions.change-now", "Change wallpaper now")
                icon: "dice"
                enabled: root.ready && !root.main.busy && !root.daemonDown
                onClicked: root.main.changeNow()
            }

            NDivider {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                    Layout.fillWidth: true
                    text: root.tr("panel.collections", "Collections")
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurfaceVariant
                }

                NIconButton {
                    icon: "refresh"
                    baseSize: Style.baseWidgetSize * 0.7
                    tooltipText: root.tr("actions.reload", "Reload collections")
                    enabled: root.ready && !root.main.busy
                    onClicked: root.main.loadCollections(true)
                }
            }

            // ---- collection picker ----
            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty list means either "still loading" or "source
                // unreachable"; both are explained rather than shown blank.
                NText {
                    anchors.centerIn: parent
                    width: parent.width - Style.marginM * 2
                    visible: root.collections.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    text: {
                        if (root.daemonDown)
                            return root.tr("panel.daemon-down-hint", "Start the wallpaper daemon to pick a collection.");
                        if (root.main?.busy ?? false)
                            return root.tr("panel.loading", "Loading collections…");
                        if ((root.main?.lastError ?? "") !== "")
                            return root.main.lastError;
                        return root.tr("panel.no-collections", "No collections found.");
                    }
                }

                NListView {
                    anchors.fill: parent
                    anchors.margins: Style.marginXS
                    visible: root.collections.length > 0
                    spacing: Style.marginXXS
                    model: root.rows

                    delegate: Rectangle {
                        required property var modelData

                        width: ListView.view.width
                        height: Math.round(30 * Style.uiScaleRatio)
                        radius: Style.radiusS
                        readonly property bool selected: modelData.value === root.activeFilter
                        color: {
                            if (selected)
                                return Qt.alpha(Color.mPrimary, 0.18);
                            return rowMouse.containsMouse ? Color.mHover : "transparent";
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.marginS
                            anchors.rightMargin: Style.marginS
                            spacing: Style.marginS

                            NIcon {
                                icon: modelData.icon
                                pointSize: Style.fontSizeS
                                color: selected ? Color.mPrimary : Color.mOnSurfaceVariant
                            }

                            NText {
                                Layout.fillWidth: true
                                text: modelData.label
                                pointSize: Style.fontSizeXS
                                color: rowMouse.containsMouse && !selected ? Color.mOnHover : Color.mOnSurface
                                elide: Text.ElideMiddle
                            }

                            NIcon {
                                icon: "check"
                                pointSize: Style.fontSizeS
                                color: Color.mPrimary
                                visible: selected
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Picking a collection also applies a wallpaper
                            // from it right away, so the click has a visible
                            // result instead of only arming the next tick.
                            onClicked: root.main.selectCollection(modelData.value)
                        }
                    }
                }
            }
        }
    }
}
