# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# to use this ebuild, add PORTDIR_OVERLAY="/usr/local/portage" to make.conf
# and put this ebuild into /usr/local/portage/virtual/anyc-meta/ and run:
# "ebuild anyc-meta-2.ebuild digest"

EAPI="4"

DESCRIPTION="meta ebuild to select useful software"
HOMEPAGE="http://kicherer.org"

LICENSE="as-is"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="laptop wlan fuse kde4 games media communication office latex misc photo
	nettools"

DEPEND=""
RDEPEND="${DEPEND}
	app-portage/gentoolkit
	app-portage/genlop
	dev-util/ccache
	sys-power/acpid

	app-misc/screen
	app-admin/sudo
	net-misc/ntp

	sys-apps/smartmontools
	app-admin/hddtemp
	sys-apps/lm_sensors

	net-misc/openssh

	fuse? (
		sys-fs/fuse
		sys-fs/sshfs-fuse
		sys-fs/ntfs3g
		net-fs/davfs2
		sys-fs/fuseiso
		)
	laptop? (
		app-laptop/laptop-mode-tools
		sys-power/pm-utils
		sys-power/powertop
		)
	wlan? (
		net-wireless/wireless-tools
		sys-apps/ifplugd
		net-misc/dhcpcd
		net-wireless/wpa_supplicant
		|| (
			net-misc/networkmanager
			net-misc/wicd
		   )
		net-wireless/iw
		net-wireless/rfkill
		)
	kde4? (
		kde-base/kdebase-startkde
		kde-base/kdm
		kde-base/konsole
		media-fonts/dejavu
		kde-base/kmenuedit

		kde-base/kdeartwork-colorschemes
		kde-base/kdeartwork-desktopthemes
		kde-base/kdeartwork-iconthemes
		kde-base/kdeartwork-emoticons
		kde-base/kdeartwork-styles
		kde-base/kdeartwork-wallpapers
		kde-base/kscreensaver
		kde-base/kdeartwork-kscreensaver
		
		kde-base/klettres
		kde-base/kturtle
		kde-base/kmplot
		
		kde-base/kruler
		kde-base/ksnapshot
		
		kde-base/kmix
		kde-base/kscd
		kde-base/kdemultimedia-kioslaves
		
		kde-base/krfb
		kde-base/kdnssd
		kde-base/kdenetwork-filesharing
		kde-base/krdc
		
		kde-base/kdf
		kde-base/kcalc
		kde-base/kcharselect
		
		kde-base/kate
		kde-base/gwenview
		
		kde-base/okular
		kde-base/dolphin
		kde-base/kde-l10n
		kde-base/kdeplasma-addons
		kde-misc/networkmanagement
		)
	games? (
		kde4? (
			kde-base/kbattleship
			kde-base/kreversi
			kde-base/kmahjongg
			kde-base/kmines
			kde-base/ktron
			kde-base/konquest
			kde-base/klines
			)
		games-strategy/freeciv
		games-strategy/hedgewars
		games-simulation/openttd
		games-arcade/frozen-bubble
		)
	media? (
		kde4? (
			media-sound/amarok
			media-video/kaffeine
			app-cdr/k3b
			)
		media-video/mplayer
		media-video/vlc
		media-sound/alsa-utils
		media-sound/alsa-tools

		media-gfx/gimp
		media-gfx/blender
		media-gfx/inkscape
		)
	communication? (
		www-client/firefox
		mail-client/thunderbird
		www-plugins/adobe-flash
		net-im/pidgin
		www-plugins/kpartsplugin
		)
	office? (
		kde4? (
			kde-base/kontact
			kde-base/kaddressbook
			kde-base/kmail
			kde-base/korganizer
			)
		app-office/openoffice-bin
		app-office/dia
		)
	latex? (
		app-text/texlive
		app-editors/kile
		)
	misc? (
		sci-geosciences/googleearth
		app-emulation/wine
		)
	photo? (
		media-gfx/darktable
		media-gfx/digikam
		media-gfx/gimp
		media-gfx/hugin
		media-gfx/rawtherapee
		media-plugins/gimp-lensfun
		media-plugins/kipi-plugins
		)
	nettools? (
		net-analyzer/arping
		net-analyzer/mtr
		net-analyzer/tcpdump
		net-analyzer/tcptraceroute
		net-dialup/minicom
		net-dialup/ppp
		net-misc/bridge-utils
		net-misc/socat
		net-misc/vconfig
		)
	"

