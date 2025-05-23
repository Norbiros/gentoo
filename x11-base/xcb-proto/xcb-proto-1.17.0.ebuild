# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
XORG_MODULE=proto/

inherit python-r1 xorg-3

DESCRIPTION="X C-language Bindings protocol headers"
HOMEPAGE="https://xcb.freedesktop.org/ https://gitlab.freedesktop.org/xorg/proto/xcbproto"
EGIT_REPO_URI="https://gitlab.freedesktop.org/xorg/proto/xcbproto.git"

KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# DEPEND=""
RDEPEND="
	${PYTHON_DEPS}
"
BDEPEND="
	${PYTHON_DEPS}
	dev-libs/libxml2
"

ECONF_SOURCE="${S}"

src_configure() {
	# Don't use Python to find sitedir here.
	PYTHON=true default
}

src_compile() {
	:
}

xcbgen_install() {
	# Use eclass to find sitedir instead.
	emake -C xcbgen install DESTDIR="${D}" pythondir="$(python_get_sitedir)"
	python_optimize
}

src_install() {
	# Restrict SUBDIRS to prevent xcbgen with empty sitedir.
	emake install DESTDIR="${D}" SUBDIRS=src
	python_foreach_impl xcbgen_install
}
