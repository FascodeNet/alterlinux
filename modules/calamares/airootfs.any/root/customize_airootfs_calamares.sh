#!/usr/bin/env bash

# Create Calamares Entry
#if [[ -f "/etc/skel/Desktop/calamares.desktop" ]]; then
#    cp -a "/etc/skel/Desktop/calamares.desktop" "/usr/share/applications/calamares.desktop"
#fi

# Configure Plymouth settings
if [[ "${boot_splash}" = true ]]; then
    # Edit calamares settings for Plymouth.

    # Use lightdm-plymouth instead of lightdm.
    remove "/etc/calamares/modules/services-systemd.conf"
    mv "/etc/calamares/modules/services-systemd-plymouth.conf" "/etc/calamares/modules/services-systemd.conf"

    # Back up default plymouth settings.
    # cp /usr/share/calamares/modules/plymouthcfg.conf /usr/share/calamares/modules/plymouthcfg.conf.org

    # Override theme settings.
    remove "/etc/calamares/modules/plymouthcfg.conf"
    echo '---' > "/etc/calamares/modules/plymouthcfg.conf"
    echo "plymouth_theme: ${theme_name}" >> "/etc/calamares/modules/plymouthcfg.conf"
else
    # Delete the configuration file for plymouth.
    remove "/etc/calamares/modules/services-systemd-plymouth.conf"
fi

# Calamares configs

# Replace the configuration file.
# initcpio
#sed -i "s/%MKINITCPIO_PROFILE%/${kernel_mkinitcpio_profile}/g" /usr/share/calamares/modules/initcpio.configs
sed "s|^kernel:.*$|kernel: ${kernel_mkinitcpio_profile}|g" "/usr/share/calamares/modules/initcpio.conf" > "/etc/calamares/modules/initcpio.conf"

# Set up calamares removeuser
#sed -i "s/%USERNAME%/${username}/g" "/usr/share/calamares/modules/removeuser.conf"
sed "s|^username:.*$|username: ${username}|g" "/usr/share/calamares/modules/removeuser.conf" > "/etc/calamares/modules/removeuser.conf"

# Set user shell
sed -i "s|%USERSHELL%|${usershell}|g" "/etc/calamares/modules/users.conf"

# Setup unpackfs
sed -i "s|%ARCH%|${arch}|g;
        s|%KERNEL_FILENAME%|${kernel_filename}|g;
        s|%INSTALL_DIR%|${install_dir}|g" \
        "/etc/calamares/modules/unpackfs.conf"
