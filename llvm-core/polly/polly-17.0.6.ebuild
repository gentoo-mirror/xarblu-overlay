# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit cmake llvm llvm.org python-any-r1

DESCRIPTION="Polyhedral optimizations for LLVM"
HOMEPAGE="https://polly.llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions UoI-NCSA"
SLOT="${LLVM_MAJOR}/${LLVM_SOABI}"
KEYWORDS="amd64 arm arm64 ~loong ppc ppc64 ~riscv sparc x86 ~amd64-linux ~arm64-macos ~ppc-macos ~x64-macos"
IUSE="debug test"
RESTRICT="!test? ( test )"

# upstream says to build against the exact same version
# but just depending on LLVM_MAJOR should be fine since we build
# a shared library + this avoids circular dependencies unless it's
# a major version upgrade
DEPEND="
	llvm-core/llvm:${LLVM_MAJOR}=
"
RDEPEND="${DEPENDS}"
BDEPEND="
	test? (
		$(python_gen_any_dep ">=dev-python/lit-${PV}[\${PYTHON_USEDEP}]")
	)
"

LLVM_COMPONENTS=( polly cmake )
llvm.org_set_globals

python_check_deps() {
	python_has_version ">=dev-python/lit-${PV}[${PYTHON_USEDEP}]"
}

pkg_setup() {
	LLVM_MAX_SLOT=${LLVM_MAJOR} llvm_pkg_setup
	use test && python-any-r1_pkg_setup
}

src_prepare() {
	# prepend the newly built test binaries
	if use test; then
		local polly_test_bin="${WORKDIR}/${PN}_build/bin"
		sed -i -E -e "s|^(llvm_config.add_tool_substitutions\(tool_patterns)|\1,\[\'${polly_test_bin}\',llvm_config.config.llvm_tools_dir\]|" test/lit.cfg || die "sed: couldn't add test bin search dir"
	fi
	eapply_user
	cmake_src_prepare
}

src_configure() {
	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"

	local mycmakeargs=(
		-DLLVM_POLLY_LINK_INTO_TOOLS=OFF
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}"
	)
	use test && mycmakeargs+=(
		-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
		-DLLVM_LIT_ARGS="$(get_lit_flags)"
		-DPython3_EXECUTABLE="${PYTHON}"
	)
	cmake_src_configure
}

src_test() {
	local -x LIT_PRESERVES_TMP=1
	cmake_build check-polly
}

pkg_postinst() {
	elog "To use the clang plugin add the following flag:"
	elog "  \"-fplugin=LLVMPolly.so\""
	elog "Then pass polly args via (examples):"
	elog "  \"-mllvm -polly\""
}
