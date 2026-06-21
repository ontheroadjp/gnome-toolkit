import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Keyboard from 'resource:///org/gnome/shell/ui/status/keyboard.js';

const DBUS_IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.FocusUsInput">
    <method name="SwitchToUs"/>
  </interface>
</node>`;

const TERMINAL_IDENTIFIERS = [
    'alacritty',
    'com.mitchellh.ghostty',
    'com.system76.cosmicterm',
    'foot',
    'gnome-terminal',
    'kitty',
    'konsole',
    'org.gnome.console',
    'org.gnome.terminal',
    'org.gnome.ptyxis',
    'terminator',
    'wezterm',
    'xterm',
];

function windowIdentifiers(window) {
    return [
        window.get_wm_class(),
        window.get_wm_class_instance(),
        window.get_gtk_application_id(),
    ]
        .filter(identifier => identifier !== null)
        .map(identifier => identifier.toLowerCase());
}

function isTerminal(window) {
    return windowIdentifiers(window).some(identifier =>
        TERMINAL_IDENTIFIERS.some(terminal => identifier === terminal)
    );
}

export default class FocusUsInputExtension extends Extension {
    enable() {
        this._inputSourceManager = Keyboard.getInputSourceManager();
        this._focusChangedId = global.display.connect(
            'notify::focus-window',
            () => this._scheduleSwitch()
        );
        this._idleId = 0;
        this._scheduleSwitch();

        this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(DBUS_IFACE, this);
        this._dbusImpl.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/FocusUsInput');
        this._ownerId = Gio.bus_own_name_on_connection(
            Gio.DBus.session,
            'org.gnome.Shell.Extensions.FocusUsInput',
            Gio.BusNameOwnerFlags.NONE,
            () => {},
            () => {}
        );
    }

    disable() {
        if (this._ownerId) {
            Gio.bus_unown_name(this._ownerId);
            this._ownerId = 0;
        }
        if (this._dbusImpl) {
            this._dbusImpl.unexport();
            this._dbusImpl = null;
        }
        if (this._focusChangedId) {
            global.display.disconnect(this._focusChangedId);
            this._focusChangedId = 0;
        }
        if (this._idleId) {
            GLib.source_remove(this._idleId);
            this._idleId = 0;
        }
        this._inputSourceManager = null;
    }

    SwitchToUs() {
        const usSource = Object.values(this._inputSourceManager.inputSources)
            .find(source => source.type === 'xkb' && source.id === 'us');
        usSource?.activate();
    }

    _scheduleSwitch() {
        if (this._idleId)
            GLib.source_remove(this._idleId);

        this._idleId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this._idleId = 0;
            this._switchIfTerminal();
            return GLib.SOURCE_REMOVE;
        });
    }

    _switchIfTerminal() {
        const window = global.display.focus_window;
        if (!window || !isTerminal(window))
            return;

        const usSource = Object.values(this._inputSourceManager.inputSources)
            .find(source => source.type === 'xkb' && source.id === 'us');
        usSource?.activate();
    }
}
