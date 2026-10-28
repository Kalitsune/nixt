// Bar entry point: a capsule button showing wallpaper state.
// Left click opens the panel, right click offers the quick actions.
import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    // Plugin API (injected by PluginService)
    property var pluginApi: null

    // Required properties for bar widgets
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var main: pluginApi?.mainInstance
    readonly property bool daemonDown: main ? !main.daemonReachable : false

    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: daemonDown ? Color.mError : Color.mPrimary
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    tooltipDirection: BarService.getTooltipDirection(screen?.name)

    // "wallpaper-off" doubles as the error state: the daemon is not running,
    // so nothing can be changed until niri respawns it.
    icon: daemonDown ? "wallpaper-off" : "wallpaper"
    opacity: (main?.busy ?? false) ? 0.6 : 1.0

    tooltipText: {
        if (daemonDown)
            return main ? main.tr("tooltip.daemon-down", "Wallpaper daemon is not running") : "";
        if (main?.busy ?? false)
            return main.tr("tooltip.changing", "Changing wallpaper…");
        var name = main?.currentName ?? "";
        var filter = main?.filter ?? "";
        if (name === "")
            return main ? main.tr("tooltip.idle", "Wallpaper") : "";
        return filter === "" ? name : filter + " · " + name;
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": main ? main.tr("actions.change-now", "Change wallpaper now") : "Change wallpaper now",
                "action": "change-now",
                "icon": "dice",
                "enabled": !(main?.busy ?? false)
            },
            {
                "label": main ? main.tr("actions.plugin-settings", "Plugin settings") : "Plugin settings",
                "action": "plugin-settings",
                "icon": "settings"
            },
        ]

        onTriggered: action => {
                         contextMenu.close();
                         PanelService.closeContextMenu(screen);

                         if (action === "change-now") {
                             if (main)
                                 main.changeNow();
                         } else if (action === "plugin-settings") {
                             BarService.openPluginSettings(screen, pluginApi.manifest);
                         }
                     }
    }

    onClicked: {
        if (pluginApi)
            pluginApi.togglePanel(root.screen, root);
    }

    onRightClicked: PanelService.showContextMenu(contextMenu, root, screen)
}
