FROM opensuse/leap:16.0
LABEL description="openSUSE Leap 16.0, Integration Test Target (ITT) with systemd"
LABEL maintainer="foundata GmbH (https://foundata.com)"

# Inform systemd it's running in a container and specify the container manager
# type (this may affect the behavior, see src/basic/virt.c).
# Docker users can overwrite this with "--env container=docker".
ENV container=podman

# Ensure Python output goes directly to the terminal without buffering,
# preventing loss of partial output if an application crashes.
ENV PYTHONUNBUFFERED=1

# Install required packages and clean-up package manager caches afterwards.
# Packages are included for these purposes:
#
# - Overall compatibility and network functionality:
#   iproute2 procps systemd which
#
# - Easier debugging within the container (good feature-to-size ratio):
#   iputils less vim-small
#
# - Accessing a container via Ansible:
#   python3 sudo
        #iproute \
        #python312 \
RUN zypper --non-interactive install \
        iproute2 \
        procps \
        systemd \
        which \
        iputils \
        less \
        vim-small \
        python3 \
        sudo \
    && zypper clean -a

# Configure systemd, mask or remove inconvenient systemd units and services.
# Helpful resources to determine problematic units to be removed:
#   systemctl list-dependencies
#   systemctl list-units --state=waiting
#   systemctl list-units --state=failed
#   systemctl mask (if not available: cd path && ln -s -f "/dev/null")
#   https://www.freedesktop.org/software/systemd/man/latest/bootup.html
RUN systemctl mask \
        # Prevent login prompts, agetty on agetty on tty[1-6] etc.
        console-getty.service \
        getty.target \
        systemd-logind.service \
        systemd-ask-password-console.service \
        systemd-ask-password-plymouth.service \
        systemd-ask-password-wall.service \
        # Filesystem related
        dev-hugepages.mount \
        sys-fs-fuse-connections.mount \
        systemd-remount-fs.service \
        # Miscellaneous
        systemd-initctl.service \
        systemd-machine-id-commit.service \
        systemd-random-seed.service \
        systemd-udevd.service \
        systemd-udev-trigger.service \
        # openSUSE Leap specific
        anaconda.service \
        anaconda.target \
        systemd-oomd.service \
        systemd-oomd.socket \
        systemd-resolved.service

# Define volumes for systemd (Podman will do this automatically, but let's add
# this for best-effort Docker compatibility)
VOLUME ["/run", "/run/lock", "/tmp", "/sys/fs/cgroup/systemd", "/var/lib/journal" ]

# Start systemd init
CMD ["/usr/sbin/init"]
