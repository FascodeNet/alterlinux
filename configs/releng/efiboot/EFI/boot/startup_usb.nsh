@echo -off

for %m run (0 20)
    if exist fs%m:\%INSTALL_DIR%\boot\x86_64\vmlinuz then
        fs%m:
        cd fs%m:\%INSTALL_DIR%\boot\x86_64
        echo "Launching Archiso Kernel fs%m:\%INSTALL_DIR%\boot\x86_64\vmlinuz"
        vmlinuz archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% initrd=\%INSTALL_DIR%\boot\x86_64\archiso.img
    endif
endfor
