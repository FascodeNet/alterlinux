FROM archlinux:latest AS arch

# Update system and install archiso
RUN pacman -Syu --noconfirm && \
    pacman -Scc --noconfirm


FROM arch AS archiso-deps

# Install archiso runtime dependencies
RUN <<EOS
set -eu
pacman -Sy --noconfirm jq unzip \
    arch-install-scripts dosfstools e2fsprogs libisoburn mtools squashfs-tools erofs-utils
pacman -Scc --noconfirm
EOS

FROM arch AS golang-dev

RUN pacman -S --noconfirm git go jq base-devel && \
    pacman -Scc --noconfirm

FROM golang-dev AS builder
ARG ALTERISO_VERSION=devel
ARG GIT_REVISION
WORKDIR /build
COPY . .

# Build the binary with optimization flags
RUN CGO_ENABLED=1 GOOS=linux go build \
    -ldflags="-s -w \
        -X github.com/FascodeNet/alterlinux/src/internal/buildinfo.version=${ALTERISO_VERSION} \
        -X github.com/FascodeNet/alterlinux/src/internal/buildinfo.revision=${GIT_REVISION}" \
    -trimpath \
    -o alteriso ./src

# Final stage
FROM archiso-deps AS alteriso

ARG GIT_REVISION
ENV GIT_REVISION=${GIT_REVISION}

COPY --from=builder /build/alteriso /usr/local/bin/alteriso
COPY ./configs /usr/share/alteriso/configs
COPY ./modules /usr/share/alteriso/modules
COPY ./bootloaders /usr/share/alteriso/bootloaders
COPY ./setup_3rd_repo.sh /tmp/setup_3rd_repo.sh
RUN <<EOF
set -eu

alteriso install-archiso

chmod +x /usr/local/bin/alteriso /tmp/setup_3rd_repo.sh
bash /tmp/setup_3rd_repo.sh || exit 1
rm -rf /tmp/setup_3rd_repo.sh
EOF

# FROM alteriso
# WORKDIR /app
# RUN --security=insecure <<EOF
# alteriso profile \
#     --bootloaders /usr/share/alteriso/bootloaders \
#     --modules /usr/share/alteriso/modules \
#     generate \
#     -o ./out /usr/share/alteriso/configs/xfce
# mkarchiso -v -o ./out -w ./work ./out/xfce
# EOF


