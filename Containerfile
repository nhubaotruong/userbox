FROM ghcr.io/ublue-os/arch-distrobox:latest

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="A cloud-native terminal experience" \
      maintainer="jorge.castro@gmail.com"

# Create build user
RUN useradd -m --shell=/bin/bash build && usermod -L build && \
      echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
      echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add chaotic-aur
RUN pacman-key --init && \
      pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
      pacman-key --lsign-key 3056513887B78AEB && \
      pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'  --noconfirm && \
      printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf

COPY extra-packages aur-packages /
RUN pacman -Syu --noconfirm pacutils
RUN pacinstall --no-confirm --resolve-conflicts=all --dbsync --install $(cat /extra-packages | tr '\n' ' ')
USER build
RUN paru -Syu --noconfirm --skipreview $(cat /aur-packages | tr '\n' ' ')
USER root

RUN rm /extra-packages /aur-packages

RUN ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/distrobox && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman-compose && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/transactional-update && \
      ln -fs /usr/share/icons/Breeze /usr/share/icons/breeze_cursors

# Cleanup
RUN sed -i 's@#en_US.UTF-8@en_US.UTF-8@g' /etc/locale.gen && \
      sed -i 's@#en_GB.UTF-8@en_GB.UTF-8@g' /etc/locale.gen && \
      locale-gen && \
      printf "LANG=en_US.UTF-8\nLC_NUMERIC=en_GB.UTF-8\nLC_TIME=en_GB.UTF-8\nLC_MONETARY=en_GB.UTF-8\nLC_PAPER=en_GB.UTF-8\nLC_MEASUREMENT=en_GB.UTF-8" | tee /etc/locale.conf && \
      userdel -r build && \
      rm -drf /home/build && \
      sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
      sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
      rm -rf \
      /tmp/* \
      /var/cache/pacman/pkg/*