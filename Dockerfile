FROM archlinux:latest
RUN echo -n > /etc/pacman.d/mirrorlist
RUN echo 'Server = http://mirrors.cat.net/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
RUN echo 'Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm git sudo python3 \
        base-devel cmake ninja qt5-base \
        archiso arch-install-scripts pyalpm
RUN pacman-key --init
COPY . /alterlinux
WORKDIR /alterlinux
RUN ./tools/keyring.sh -a
ENTRYPOINT ["./build.sh"]
CMD []
