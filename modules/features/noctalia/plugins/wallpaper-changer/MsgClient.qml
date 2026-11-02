// Talks to the change-wallpaper daemon by shelling out to
// `change-wallpaper --msg '<json>'` instead of opening the Unix socket
// directly. The CLI prints one JSON line on stdout; transport failures
// (daemon not running) are reported on stderr with a non-zero exit.
//
// Requests are queued: one Process is reused, so a panel can ask for
// status + collections at once without losing a reply.
import QtQuick
import Quickshell.Io

Item {
    id: root

    // change-wallpaper binary; resolved on $PATH unless an absolute path is
    // given via plugin settings.
    property string exe: "change-wallpaper"
    // Optional explicit socket path; empty lets the CLI use its default
    // ($WALLPAPER_SOCKET or $XDG_RUNTIME_DIR/change-wallpaper.sock).
    property string socketPath: ""

    // Queued or running requests, drives spinners.
    readonly property bool busy: _pending > 0
    // False once a request could not reach the daemon at all (not running).
    // Distinct from a command that the daemon answered with ok:false.
    property bool daemonReachable: true
    // Human readable text of the last failure, "" after a success.
    property string lastError: ""

    // Emitted for every finished request, successful or not.
    signal replied(string cmd, bool ok, var data, string error)

    property int _pending: 0
    property var _queue: []
    property string _cmd: ""
    property var _callback: null
    property bool _exited: false
    property bool _streamDone: false
    property int _exitCode: 0

    Process {
        id: proc
        stdout: StdioCollector {
            id: outCollector
            onStreamFinished: {
                root._streamDone = true;
                root._maybeFinish();
            }
        }
        stderr: StdioCollector {
            id: errCollector
        }
        onExited: code => {
            root._exitCode = code;
            root._exited = true;
            root._maybeFinish();
        }
    }

    // Enqueue one command. callback (optional) gets (ok, data, error).
    function request(cmd, value, callback) {
        var req = {
            cmd: cmd
        };
        if (value !== undefined && value !== null)
            req.value = value;
        _queue.push({
            "cmd": cmd,
            "payload": JSON.stringify(req),
            "callback": callback || null
        });
        _pending = _pending + 1;
        _pump();
    }

    function trigger(callback) {
        request("trigger", undefined, callback);
    }

    function status(callback) {
        request("status", undefined, callback);
    }

    function listCollections(callback) {
        request("list_collections", undefined, callback);
    }

    function setFilter(value, callback) {
        request("set_filter", value, callback);
    }

    function _pump() {
        if (proc.running || _queue.length === 0)
            return;
        var next = _queue.shift();
        _cmd = next.cmd;
        _callback = next.callback;
        _exited = false;
        _streamDone = false;
        _exitCode = 0;

        var argv = [root.exe];
        if (root.socketPath !== "")
            argv.push("--socket=" + root.socketPath);
        argv.push("--msg=" + next.payload);
        proc.command = argv;
        proc.running = true;
    }

    // Both the stdout stream and the process itself must be done before the
    // reply can be read: the two signals can arrive in either order.
    function _maybeFinish() {
        if (!_exited || !_streamDone)
            return;

        var cmd = _cmd;
        var callback = _callback;
        _cmd = "";
        _callback = null;
        _pending = Math.max(0, _pending - 1);

        var ok = false;
        var data = null;
        var error = "";

        // The CLI prints its log lines before the reply, so only the last
        // non-empty line is JSON.
        var lines = (outCollector.text || "").trim().split("\n");
        var line = lines.length > 0 ? lines[lines.length - 1].trim() : "";

        if (line !== "") {
            try {
                data = JSON.parse(line);
                ok = data.ok === true;
                error = ok ? "" : (data.error || "command failed");
                // A parsed reply means the daemon answered, even if it says no.
                root.daemonReachable = true;
            } catch (e) {
                error = "unreadable reply: " + line;
            }
        } else {
            // No reply at all: the daemon is not listening on the socket.
            root.daemonReachable = false;
            var stderrText = (errCollector.text || "").trim();
            error = stderrText !== "" ? stderrText.split("\n").pop() : "wallpaper daemon is not running";
        }

        if (!ok && _exitCode === 0 && error === "")
            error = "command failed";

        root.lastError = ok ? "" : error;
        if (callback)
            callback(ok, data, error);
        root.replied(cmd, ok, data, error);

        _pump();
    }
}
