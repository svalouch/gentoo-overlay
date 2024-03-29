# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit fcaps savedconfig toolchain-funcs

DESCRIPTION="simple X display locker (patched)"
HOMEPAGE="https://tools.suckless.org/slock"
SRC_URI="https://dl.suckless.org/tools/${P}.tar.gz"
IUSE="pam"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 hppa x86 ~x86-fbsd"

RDEPEND="
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXrandr
	pam? ( virtual/pam )
"
DEPEND="
	${RDEPEND}
	x11-base/xorg-proto
"

src_prepare() {
	default

	use pam && eapply "${FILESDIR}"/slock-pam_auth-20190207-35633d4.diff

	sed -i \
		-e '/^CFLAGS/{s: -Os::g; s:= :+= :g}' \
		-e '/^CC/d' \
		-e '/^LDFLAGS/{s:-s::g; s:= :+= :g}' \
		config.mk || die
	sed -i \
		-e 's|@${CC}|$(CC)|g' \
		Makefile || die

	if use elibc_FreeBSD; then
		sed -i -e 's/-DHAVE_SHADOW_H//' config.mk || die
	fi

	restore_config config.h

	tc-export CC
}

src_compile() { emake slock; }

src_install() {
	dobin slock
	save_config config.h
}

pkg_postinst() {
	# cap_dac_read_search used to be enough for shadow access
	# but now slock wants to write to /proc/self/oom_score_adj
	# and for that it needs:
	fcaps \
		cap_dac_override,cap_setgid,cap_setuid,cap_sys_resource \
		/usr/bin/slock

	savedconfig_pkg_postinst
}
