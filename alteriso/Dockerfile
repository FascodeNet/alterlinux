FROM archlinux:latest AS arch

# Update system and install archiso
RUN pacman -Syu --noconfirm && \
    pacman -Scc --noconfirm


FROM arch AS archiso

# Install archiso
RUN pacman -S --noconfirm archiso jq && \
    pacman -Scc --noconfirm

FROM arch AS golang-dev

RUN pacman -S --noconfirm git go jq base-devel && \
    pacman -Scc --noconfirm

FROM golang-dev AS builder
WORKDIR /build
COPY . .

# Build the binary with optimization flags
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -trimpath \
    -o alteriso ./src

# Final stage
FROM archiso AS alteriso

COPY --from=builder /build/alteriso /usr/local/bin/alteriso
COPY ./configs /usr/share/alteriso/configs
COPY ./modules /usr/share/alteriso/modules
COPY ./bootloaders /usr/share/alteriso/bootloaders
COPY ./setup_3rd_repo.sh /tmp/setup_3rd_repo.sh
RUN <<EOF
chmod +x /usr/local/bin/alteriso
chmod +x /tmp/setup_3rd_repo.sh
bash /tmp/setup_3rd_repo.sh
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




