import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Keyboard from 'resource:///org/gnome/shell/ui/status/keyboard.js';

const DBUS_IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.FepSwitcher">
    <method name="SwitchToUs"/>
    <method name="SwitchToJa"/>
  </interface>
</node>`;

export default class FepSwitcherExtension extends Extension {
    enable() {
        this._inputSourceManager = Keyboard.getInputSourceManager();

        this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(DBUS_IFACE, this);
        this._dbusImpl.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/FepSwitcher');
        this._ownerId = Gio.bus_own_name_on_connection(
            Gio.DBus.session,
            'org.gnome.Shell.Extensions.FepSwitcher',
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
        this._inputSourceManager = null;
    }

    SwitchToUs() {
        const source = Object.values(this._inputSourceManager.inputSources)
            .find(s => s.type === 'xkb' && s.id === 'us');
        source?.activate();
    }

    SwitchToJa() {
        const source = Object.values(this._inputSourceManager.inputSources)
            .find(s => s.type === 'ibus' && s.id === 'mozc-jp');
        source?.activate();
    }
}
