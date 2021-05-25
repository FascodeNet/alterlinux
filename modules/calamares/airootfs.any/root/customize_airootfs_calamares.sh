#!/usr/bin/env bash

# Create Calamares Entry
if [[ -f "/etc/skel/Desktop/calamares.desktop" ]]; then
    cp -a "/etc/skel/Desktop/calamares.desktop" "/usr/share/applications/calamares.desktop"
fi

# Configure Plymouth settings
if [[ "${boot_splash}" = true ]]; then
    # Edit calamares settings for Plymouth.

    # Use lightdm-plymouth instead of lightdm.
    remove "/usr/share/calamares/modules/services.conf"
    mv "/usr/share/calamares/modules/services-plymouth.conf" "/usr/share/calamares/modules/services.conf"

    # Back up default plymouth settings.
    # cp /usr/share/calamares/modules/plymouthcfg.conf /usr/share/calamares/modules/plymouthcfg.conf.org

    # Override theme settings.
    remove "/usr/share/calamares/modules/plymouthcfg.conf"
    echo '---' > "/usr/share/calamares/modules/plymouthcfg.conf"
    echo "plymouth_theme: ${theme_name}" >> "/usr/share/calamares/modules/plymouthcfg.conf"
else
    # Delete the configuration file for plymouth.
    remove "/usr/share/calamares/modules/services-plymouth.conf"
fi

# Calamares configs

# Replace the configuration file.
# initcpio
sed -i "s/%MKINITCPIO_PROFILE%/${kernel_mkinitcpio_profile}/g" /usr/share/calamares/modules/initcpio.conf

# unpackfs
sed -i "s|%KERNEL_FILENAME%|${kernel_filename}|g" /usr/share/calamares/modules/unpackfs.conf

# Remove configuration files for other kernels.
remove "/usr/share/calamares/modules/initcpio/"
remove "/usr/share/calamares/modules/unpackfs/"

# Set up calamares removeuser
sed -i "s/%USERNAME%/${username}/g" "/usr/share/calamares/modules/removeuser.conf"

# Set user shell
sed -i "s|%USERSHELL%|${usershell}|g" "/usr/share/calamares/modules/users.conf"

# Set INSTALL_DIR
sed -i "s/%INSTALL_DIR%/${install_dir}/g" "/usr/share/calamares/modules/unpackfs.conf"

# Set ARCH
sed -i "s/%ARCH%/${arch}/g" "/usr/share/calamares/modules/unpackfs.conf"

# Add disabling of sudo setting
echo -e "\nremove \"/etc/sudoers.d/alterlive\"" >> "/usr/share/calamares/final-process"
echo -e "\nremove \"/etc/systemd/system/getty@.service.d\"" >> "/usr/share/calamares/final-process"
