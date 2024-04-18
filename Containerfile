FROM ghcr.io/ublue-os/arch-distrobox:latest

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="A cloud-native terminal experience" \
      maintainer="jorge.castro@gmail.com"

# Create build user
RUN sed -i 's/#Color/Color/g' /etc/pacman.conf && \
      printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | tee -a /etc/pacman.conf && \
      sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/g' /etc/makepkg.conf && \
      pacman -Syu --noconfirm && \
      pacman -S \
      wget \
      base-devel \
      git \
      --noconfirm && \
      useradd -m --shell=/bin/bash build && usermod -L build && \
      echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
      echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY extra-packages /
USER build

RUN grep -v '^#' /extra-packages | xargs paru -Syu --noconfirm --noedit
USER root

RUN rm /extra-packages

RUN ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/distrobox && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman-compose && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/transactional-update

# Cleanup
RUN sed -i 's@#en_US.UTF-8@en_US.UTF-8@g' /etc/locale.gen && \
      userdel -r build && \
      rm -drf /home/build && \
      sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
      sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
      rm -rf \
      /tmp/* \
      /var/cache/pacman/pkg/*