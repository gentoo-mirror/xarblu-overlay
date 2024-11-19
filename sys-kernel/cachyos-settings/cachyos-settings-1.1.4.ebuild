# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev tmpfiles systemd

DESCRIPTION="Configuration files and tweaks from CachyOS"
HOMEPAGE="https://github.com/CachyOS/CachyOS-Settings"
SRC_URI="https://github.com/CachyOS/CachyOS-Settings/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/CachyOS-Settings-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd zram"
REQUIRED_USE="zram? ( systemd )"

RDEPEND="
	sys-apps/hdparm
	sys-process/procps
	virtual/udev
	zram? (
		sys-apps/zram-generator
		app-arch/zstd
	)
"

src_install() {
	# only install script that make sense
	dobin usr/bin/kerver
	dobin usr/bin/ksmctl
	dobin usr/bin/ksmstats

	insinto /usr/lib/modprobe.d
	doins usr/lib/modprobe.d/*

	insinto /usr/lib/sysctl.d
	doins usr/lib/sysctl.d/*

	if use systemd; then
		# can't use systemd_get_utildir directly
		# as it includes EPREFIX
		local systemd_utildir
		systemd_utildir="$(systemd_get_utildir)"
		systemd_utildir="${systemd_utildir#"${EPREFIX}"}"

		insinto "${systemd_utildir}/journald.conf.d"
		doins usr/lib/systemd/journald.conf.d/*

		insinto "${systemd_utildir}/system.conf.d"
		doins usr/lib/systemd/system.conf.d/*

		# this explicitly doesn't install the
		# .service files (only dropins) because we
		# don't install the cachyos specific scripts
		insinto "${systemd_utildir}/system"
		doins -r  usr/lib/systemd/system/*.service.d

		insinto "${systemd_utildir}/user.conf.d"
		doins usr/lib/systemd/user.conf.d/*

		if use zram; then
			insinto "${systemd_utildir}"
			doins usr/lib/systemd/zram-generator.conf
		fi
	fi

	dotmpfiles usr/lib/tmpfiles.d/*

	udev_dorules usr/lib/udev/rules.d/*
}

pkg_postinst() {
	udev_reload
	tmpfiles_process coredump.conf disable-zswap.conf optimize-interruptfreq.conf thp.conf
}

pkg_postrm() {
	udev_reload
}
