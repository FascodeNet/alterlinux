#!/usr/bin/env python3
#== Copyright ==#
# (C) 2019-2020 Fascode Network

#== Import ==#
import gi, subprocess, sys, threading
gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk, GObject

#== Main Window ==#
class MainWindow(Gtk.Window):
    #= Fuction =#
    def __init__(self):
        def yn(name):
            y = Gtk.RadioButton.new_with_label_from_widget(None, "Yes")
            y.connect("toggled", self.on_button_toggled, name, True)
            n = Gtk.RadioButton.new_with_mnemonic_from_widget(y, "No")
            n.connect("toggled", self.on_button_toggled, name, False)
            return y, n

        def combobox(name, list):
            list_store = Gtk.ListStore(int, str)
            for num in range(len(list)):
                list_store.append([num, list[num]])

            combo = Gtk.ComboBox.new_with_model_and_entry(list_store)
            combo.connect("changed", self.on_combo_changed, name)
            combo.set_entry_text_column(1)
            combo.set_active(0)
            return combo

        #-- Create Window --#
        Gtk.Window.__init__(self, title="build wizard")

        #-- Define --#
        self.bool = {"plymouth": True, "japanese": True}
        self.selected = {"build": "native"}

        #-- Sub Layout 1 --#
        #- Create -#
        sub_layout1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

        #- Labels -#
        label1 = Gtk.Label("select desktop environment")
        label2 = Gtk.Label("select kernel")

        #- Comboboxes -#
        de = combobox("de", ["xfce", "plasma", "lxde"])
        kernel= combobox("kernel", ["zen", "linux", "lts", "lqx", "ck", "rt", "rt-lts", "xanmod-lts"])

        #- Buttons & Add -#
        for name in "plymouth", "japanese":
            y, n = yn(name)
            subs_layout = Gtk.Box(spacing=5)
            subs_layout.pack_start(y, True, True, 30)
            subs_layout.pack_start(n, True, True, 30)
            label = Gtk.Label("Enable" + " " + name + "?")
            sub_layout1.pack_start(label,       True, True, 5)
            sub_layout1.pack_start(subs_layout, True, True, 5)

        #- Add -#
        for name in label1, de, label2, kernel:
            sub_layout1.pack_start(name, True, True, 5)

        #-- Sub Layout 2 --#
        #- Create -#
        sub_layout2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

        #- Labels -#
        label1 = Gtk.Label("select compression")
        label2 = Gtk.Label("user name")
        label3 = Gtk.Label("password")

        #- Combobox -#
        comp = combobox("comp", ["zstd", "lzma", "lzo", "lz4", "xz", "gzip"])

        #- Entrys -#
        self.usr = Gtk.Entry()
        self.usr.set_text("alter")
        self.passwd = Gtk.Entry()
        self.passwd.set_visibility(False)
        self.passwd.set_text("alter")

        #- Button -#
        showpasswd = Gtk.ToggleButton("Show password")
        showpasswd.connect("toggled", self.on_button_toggled, "1")

        #- Add -#
        for name in label1, comp, label2, self.usr, label3, self.passwd, showpasswd:
            sub_layout2.pack_start(name, True, True, 5)

        #-- Sub Layout 3 --#
        #- Create -#
        sub_layout3 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

        #- Label -#
        label = Gtk.Label("select build type")

        #- Button -#
        button1 = Gtk.RadioButton.new_with_label_from_widget(None, "native")
        button1.connect("toggled", self.select_build, "native")

        #- Add -#
        sub_layout3.pack_start(label, True, True, 5)
        sub_layout3.pack_start(button1, True, True, 5)

        #- Buttons & Add -#
        for name in "docker", "ssh":
            button = Gtk.RadioButton.new_with_mnemonic_from_widget(button1, name)
            button.connect("toggled", self.select_build, name)
            sub_layout3.pack_start(button, True, True, 5)

        #-- Grid --#
        #- Create -#
        grid = Gtk.Grid(column_spacing=10, row_spacing=10)

        #- Progressbar -#
        self.progressbar = Gtk.ProgressBar()

        #- Button -#
        build = Gtk.Button("build")
        build.connect("clicked", self.on_click_build)

        #- Add -#
        grid.attach(sub_layout1,      0, 0, 1, 1)
        grid.attach(sub_layout2,      1, 0, 1, 1)
        grid.attach(sub_layout3,      2, 0, 1, 1)
        grid.attach(self.progressbar, 0, 1, 2, 1)
        grid.attach(build,            2, 1, 1, 1)

        #-- Layout --#
        #- Create -#
        layout = Gtk.Box(spacing=10)

        #- Add -#
        layout.pack_start(grid, True, True, 10)

        #-- Main Layout --#
        #- Create -#
        main_layout = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        #- Add -#
        main_layout.pack_start(layout, True, True, 10)

        #-- Add Main Window --#
        self.add(main_layout)

    def on_button_toggled(self, button, name):
        if button.get_active():
            self.passwd.set_visibility(True)
        else:
            self.passwd.set_visibility(False)

    def on_combo_changed(self, combo, name):
        self.selected[name] = combo.get_model()[combo.get_active_iter()][1]

    def select_build(self, button, name):
        self.selected["build"] = name

    def on_click_build(self, button):
        cmd = ["sudo", "./build.sh"]

        if self.selected["build"] == "native":
            if self.bool["plymouth"]:
                cmd.append("-b")

            if self.bool["japanese"]:
                cmd.append("-j")

            for name in "-k", self.selected["kernel"], "-c", self.selected["comp"], "-u", self.usr.get_text(), "-p", self.passwd.get_text():
                cmd.append(name)

            self.run_cmd(cmd)
        else:
            self.progressbar.set_show_text(1)
            self.progressbar.set_text("not supported!")
            print("not supported!")

    def run_cmd(self, cmd):
        def update(line):
            self.progressbar.pulse()
            self.progressbar.set_show_text(1)
            self.progressbar.set_ellipsize(True)
            self.progressbar.set_text(line)
            return False

        def run():
            run = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr = subprocess.STDOUT)
            while run.poll() is None:
                line = run.stdout.readline().decode('utf-8')
                if line:
                    yield line

        def echo():
            for line in run():
                GLib.idle_add(update, line)
                sys.stdout.write(line)

        thread = threading.Thread(target=echo)
        thread.daemon = True
        thread.start()

#== Run ==#
if __name__ == "__main__":
    win = MainWindow()
    win.show_all()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()
