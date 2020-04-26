# Using the scipt with systemd-nspawn
Instructions for setting up systemd-nspawn containers for 7thCore's scripts

-------------------------

***Introduction***

systemd-nspawn is like the chroot command, but it is a chroot on steroids.

systemd-nspawn may be used to run a command or OS in a light-weight namespace container. It is more powerful than chroot since it fully virtualizes the file system hierarchy, as well as the process tree, the various IPC subsystems and the host and domain name.

systemd-nspawn limits access to various kernel interfaces in the container to read-only, such as /sys, /proc/sys or /sys/fs/selinux. Network interfaces and the system clock may not be changed from within the container. Device nodes may not be created. The host system cannot be rebooted and kernel modules may not be loaded from within the container.

systemd-nspawn is part of and packaged with systemd meaning it's preinstalled on all systemd enabled distros.

This guide is based on my setup but you may find it usefull.

-------------------------

# Prepare networking

**Create a bridge with systemd-networkd**

To create a simple bridge with systemd-networkd you basicly need 3 files in the following directory of the host:

`/etc/systemd/network/`

The first file is the .netdev file that creates a network interface. 

`/etc/systemd/network/nic0-bridge.netdev`

Contains:

`[NetDev]`

`Name=nic0-bridge`

`Kind=bridge`

The second file is the .network file that will assign the ip configuration for the host: 

`/etc/systemd/network/nic0-bridge.network`

Contains:

`[Match]`

`Name=nic0-bridge`

`[Network]`

`Address=192.168.1.5/24`

`Gateway=192.168.1.1`

`DNS=1.1.1.1`

`DNS=1.0.0.1`

The third file creates a bridge between the nic with the assigned mac address and the virtual interface nic0-bridge:

`/etc/systemd/network/nic0.network`

Contains:

`[Match]`

`MACAddress=00:0a:95:9d:68:16`

`[Network]`

`Bridge=nic0-bridge`

**Passthrough a second nic**

You can passthrough a second nic to the nspawn container by adding `Interface=<name of second nic>` under `[Network]` in the nspawn file.

-------------------------

# Prepare the container

If paths are not specified, containers default to the following location:

`/var/lib/machines/`

If you are using diffrent paths, you will have to symlink it to `/var/lib/machines/` after the installation with:

`sudo ln -s /path/to/desired/container/location/and/ContainerName /var/lib/machines/`

-------------------------

**Arhc Linux**

***Arch Linux container***

For a Arch Linux container you will need the [arch-install-scripts](https://www.archlinux.org/packages/?name=arch-install-scripts) package.

Create a container with the following command:

`sudo pacstrap -c /path/to/desired/container/location/and/ContainerName base [additional pkgs/groups]`

Once your installation is finished, boot into the container:

`sudo systemd-nspawn -b -D /path/to/desired/container/location/and/ContainerName`

Set the root password and logout:

`passwd`

`logout`

Shutdown the container with:

`sudo machinectl stop ContainerName`

***Ubuntu container***

For a Ubuntu container you will need the [debootstrap](https://www.archlinux.org/packages/?name=debootstrap) and the [ubuntu-keyring](https://www.archlinux.org/packages/?name=ubuntu-keyring) package.

Create a container with the following commands:

`cd /path/to/desired/container/location`

`sudo debootstrap --include=systemd-container --components=main,universe <codename: can be bionic, eoan or focal> ContainerName http://archive.ubuntu.com/ubuntu/`

Unlike Arch, Ubuntu will not let you login without a password on first login. To set the root password login without the '-b' option and set a password:

`sudo systemd-nspawn -D /path/to/desired/container/location/and/ContainerName`

`passwd`

`logout`

If the above did not work, one can start the container and use these commands instead:

`sudo systemd-nspawn -b -D /path/to/desired/container/location/and/ContainerName`  #Starts the container

`sudo machinectl shell root@ContainerName /bin/bash`  #Get a root bash shell

`passwd`

`logout`

-------------------------

**Ubuntu**

***Ubuntu container***

Install the [systemd-container](https://packages.ubuntu.com/search?keywords=systemd-container&searchon=names&suite=all&section=all) and [debootstrap](https://packages.ubuntu.com/search?keywords=debootstrap&searchon=names&suite=all&section=all) packages.

Create a container with the following commands:

`cd /path/to/desired/container/location`

`sudo debootstrap --include=systemd-container --components=main,universe <codename: can be bionic, eoan or focal> ContainerName http://archive.ubuntu.com/ubuntu/`

Ubuntu will not let you login without a password on first login. To set the root password login without the '-b' option and set a password:

`sudo systemd-nspawn -D /path/to/desired/container/location/and/ContainerName`

`passwd`

`logout`

If the above did not work, one can start the container and use these commands instead:

`sudo systemd-nspawn -b -D /path/to/desired/container/location/and/ContainerName`  #Starts the container

`sudo machinectl shell root@ContainerName /bin/bash`  #Get a root bash shell

`passwd`

`logout`

-------------------------

# Create the nspawn file

Create a nspawn file in the following location:

`/etc/systemd/nspawn/ContainerName.nspawn`

Contains:

`[Exec]`

`Boot=yes`

`PrivateUsers=pick`

`NotifyReady=yes`

`Hostname=ContainerName`

`Timezone=symlink`

`LinkJournal=try-guest`

`[Files]`

`Bind=/path/on/host:/path/on/container`

`TemporaryFileSystem=/mnt/tmpfs:rw,size=42G,gid=985,mode=0777`

The lines under `[Files]`are not nedded if you don't plan to use a ramdisk and a shared folder between the host and guest.

You also need to add the network configuration to the same file. The following is for passing through a nic:

`[Network]`

`Private=yes`

`VirtualEthernet=yes`

`Bridge=nic0-bridge`

`[Network]`

`Private=yes`

`VirtualEthernet=no`

`Interface=nic1`

This one is for using a bridge we configured earlier:

`[Network]`

`Private=yes`

`VirtualEthernet=yes`

`Bridge=nic0-bridge`

-------------------------

# Enable container on boot and start it

First enable the `machines.target` target with `sudo systemctl enable machines.target`, then `sudo systemctl enable systemd-nspawn@ContainerName.service`, where `ContainerName` is an nspawn container in `/var/lib/machines`.

Now you can start the container with `sudo systemctl start systemd-nspawn@ContainerName.service`

That should be it.
