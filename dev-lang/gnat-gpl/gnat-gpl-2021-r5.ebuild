# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PATCH_GCC_VER=10.3.0
PATCH_VER="4"

TOOLCHAIN_GCC_PV=10.3.1

REL=10
MYP=gcc-${REL}-${PV}-20210519-19A74-src
GNATDIR=gnat-${PV}-20210519-19A70-src
INTFDIR=gcc-interface-${REL}-${PV}-20210519-19A75-src

BTSTRP_X86=gnat-gpl-2014-x86-linux-bin
BTSTRP_AMD64=gnat-gpl-2014-x86_64-linux-bin
BASE_URI=https://community.download.adacore.com/v1
# we provide own tarball below
GCC_TARBALL_SRC_URI="
	${BASE_URI}/005d2b2eff627177986d2517eb31e1959bec6f3a?filename=${GNATDIR}.tar.gz
		-> ${GNATDIR}.tar.gz
	${BASE_URI}/44cd393be0b468cc253bf2cf9cf7804c993e7b5b?filename=${MYP}.tar.gz
		-> ${MYP}.tar.gz
	${BASE_URI}/8ace7d06e469d36d726cc8badb0ed78411e727f3?filename=${INTFDIR}.tar.gz
		-> ${INTFDIR}.tar.gz
	!system-bootstrap? (
		amd64? (
			${BASE_URI}/6eb6eef6bb897e4c743a519bfebe0b1d6fc409c6?filename=${BTSTRP_AMD64}.tar.gz&rand=1193
			-> ${BTSTRP_AMD64}.tar.gz
		)
		x86? (
			${BASE_URI}/c5e9e6fdff5cb77ed90cf8c62536653e27c0bed6?filename=${BTSTRP_X86}.tar.gz&rand=436
			-> ${BTSTRP_X86}.tar.gz
		)
	)"

inherit flag-o-matic toolchain-funcs toolchain

DESCRIPTION="GNAT Ada Compiler - GPL version"
HOMEPAGE="http://libre.adacore.com/"
S="${WORKDIR}"/${MYP}

LICENSE+=" GPL-2 GPL-3"
KEYWORDS="amd64 x86"
IUSE="+ada system-bootstrap"
RESTRICT="test"

RDEPEND="!=sys-devel/gcc-${TOOLCHAIN_GCC_PV}*"
BDEPEND=sys-devel/binutils

pkg_pretend() {
	toolchain_pkg_pretend
	if tc-is-clang; then
		die "${P} does not build with clang. It is bootstrapped."
	fi
}

