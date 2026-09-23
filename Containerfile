ARG FEDORA_VERSION=44
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION}

# RPMFusion repos
RUN --mount=type=cache,target=/var/cache/libdnf5 <<EORUN
set -xeuo pipefail

dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    dnf5-plugins
dnf config-manager setopt fedora-cisco-openh264.enabled=1

EORUN


# Groups
RUN --mount=type=cache,target=/var/cache/libdnf5 <<EORUN
set -xeuo pipefail

dnf -y group install \
    base-graphical \
    container-management \
    core \
    firefox \
    fonts \
    gnome-desktop \
    guest-desktop-agents \
    hardware-support \
    multimedia \
    networkmanager-submodules \
    printing \
    virtualization \
    workstation-product

EORUN


# RPMFusion packages
RUN --mount=type=cache,target=/var/cache/libdnf5 <<EORUN
set -xeuo pipefail

dnf swap -y ffmpeg-free ffmpeg --allowerasing
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf install -y intel-media-driver

EORUN


# Extra stuff
RUN --mount=type=cache,target=/var/cache/libdnf5 <<EORUN
set -xeuo pipefail

dnf --setopt=install_weak_deps=False install -y \
alacritty \
ansible-core \
autoconf \
automake \
bash-completion \
binutils-devel \
bison \
buildah \
centos-packager \
centpkg \
clang \
cmake \
composefs-devel \
emacs-nw \
erofs-utils \
fedora-packager \
fedora-packager-kerberos \
flex \
fsverity-utils \
gcc-c++ \
gdb \
gh \
git-email \
gitk \
glib2-devel \
go-md2man \
golang-bin \
golang-x-tools-gopls \
inotify-tools \
json-c-devel \
just \
keepassxc \
krb5-workstation \
libcurl-devel \
libmodulemd-devel \
librepo-devel \
libsolv-devel \
libunwind-devel \
libvirt-devel \
libzstd-devel \
lingot \
moreutils \
openssl-devel \
ostree-devel \
pandoc \
python3-virt-firmware \
ruff \
setools-console \
sqlite-devel \
strace \
tmt+provision-virtual \
tmux \
weechat \
wireshark \
xz-devel \

dnf builddep -y rpm-ostree bootc

EORUN

# Config
RUN <<EORUN

rm -f /usr/lib/systemd/system/bootc-fetch-apply-updates.timer

EORUN

# Cleanup
RUN <<EORUN
set -xeuo pipefail

rm -f /var/log/dnf*
EORUN

# Configure
RUN <<EORUN
set -xeuo pipefail

systemctl set-default graphical.target

cat > /usr/lib/bootc/install/90-xfs.toml <<EOF
[install.filesystem.root]
type = "xfs"
EOF

EORUN

# lint
RUN <<EORUN
set -xeuo pipefail

bootc container lint
EORUN
