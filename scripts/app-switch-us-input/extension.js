import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

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

export default class AppSwitchUsInputExtension extends Extension {
    enable() {
        this._focusChangedId = global.display.connect(
            'notify::focus-window',
            () => this._scheduleSwitch()
        );
        this._idleId = 0;
        this._scheduleSwitch();
    }

    disable() {
        if (this._focusChangedId) {
            global.display.disconnect(this._focusChangedId);
            this._focusChangedId = 0;
        }
        if (this._idleId) {
            GLib.source_remove(this._idleId);
            this._idleId = 0;
        }
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

        Gio.DBus.session.call(
            'org.gnome.Shell.Extensions.FepSwitcher',
            '/org/gnome/Shell/Extensions/FepSwitcher',
            'org.gnome.Shell.Extensions.FepSwitcher',
            'SwitchToUs',
            null, null,
            Gio.DBusCallFlags.NONE,
            -1, null, null
        );
    }
}