src_prepare() {
	if use amd64; then
		BTSTRP=${BTSTRP_AMD64}
	else
		BTSTRP=${BTSTRP_X86}
	fi

	if ! use system-bootstrap; then
		GCC="${WORKDIR}"/${BTSTRP}/bin/gcc
	else
		GCC=${ADA:-$(tc-getCC)}
	fi

	gnatbase=$(basename ${GCC})
	gnatpath=$(dirname ${GCC})

	GNATMAKE=${gnatbase/gcc/gnatmake}
	if [[ ${gnatpath} != "." ]] ; then
		GNATMAKE="${gnatpath}/${GNATMAKE}"
	fi

	if use system-bootstrap && [[ -z "$(type ${GNATMAKE} 2>/dev/null)" ]] ; then
		eerror "You need a gcc compiler that provides the Ada Compiler:"
		eerror "1) use gcc-config to select the right compiler or"
		eerror "2) disable the system-bootstrap use flag or"
		eerror "3) set ADA to a working gcc ada compiler"
		die "ada compiler not available"
	fi

	local bundledchost=""
	use amd64 && local bundledchost="x86_64"
	use x86 && local bundledchost="i686"
	if ! use system-bootstrap; then
		rm "${WORKDIR}"/${BTSTRP}/libexec/gcc/${bundledchost}-pc-linux-gnu/4.7.4/ld \
			|| die
		ln -s /usr/bin/$CHOST-ld \
			"${WORKDIR}"/${BTSTRP}/libexec/gcc/${bundledchost}-pc-linux-gnu/4.7.4/ld \
			|| die
		rm "${WORKDIR}"/${BTSTRP}/libexec/gcc/${bundledchost}-pc-linux-gnu/4.7.4/as \
			|| die
		ln -s /usr/bin/$CHOST-as \
			"${WORKDIR}"/${BTSTRP}/libexec/gcc/${bundledchost}-pc-linux-gnu/4.7.4/as \
			|| die
	fi

	CC=${GCC}
	CXX="${gnatbase/gcc/g++}"
	GNATBIND="${gnatbase/gcc/gnatbind}"
	GNATLINK="${gnatbase/gcc/gnatlink}"
	GNATLS="${gnatbase/gcc/gnatls}"
	if [[ ${gnatpath} != "." ]] ; then
		CXX="${gnatpath}/${CXX}"
		GNATBIND="${gnatpath}/${GNATBIND}"
		GNATLINK="${gnatpath}/${GNATLINK}"
		GNATLS="${gnatpath}/${GNATLS}"
	fi
	mkdir bin || die
	ln -s $(type -P ${GCC}) bin/gcc || die
	ln -s $(type -P ${CXX}) bin/g++ || die
	ln -s $(type -P ${GNATMAKE}) bin/gnatmake || die
	ln -s $(type -P ${GNATBIND}) bin/gnatbind || die
	ln -s $(type -P ${GNATLINK}) bin/gnatlink || die
	ln -s $(type -P ${GNATLS}) bin/gnatls || die
	ln -s $(type -P ${GCC}) bin/${bundledchost}-pc-linux-gnu-gcc || die
	ln -s $(type -P ${CXX}) bin/${bundledchost}-pc-linux-gnu-g++ || die
	ln -s $(type -P ${GNATMAKE}) bin/${bundledchost}-pc-linux-gnu-gnatmake || die
	ln -s $(type -P ${GNATBIND}) bin/${bundledchost}-pc-linux-gnu-gnatbind || die
	ln -s $(type -P ${GNATLINK}) bin/${bundledchost}-pc-linux-gnu-gnatlink || die
	ln -s $(type -P ${GNATLS}) bin/${bundledchost}-pc-linux-gnu-gnatls || die

	cd ..
	mv ${GNATDIR}/src/ada ${MYP}/gcc/ || die
	mv ${INTFDIR} ${MYP}/gcc/ada/gcc-interface || die
	eapply "${FILESDIR}"/${P}-gentoo.patch
	cd -
	sed -i \
		-e 's:-fcf-protection":":' \
		libiberty/configure \
		lto-plugin/configure || die
	sed -i \
		-e 's:$(P) ::g' \
		gcc/ada/gcc-interface/Makefile.in \
		|| die "sed failed"
	toolchain_src_prepare
}

src_configure() {
	export PATH=${PWD}/bin:${PATH}

	# This version is GCC 4.7.4 with a bolted-on newer GNAT; be very
	# conservative, we just want it to build for bootstrapping proper
	# sys-devel/gcc[ada]. We don't need it to be fast.
	strip-flags
	CC="${WORKDIR}"/${BTSTRP}/bin/gcc CXX="${WORKDIR}"/${BTSTRP}/bin/g++ strip-unsupported-flags
	CC="${WORKDIR}"/${GNATDIR}/bin/gcc CXX="${WORKDIR}"/${GNATDIR}/bin/g++ strip-unsupported-flags
	strip-unsupported-flags
	filter-lto
	append-flags -O2
	append-flags -fno-strict-aliasing
	downgrade_arch_flags "$(gcc-version)"

	toolchain_src_configure
}

pkg_postinst() {
	toolchain_pkg_postinst
	einfo "This provide the GNAT compiler with gcc for ada/c/c++ and more"
	einfo "The compiler binary is ${CTARGET}-gcc-${TOOLCHAIN_GCC_PV}"
	einfo "Even if the c/c++ compilers are using almost the same patched"
	einfo "source as the sys-devel/gcc package its use is not extensively"
	einfo "tested, and not supported for updating your system, except for ada"
	einfo "related packages"
}
