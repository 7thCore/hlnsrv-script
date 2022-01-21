# Maintainer: 7thCore

pkgname=hlnsrv-script
pkgver=1.1
pkgrel=1
pkgdesc='Hellion server script for running the server on linux with wine compatibility layer.'
arch=('x86_64')
depends=('bash'
         'coreutils'
         'sudo'
         'grep'
         'sed'
         'awk'
         'curl'
         'rsync'
         'findutils'
         'cabextract'
         'unzip'
         'p7zip'
         'wget'
         'tmux'
         'postfix'
         'zip'
         'jq'
         'samba'
         'xorg-server-xvfb'
         'wine'
         'wine-mono'
         'wine_gecko'
         'winetricks'
         'libpulse'
         'libxml2'
         'mpg123'
         'lcms2'
         'giflib'
         'libpng'
         'gnutls'
         'gst-plugins-base'
         'gst-plugins-good'
         'lib32-libpulse'
         'lib32-libxml2'
         'lib32-mpg123'
         'lib32-lcms2'
         'lib32-giflib'
         'lib32-libpng'
         'lib32-gnutls'
         'lib32-gst-plugins-base'
         'lib32-gst-plugins-good'
         'steamcmd')
backup=('')
install=hlnsrv-script.install
source=('hlnsrv-script.bash'
        'hlnsrv-timer-1.timer'
        'hlnsrv-timer-1.service'
        'hlnsrv-timer-2.timer'
        'hlnsrv-timer-2.service'
        'hlnsrv-send-notification.service'
        'hlnsrv.service'
        'hlnsrv-mkdir-tmpfs.service'
        'hlnsrv-tmpfs.service'
        'bash_profile')
noextract=('')
sha256sums=('95bc892db033e457a7b081530382812de29a41df19c6f4d25035d9672c007e11'
            'deb68ef656e1c6e69ca9ac993990306ab7e44e3f6c3c67cb6136266ad6359f54'
            '30c346e7bb70a9fd257fb389b774eca12f25b1ba8cd709af7d9dc8b9d985abd1'
            '58f2a4a7bfa23fc9011948cb16f60426ad52bde2261f8a8d712b8f8184de2568'
            '0d8ebd66c10d9acc9b752185191427247ea654a595674ca304376295b91e2c6a'
            'acf6b216948e533825d94b7e092ed22c57cddf8a117738df082e9af5e7fce6d2'
            'e4c5057d307572f835260208e2b3d3252e5a78f76bf11b28855bea479d4747e6'
            '93014c64a50fda63f7c22d151469a625753ebce7847697917cf8921ad308f2e6'
            '636320f47b6ed583dc5d1cd0b34945e680699f5675eb569a4e99a23b7b259efd'
            'f1e2f643b81b27d16fe79e0563e39c597ce42621ae7c2433fd5b70f1eeab5d63')

package() {
  install -d -m0755 "${pkgdir}/usr/bin"
  install -d -m0755 "${pkgdir}/srv/hlnsrv"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/server"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/config"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/updates"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/backups"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/logs"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/tmpfs"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/.config"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/.config/systemd"
  install -d -m0755 "${pkgdir}/srv/hlnsrv/.config/systemd/user"
  install -D -Dm755 "${srcdir}/hlnsrv-script.bash" "${pkgdir}/usr/bin/hlnsrv-script"
  install -D -Dm755 "${srcdir}/hlnsrv-timer-1.timer" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-timer-1.timer"
  install -D -Dm755 "${srcdir}/hlnsrv-timer-1.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-timer-1.service"
  install -D -Dm755 "${srcdir}/hlnsrv-timer-2.timer" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-timer-2.timer"
  install -D -Dm755 "${srcdir}/hlnsrv-timer-2.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-timer-2.service"
  install -D -Dm755 "${srcdir}/hlnsrv-send-notification.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-send-notification.service"
  install -D -Dm755 "${srcdir}/hlnsrv.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv.service"
  install -D -Dm755 "${srcdir}/hlnsrv-mkdir-tmpfs.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-mkdir-tmpfs.service"
  install -D -Dm755 "${srcdir}/hlnsrv-tmpfs.service" "${pkgdir}/srv/hlnsrv/.config/systemd/user/hlnsrv-tmpfs.service"
  install -D -Dm755 "${srcdir}/bash_profile" "${pkgdir}/srv/hlnsrv/.bash_profile"
}
