# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="meta ebuild to select useful software"
HOMEPAGE="http://kicherer.org"

LICENSE="as-is"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="laptop wlan fuse kde kde3 kde4 games media communication office latex misc"

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
		sys-fs/sshfs
		sys-fs/ntfs3g
		net-fs/curlftpfs
		net-fs/davfs2
		net-fs/fusesmb
		)
	laptop? (
		sys-power/cpufreqd
		sys-power/hibernate-script
		app-laptop/laptop-mode-tools
		)
	wlan? (
		net-wireless/wireless-tools
		sys-apps/ifplugd
		net-misc/dhcpcd
		net-wireless/wpa_supplicant
		net-misc/wicd
		)
	kde? (
		kde-base/kdebase-startkde
		kde-base/kdm
		kde-base/konsole
		media-fonts/dejavu
		kde-base/kmenuedit

		kde-base/kdeartwork-kwin-styles
		
		kde-base/kdeartwork-iconthemes
		kde-base/kdeartwork-emoticons
		kde-base/kdeartwork-styles
		kde-base/kdeartwork-wallpapers
		kde-base/kscreensaver
		kde-base/kdeartwork-kscreensaver
		
		kde-base/klettres
		kde-base/keduca
		kde-base/kturtle
		kde-base/kverbos
		kde-base/kmplot
		kde-base/kig
		kde-base/kvoctrain
		kde-base/ktouch
		
		kde-base/kdegraphics-kfile-plugins
		kde-base/kruler
		kde-base/ksnapshot
		kde-base/kview
		kde-base/ksvg
		
		kde-base/kmix
		kde-base/kscd
		kde-base/kdemultimedia-kfile-plugins
		kde-base/kdemultimedia-kioslaves
		
		kde-base/kdenetwork-kfile-plugins
		kde-base/krfb
		kde-base/kdict
		kde-base/kdnssd
		kde-base/kdenetwork-filesharing
		kde-base/krdc
		
		kde-base/kdf
		kde-base/kcalc
		kde-base/kcharselect
		
		kde-base/kate
		kde-base/gwenview
		)
	kde3? (
		kde-base/kdeprint
		kde-base/kghostview
		kde-base/kdvi
		kde-base/kpdf

		kde-base/kpf
		kde-base/knewsticker
		kde-base/khexedit
		kde-base/kregexpeditor
		kde-base/kde-i18n
		
		kde-base/klaptopdaemon
		kde-misc/styleclock
		kde-misc/ksynaptics
		
		kde-misc/ksmoothdock
		kde-misc/kooldock
		kde-misc/kompose
		kde-base/kwifimanager
		kde-base/superkaramba
		kde-base/kweather
		kde-base/kteatime
		)
	kde4? (
		kde-base/okular
		kde-base/dolphin
		kde-base/kde-l10n
		kde-base/kdeplasma-addons
		)
	games? && kde? (
		kde-base/kbattleship
		kde-base/kreversi
		kde-base/kmahjongg
		kde-base/ksokoban
		kde-base/ksnake
		kde-base/atlantik
		kde-base/kmines
		kde-base/ktron
		kde-base/konquest
		kde-base/klines
		)
	games? (
		games-strategy/freeciv
		games-strategy/hedgewars
		games-simulation/openttd
		games-arcade/frozen-bubble
		)
	media? && kde? (
		media-sound/amarok
		media-video/kaffeine
		app-cdr/k3b
		)
	media? (
		media-video/mplayer
		media-video/vlc
		media-sound/alsa-utils
		media-sound/alsa-tools

		media-gfx/gimp
		media-gfx/blender
		)
	communication? (
		www-client/mozilla-firefox
		mail-client/mozilla-thunderbird
		www-plugins/adobe-flash
		net-im/pidgin
		)
	office? && kde? (
		kde-base/kontact
		kde-base/kaddressbook
		kde-base/kmail
		kde-base/korganizer
		kde-base/kontact-specialdates
		)
	office? (
		app-office/openoffice-bin
		app-office/dia
		)
	latex? (
		app-text/texlive
		app-editors/kile
		)
	misc? (
		x11-misc/googleearth
		)
	"

