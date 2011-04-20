#!/bin/bash

apt-add-repository ppa:glasen/855gm-fix
apt-add-repository ppa:brian-rogers/graphics-fixes
apt-add-repository ppa:glasen/intel-driver
aptitude update
aptitude install linux 855gm-fix-dkms
aptitude dist-upgrade

cat <<EOF >/etc/X11/xorg.conf
Section "Module"
        Disable "dri"
        Disable "glx"
EndSection
EOF
