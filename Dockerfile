FROM archlinux:latest
RUN echo 'Server = http://mirrors.cat.net/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist \
&& echo 'nameserver 1.1.1.1' > /etc/resolv.conf
RUN pacman -Syyu --noconfirm
RUN pacman -S archiso git arch-install-scripts sudo qt5-base cmake ninja base-devel --noconfirm
RUN git clone https://github.com/FascodeNet/alterlinux.git alterlinux/
WORKDIR /alterlinux
RUN git checkout dev
RUN ./keyring.sh -ca
CMD ["./build.sh", "-b"]
