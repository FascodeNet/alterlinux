FROM archlinux:latest
RUN curl -o /etc/pacman.d/mirrorlist https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4
RUN sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
RUN pacman -Syyu --noconfirm
RUN pacman -S git archiso arch-install-scripts sudo qt5-base cmake ninja base-devel --noconfirm
RUN git clone https://github.com/SereneTeam/alterlinux.git alterlinux/
WORKDIR /alterlinux
RUN git checkout dev
RUN ./keyring.sh -ca
CMD ["./build.sh", "-b"]
