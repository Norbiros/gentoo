# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=PTC
DIST_VERSION=0.52
inherit perl-module

DESCRIPTION="Dispatcher module for command line interface programs"

SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="test"
RESTRICT="!test? ( test )"

PATCHES=("${FILESDIR}/${PN}-0.50-authortests.patch")
PERL_RM_FILES=(
	"t/03-pod.t"
	"t/99-kwalitee.t"
)
RDEPEND="
	dev-perl/Capture-Tiny
	virtual/perl-Carp
	dev-perl/Class-Load
	>=virtual/perl-Getopt-Long-2.350.0
	virtual/perl-Pod-Simple
	virtual/perl-Scalar-List-Utils
"
BDEPEND="${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
	test? (
		virtual/perl-Test-Simple
	)
"
