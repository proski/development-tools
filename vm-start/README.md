vm-start
========

Headless qemu setup suitable for running as a macOS system service.

Installation
------------

Install qemu from homebrew.

Prepare a qcow2 file with an existing install.

Run as root:

cp vm-start /usr/local/bin
cp com.vm.autostart.plist /Library/LaunchDaemons
mkdir /usr/local/vm
cp /existing/file.qcow2 /usr/local/vm
dd if=/dev/zero of=/usr/local/vm/efi_vars.fd bs=1M count=32
chown -R daemon:daemon /usr/local/vm
launchctl load /Library/LaunchDaemons/com.vm.autostart.plist
