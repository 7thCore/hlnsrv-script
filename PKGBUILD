# Maintainer: 7thCore

pkgname=hlnsrv-script
pkgver=1.2
pkgrel=7
pkgdesc='Hellion server script for running the server on linux with wine compatibility layer.'
arch=('x86_64')
license=('GPL3')
depends=('bash'
         'coreutils'
         'sudo'
         'grep'
         'sed'
         'awk'
         'curl'
         'rsync'
         'wget'
         'findutils'
         'tmux'
         'zip'
         'unzip'
         'p7zip'
         'postfix'
         'cabextract'
         'xorg-server-xvfb'
         'wine'
         'wine-mono'
         'wine_gecko'
         'winetricks'
         'lcms2'
         'mpg123'
         'giflib'
         'gnutls'
         'gst-plugins-base'
         'gst-plugins-good'
         'libpng'
         'libpulse'
         'libxml2'
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
install=hlnsrv-script.install
source=('bash_profile'
        'hlnsrv-mkdir-tmpfs.service'
        'hlnsrv-script.bash'
        'hlnsrv-send-notification.service'
        'hlnsrv.service'
        'hlnsrv-timer-1.service'
        'hlnsrv-timer-1.timer'
        'hlnsrv-timer-2.service'
        'hlnsrv-timer-2.timer'
        'hlnsrv-tmpfs.service')
sha256sums=('f1e2f643b81b27d16fe79e0563e39c597ce42621ae7c2433fd5b70f1eeab5d63'
            'b834287ecfe22a85ca7205b14e7a2ab7a4651ba48e6ba1dbbb76571a62356ca5'
            '6d997c139898ce5312af70a1b7993f8f6aad783b3a57e4dc637bf813f86f9395'
            'd899e55144563442ef526f13fe7511333015a04fce3a8d411943983597f467f3'
            'd972eb008f8577325940ead768517cb2b2ef5aedb189951584d56eb5f58577cc'
            '7a0953dca1ee275ad5f6d46ba43fd320f4290f0201cac4f9f5d7c634dfbfd726'
            '6a0519681663165fd348eabb855f6469e8f586ae8658e2b48d59895b4a8799ab'
            'a7e197d86ff5a15006d2706f1e10481c52b8fef37674d173e615d07ce44f00f5'
            '0073cdafd1b467144bfcb80d8781002e043323a7f4da0f77d457f47d89a1dec7'
            '132a7926f56ba2e78e8e55b74dc2167765d14a39b57851fe73d44addf8831b6f')

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
