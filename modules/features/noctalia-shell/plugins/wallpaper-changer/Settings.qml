// Plugin settings pane (opened from the bar widget's context menu).
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    // Settings.qml is loaded standalone by NPluginSettingsPopup (no
    // mainInstance), so it needs its own copy of the missing-key guard: a key
    // with no translation comes back as `!!key!!`, which is truthy and would
    // defeat a plain `|| fallback`.
    function tr(key, fallback) {
        var t = pluginApi?.tr ? pluginApi.tr(key) : "";
        if (!t || (t.indexOf("!!") === 0 && t.lastIndexOf("!!") === t.length - 2))
            return fallback;
        return t;
    }

    property string editExe: pluginApi?.pluginSettings?.exe || defaults.exe || "change-wallpaper"
    property string editSocketPath: pluginApi?.pluginSettings?.socketPath ?? defaults.socketPath ?? ""
    property bool editNotifyOnChange: pluginApi?.pluginSettings?.notifyOnChange ?? defaults.notifyOnChange ?? true

    spacing: Style.marginM

    NText {
        text: root.tr("settings.title", "Wallpaper Changer")
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
    }

    NText {
        Layout.fillWidth: true
        text: root.tr("settings.description", "Controls the change-wallpaper daemon over its Unix socket. The daemon is started by the compositor; these paths only need changing if it was started differently.")
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeXS
        wrapMode: Text.Wrap
    }

    NDivider {
        Layout.fillWidth: true
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("settings.exe", "change-wallpaper binary")
        description: root.tr("settings.exe-description", "Name on $PATH, or an absolute path.")
        text: root.editExe
        placeholderText: "change-wallpaper"
        defaultValue: root.defaults.exe
        onTextChanged: root.editExe = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("settings.socket", "Socket path")
        description: root.tr("settings.socket-description", "Empty uses $WALLPAPER_SOCKET or $XDG_RUNTIME_DIR/change-wallpaper.sock.")
        text: root.editSocketPath
        placeholderText: "(default)"
        defaultValue: root.defaults.socketPath
        onTextChanged: root.editSocketPath = text
    }

    NToggle {
        Layout.fillWidth: true
        label: root.tr("settings.notify", "Notify on change")
        description: root.tr("settings.notify-description", "Show a toast with the new wallpaper's name.")
        checked: root.editNotifyOnChange
        defaultValue: root.defaults.notifyOnChange
        onToggled: checked => root.editNotifyOnChange = checked
    }

    // Called by NPluginSettingsPopup's save button.
    function saveSettings() {
        if (!pluginApi)
            return;
        pluginApi.pluginSettings.exe = root.editExe.trim() || "change-wallpaper";
        pluginApi.pluginSettings.socketPath = root.editSocketPath.trim();
        pluginApi.pluginSettings.notifyOnChange = root.editNotifyOnChange;
        pluginApi.saveSettings();
    }
}
