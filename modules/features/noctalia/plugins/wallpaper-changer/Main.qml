// Shared state for the bar widget and the panel: one MsgClient talking to
// the change-wallpaper daemon, plus the last known filter/wallpaper. Lives
// as the plugin's `main` entry point so both UI pieces see the same data
// (and a change triggered from the bar refreshes the open panel).
import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property string exe: pluginApi?.pluginSettings?.exe || "change-wallpaper"
    readonly property string socketPath: pluginApi?.pluginSettings?.socketPath || ""
    readonly property bool notifyOnChange: pluginApi?.pluginSettings?.notifyOnChange ?? true

    // Daemon-reported state.
    property string filter: ""
    property string current: ""
    property var collections: []
    property bool collectionsLoaded: false

    readonly property bool busy: client.busy
    readonly property bool daemonReachable: client.daemonReachable
    readonly property string lastError: client.lastError

    // Basename of the current wallpaper, for compact display.
    readonly property string currentName: {
        if (current === "")
            return "";
        var parts = current.split("/");
        return parts[parts.length - 1];
    }

    // Deliberately not named "changed"/"collectionsChanged": QML reserves
    // <property>Changed for every declared property, and a hand-declared
    // signal with that name is rejected at load time.
    signal wallpaperApplied
    signal collectionsRefreshed

    MsgClient {
        id: client
        exe: root.exe
        socketPath: root.socketPath
    }

    Component.onCompleted: refresh()

    // Re-read filter + current wallpaper from the daemon.
    function refresh() {
        client.status(function (ok, data) {
            if (!ok || !data)
                return;
            root.filter = data.filter || "";
            root.current = data.current || "";
        });
    }

    // Ask the daemon for its collection list (directories holding images).
    // Cheap for a local root, one GitHub API call otherwise, so it is only
    // fetched when the panel asks for it.
    function loadCollections(force) {
        if (collectionsLoaded && !force)
            return;
        client.listCollections(function (ok, data, error) {
            if (!ok || !data) {
                root.notifyError(error);
                return;
            }
            root.collections = data.collections || [];
            root.filter = data.filter || "";
            root.collectionsLoaded = true;
            root.collectionsRefreshed();
        });
    }

    // Change the wallpaper now. The daemon only replies once the new
    // wallpaper is applied, so ok/error here is the real outcome.
    function changeNow() {
        client.trigger(function (ok, data, error) {
            if (!ok) {
                root.notifyError(error);
                return;
            }
            root.current = (data && data.current) || root.current;
            if (root.notifyOnChange)
                ToastService.showNotice(root.tr("toast.changed", "Wallpaper changed"), root.currentName, "wallpaper");
            root.wallpaperApplied();
        });
    }

    // Restrict picks to one collection ("" = any), then change immediately so
    // the result is visible.
    function selectCollection(value) {
        client.setFilter(value, function (ok, data, error) {
            if (!ok) {
                root.notifyError(error);
                return;
            }
            root.filter = (data && data.filter) || "";
            root.changeNow();
        });
    }

    function notifyError(error) {
        ToastService.showError(root.tr("toast.failed", "Wallpaper change failed"), error || root.lastError, 6000);
    }

    function tr(key, fallback) {
        var t = pluginApi?.tr ? pluginApi.tr(key) : "";
        // A missing key comes back as `!!key!!` (PluginService.api.tr), which
        // must not be shown to the user — fall back to the English literal.
        if (!t || (t.indexOf("!!") === 0 && t.lastIndexOf("!!") === t.length - 2))
            return fallback;
        return t;
    }
}
