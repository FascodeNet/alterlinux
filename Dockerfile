FROM archlinux:latest
RUN echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Sy --noconfirm reflector
RUN reflector --protocol https -c Japan --sort rate --save /etc/pacman.d/mirrorlist
RUN pacman -Syyu --noconfirm \
        git sudo python3 \
        base-devel cmake ninja qt5-base \
        archiso arch-install-scripts pyalpm
COPY . /alterlinux
WORKDIR /alterlinux
RUN pacman-key --init
RUN ./tools/keyring.sh -a
ENTRYPOINT ["./build.sh"]
CMD []
