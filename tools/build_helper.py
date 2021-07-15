#!/usr/bin/env python3
import gi, os, shlex, subprocess, sys
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

class MainWindow(Gtk.Window):
    def __init__(self):

        #-- Check gtk --#
        if not Gtk.init_check()[0]:
            script_name = os.path.basename(__file__)
            print("[{}]: Failed to initialize gtk".format(script_name))
            sys.exit()

        #-- Create Window --#
        Gtk.Window.__init__(self, title="AlterISO GUI Helper")

        #-- Set window icon --#
        _window_icon = "images/icon/color/AlterV5-Icon-Colored-vector.svg"
        self.set_icon_from_file(os.path.join(root_dir, _window_icon))

        #-- Create Dict --#
        self.dict = {}
        arch_list = Gtk.ListStore(int, str)
        arch_list_num = 0

        for arch in "x86_64", "i686":
            dict = {}

            for value in "kernel", "locale":
                liststore = Gtk.ListStore(int, str)
                liststore_num = 0

                with open("{}/system/{}-{}".format(root_dir, value, arch)) as f:
                    for i in [value.strip().split()[-1] for value in f.readlines() if not "#" in value and value != "\n"]:
                        liststore.append([liststore_num, i])
                        liststore_num += 1

                dict[value] = liststore
            
            liststore = Gtk.ListStore(int, str)
            liststore_num = 0
            command = "{}/channel.sh --nobuiltin --arch {} show".format(script_dir, arch)
            command_obj = shlex.split(command)
            proc = subprocess.Popen(command_obj, stdout=subprocess.PIPE, text=True)
            
            for values in sorted(proc.stdout.read().strip().split()):
                liststore.append([liststore_num, values])
                liststore_num += 1
            
            dict["channel"] = liststore
        
            self.dict[arch] = dict
            arch_list.append([arch_list_num, arch])
            arch_list_num += 1

        #-- Create Widget --#
        # arch
        arch_label = Gtk.Label(label="Architecture")
        self.arch_combo = Gtk.ComboBox.new_with_model_and_entry(arch_list)
        self.arch_combo.set_entry_text_column(1)
        self.arch_combo.set_active(0)
        self.arch_combo.connect("changed", self.on_arch_combo_changed)
        self.default_arch = self.arch_combo.get_model()[self.arch_combo.get_active_iter()][1]
        arch_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        arch_box.set_homogeneous(True)
        arch_box.pack_start(arch_label, True, True, 0)
        arch_box.pack_start(self.arch_combo, True, True, 0)

        # kernel
        kernel_label = Gtk.Label(label="Kernel")
        kernel_list = self.dict[self.default_arch]["kernel"]
        self.kernel_combo = Gtk.ComboBox.new_with_model_and_entry(kernel_list)
        self.kernel_combo.set_entry_text_column(1)
        self.kernel_combo.set_active(0)
        kernel_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        kernel_box.set_homogeneous(True)
        kernel_box.pack_start(kernel_label, True, True, 0)
        kernel_box.pack_start(self.kernel_combo, True, True, 0)
        
        # locale
        locale_label = Gtk.Label(label="Locale")
        locale_list = self.dict[self.default_arch]["locale"]
        self.locale_combo = Gtk.ComboBox.new_with_model_and_entry(locale_list)
        self.locale_combo.set_entry_text_column(1)
        self.locale_combo.set_active(0)
        locale_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        locale_box.set_homogeneous(True)
        locale_box.pack_start(locale_label, True, True, 0)
        locale_box.pack_start(self.locale_combo, True, True, 0)

        # channel
        channel_label = Gtk.Label(label="Channel")
        channel_list = self.dict[self.default_arch]["channel"]
        self.channel_combo = Gtk.ComboBox.new_with_model_and_entry(channel_list)
        self.channel_combo.set_entry_text_column(1)

        for i in range(len(self.channel_combo.get_model())):
            if "xfce" == self.channel_combo.get_model()[i][1]:
                self.channel_combo.set_active(i)
                break
        else:
            self.channel_combo.set_active(0)
        
        channel_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        channel_box.set_homogeneous(True)
        channel_box.pack_start(channel_label, True, True, 0)
        channel_box.pack_start(self.channel_combo, True, True, 0)

        # compression
        comp_label = Gtk.Label(label="Compression")
        comp_list = Gtk.ListStore(int, str)
        comp_list_num = 0

        for i in "gzip", "lz4", "lzma", "lzo", "xz", "zstd":
            comp_list.append([comp_list_num, i])
            comp_list_num += 1

        self.comp_combo = Gtk.ComboBox.new_with_model_and_entry(comp_list)
        self.comp_combo.set_entry_text_column(1)
        self.comp_combo.set_active(5)
        comp_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        comp_box.set_homogeneous(True)
        comp_box.pack_start(comp_label, True, True, 0)
        comp_box.pack_start(self.comp_combo, True, True, 0)

        # boot splash
        boot_splash_label = Gtk.Label(label="Boot Splash")
        self.boot_splash_button_enable = Gtk.RadioButton.new_with_label_from_widget(None, "Enable")
        self.boot_splash_button_disable = Gtk.RadioButton.new_with_mnemonic_from_widget(self.boot_splash_button_enable, "Disable")
        sub_boot_splash_box = Gtk.Box(spacing=5)
        sub_boot_splash_box.set_homogeneous(True)
        sub_boot_splash_box.pack_start(self.boot_splash_button_enable, True, True, 0)
        sub_boot_splash_box.pack_start(self.boot_splash_button_disable, True, True, 0)
        boot_splash_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        boot_splash_box.set_homogeneous(True)
        boot_splash_box.pack_start(boot_splash_label, True, True, 0)
        boot_splash_box.pack_start(sub_boot_splash_box, True, True, 0)

        # username
        username_label = Gtk.Label(label="Username")
        self.username_entry = Gtk.Entry()
        self.username_entry.set_text("alter")
        username_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        username_box.set_homogeneous(True)
        username_box.pack_start(username_label, True, True, 0)
        username_box.pack_start(self.username_entry, True, True, 0)

        # password
        password_label = Gtk.Label(label="Password")
        self.password_entry = Gtk.Entry()
        self.password_entry.set_visibility(False)
        self.password_entry.set_text("alter")
        self.password_button = Gtk.Button.new_with_label("Show Password")
        self.password_button.connect("clicked", self.on_password_clicked)
        password_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        password_box.set_homogeneous(True)
        password_box.pack_start(password_label, True, True, 0)
        password_box.pack_start(self.password_entry, True, True, 0)
        password_box.pack_start(self.password_button, True, True, 0)

        # extra_option
        extra_option_label = Gtk.Label(label="Extra build options: Additional command line options")
        self.extra_option_entry = Gtk.Entry()
        self.extra_option_entry.set_text("")
        extra_option_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        extra_option_box.set_homogeneous(True)
        extra_option_box.pack_start(extra_option_label, True, True, 0)
        extra_option_box.pack_start(self.extra_option_entry, True, True, 0)
        
        # reset
        reset_button = Gtk.Button.new_with_label("Reset")
        reset_button.connect("clicked", self.on_reset_clicked)

        # build
        build_button = Gtk.Button.new_with_label("Build")
        build_button.connect("clicked", self.on_build_clicked)

        # exit
        exit_button = Gtk.Button.new_with_label("Exit")
        exit_button.connect("clicked", self.on_exit_clicked)

        util_box = Gtk.Box(spacing=5)
        util_box.set_homogeneous(True)
        util_box.pack_start(reset_button, True, True, 0)
        util_box.pack_start(build_button, True, True, 0)
        util_box.pack_start(exit_button, True, True, 0)

        
        #-- Create Layout --#
        # layout 1
        layout_1 = Gtk.Box(spacing=5)
        layout_1.pack_start(arch_box, True, True, 0)
        layout_1.pack_start(kernel_box, True, True, 0)
        layout_1.pack_start(locale_box, True, True, 0)
        layout_1.pack_start(channel_box, True, True, 0)

        # layout 2
        layout_2 = Gtk.Grid()
        layout_2.set_column_spacing(5)
        layout_2.set_column_homogeneous(True)
        layout_2.attach(comp_box, 0, 0, 1, 2)
        layout_2.attach(boot_splash_box, 1, 0, 1, 2)
        layout_2.attach(username_box, 2, 0, 1, 2)
        layout_2.attach(password_box, 3, 0, 1, 3)

        # layout 3
        layout_3 = Gtk.Grid()
        layout_3.set_column_spacing(5)
        layout_3.set_column_homogeneous(True)
        layout_3.attach(extra_option_box, 4, 0, 1, 3)


        # sub layout
        sub_layout = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        sub_layout.pack_start(layout_1, True, True, 5)
        sub_layout.pack_start(layout_2, True, True, 5)
        sub_layout.pack_start(layout_3, True, True, 5)
        sub_layout.pack_start(util_box,  True, True, 5)
        
        # main layout
        main_layout = Gtk.Box(spacing=5)
        main_layout.pack_start(sub_layout, True, True, 5)
        self.add(main_layout)

    def on_arch_combo_changed(self, combo):
        self._reset()

    def on_password_clicked(self, button):
        if self.password_entry.get_visibility():
            self.password_entry.set_visibility(False)
            self.password_button.set_label("Show Password")
        else:
            self.password_entry.set_visibility(True)
            self.password_button.set_label("Hide Password")

    def on_exit_clicked(self, button):
        sys.exit()

    def on_build_clicked(self, button):
        arch = self.arch_combo.get_model()[self.arch_combo.get_active_iter()][1]
        kernel = self.kernel_combo.get_model()[self.kernel_combo.get_active_iter()][1]
        locale = self.locale_combo.get_model()[self.locale_combo.get_active_iter()][1][0:2]
        channel = self.channel_combo.get_model()[self.channel_combo.get_active_iter()][1]
        comp = self.comp_combo.get_model()[self.comp_combo.get_active_iter()][1]
        username = self.username_entry.get_text()
        password = self.password_entry.get_text()
        extra_option = self.extra_option_entry.get_text()

        if kernel == "linux":
            kernel = "core"
        else:
            kernel = kernel.replace("linux-", "")
        
        display = os.environ["DISPLAY"]
        xauthority = os.environ["XAUTHORITY"]

        command = "pkexec env DISPLAY={} XAUTHORITY={} {}/build.sh --noconfirm --arch {} --kernel {} --lang {} --comp-type {} --user {} --password {} {}".format(display, xauthority, root_dir, arch, kernel, locale, comp, username, password, extra_option)
        
        if self.boot_splash_button_enable.get_active():
            command = "{} --boot-splash".format(command)
        
        command = "{} {}".format(command, channel)
        command_obj = shlex.split(command)
        print("----- START -----")
        print("RUN CMD:", command)
        proc = subprocess.run(command_obj)

        if proc.returncode == 0:
            print("Done!")
        else:
            print("Error Occured! Return Code", proc.returncode)
        
        print("===== END =====\n")

    def on_reset_clicked(self, button):
        self.arch_combo.set_active(0)
        self._reset()
        self.comp_combo.set_active(5)
        self.username_entry.set_text("alter")
        self.password_entry.set_text("alter")
    
    def _reset(self):
        arch = self.arch_combo.get_model()[self.arch_combo.get_active_iter()][1]
        self.kernel_combo.set_model(self.dict[arch]["kernel"])
        self.kernel_combo.set_active(0)
        self.locale_combo.set_model(self.dict[arch]["locale"])
        self.locale_combo.set_active(0)
        self.channel_combo.set_model(self.dict[arch]["channel"])

        for i in range(len(self.channel_combo.get_model())):
            if "xfce" == self.channel_combo.get_model()[i][1]:
                self.channel_combo.set_active(i)
                break
        else:
            self.channel_combo.set_active(0)


if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(script_dir)
    win = MainWindow()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
