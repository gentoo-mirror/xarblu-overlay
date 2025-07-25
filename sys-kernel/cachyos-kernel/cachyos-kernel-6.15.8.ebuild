# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KERNEL_IUSE_GENERIC_UKI=1
KERNEL_IUSE_MODULES_SIGN=1

LLVM_COMPAT=( {17..21} )
LLVM_OPTIONAL=1

inherit eapi9-pipestatus toolchain-funcs flag-o-matic llvm-r2 kernel-build

# https://dev.gentoo.org/~mgorny/dist/linux/
GENTOO_PATCHSET=linux-gentoo-patches-6.15.8
# https://github.com/projg2/gentoo-kernel-config
GENTOO_CONFIG_VER=g16
# https://github.com/CachyOS/linux-cachyos
CONFIG_COMMIT=46c6122575746034fd8d39d9a00eb46a9c65a593
CONFIG_PV="${PV}-${CONFIG_COMMIT::8}"
CONFIG_P="${PN}-${CONFIG_PV}"
# https://github.com/CachyOS/kernel-patches
PATCH_COMMIT=5226fc9a9e65629885db2f1e323dd1d1f589e8e9
PATCH_PV="${PV}-${PATCH_COMMIT::8}"
PATCH_P="${PN}-${PATCH_PV}"

# supported linux-cachyos flavours from CachyOS/linux-cachyos (excl. lts/rc)
FLAVOURS="cachyos bmq bore deckify eevdf rt-bore server"

# RCs only have main flavour
[[ ${PV} == *_rc* ]] && FLAVOURS="cachyos"

# array of patches in format
# <use>:<path/to.patch>
# special use - always applies patch
# applied in this order
CACHY_PATCH_SPECS=(
	# global
	-:all/0001-cachyos-base-all.patch
	# flavours
	cachyos:sched/0001-bore-cachy.patch
	bmq:sched/0001-prjc-cachy.patch
	bore:sched/0001-bore-cachy.patch
	deckify:misc/0001-acpi-call.patch
	deckify:misc/0001-handheld.patch
	deckify:sched/0001-bore-cachy.patch
	hardened:sched/0001-bore-cachy.patch
	hardened:misc/0001-hardened.patch
	rt-bore:sched/0001-bore-cachy.patch
	rt-bore:misc/0001-rt-i915.patch
	# clang
	clang:misc/dkms-clang.patch
)

DESCRIPTION="Linux kernel built with CachyOS and Gentoo patches"
HOMEPAGE="
	https://cachyos.org/
	https://github.com/CachyOS/linux-cachyos/
	https://www.kernel.org/
"

[[ ${PV} != *_rc* ]] && KEYWORDS="~amd64"

# Gentoo patches and config
# the rest will be set via helpers below
SRC_URI="
	https://dev.gentoo.org/~mgorny/dist/linux/${GENTOO_PATCHSET}.tar.xz
	https://github.com/projg2/gentoo-kernel-config/archive/${GENTOO_CONFIG_VER}.tar.gz
		-> gentoo-kernel-config-${GENTOO_CONFIG_VER}.tar.gz
"

IUSE="cfi clang debug lto ${FLAVOURS/cachyos/+cachyos}"
REQUIRED_USE="
	^^ ( ${FLAVOURS} )
	cfi? ( clang )
	lto? ( clang )
	clang? ( ${LLVM_REQUIRED_USE} )
"

BDEPEND="
	clang? ( $(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}=
		llvm-core/lld:${LLVM_SLOT}=
		llvm-core/llvm:${LLVM_SLOT}=
	') )
	debug? ( dev-util/pahole )
"
PDEPEND="
	>=virtual/dist-kernel-${PV}
"

QA_FLAGS_IGNORED="
	usr/src/linux-.*/scripts/gcc-plugins/.*.so
	usr/src/linux-.*/vmlinux
	usr/src/linux-.*/arch/powerpc/kernel/vdso.*/vdso.*.so.dbg
"

# append a list of kernel sources and incremental patches to SRC_URI
# and sets S to the correct directory
kernel_base_env_setup() {
	local kernel_base_src_uris=""
	local kernel_base_version="${PV%.*}"
	local incr target_incr
	local cdn_patch our_incr our_patch
	local -a rc_patches stable_patches
	if [[ "${PV}" == *_rc* ]]; then
		# for RCs fetch the last stable as a base
		kernel_base_version="$(ver_cut 1).$(( $(ver_cut 2) - 1 ))"
		kernel_base_src_uris+="
			https://cdn.kernel.org/pub/linux/kernel/v${kernel_base_version%%.*}.x/linux-${kernel_base_version}.tar.xz
		"

		# then patches from git.kernel.org
		# patches follow genpatches 1000+ convention

		# the big RC1 patch is seperate
		our_patch="1000_linux-${PV%_rc*}-rc1.patch"
		kernel_base_src_uris+="
			https://git.kernel.org/torvalds/p/v${PV%_rc*}-rc1/v${kernel_base_version}
				-> ${our_patch}
		"
		rc_patches+=( "${our_patch}" )

		# then incremental patches between RCs
		incr=2
		target_incr="${PV##*_rc}"
		while (( incr <= target_incr )); do
			# leftpad incr with 0 which allows 1000-1999
			our_incr="1$(printf '%0*d' 3 "$(( incr - 1 ))")"
			our_patch="${our_incr}_linux-${PV%_rc*}-rc${incr}.patch"
			kernel_base_src_uris+="
				https://git.kernel.org/torvalds/p/v${PV%_rc*}-rc${incr}/v${PV%_rc*}-rc$(( incr - 1 ))
					-> ${our_patch}
			"
			rc_patches+=( "${our_patch}" )
			incr=$(( incr + 1 ))
		done
	elif [[ $(ver_cut 3) == 0 ]]; then
		# for initial stable releases we only have the base
		kernel_base_src_uris+="
			https://cdn.kernel.org/pub/linux/kernel/v${kernel_base_version%%.*}.x/linux-${kernel_base_version}.tar.xz
		"
	else
		# for other stable releases we have the base
		kernel_base_src_uris+="
			https://cdn.kernel.org/pub/linux/kernel/v${kernel_base_version%%.*}.x/linux-${kernel_base_version}.tar.xz
		"

		# then patches from cdn.kernel.org
		# patches follow genpatches 1000+ convention

		# the first x.x.1 patch is seperate
		cdn_patch="patch-${kernel_base_version}.1.xz"
		our_patch="1000_linux-${kernel_base_version}.1.patch.xz"
		kernel_base_src_uris+="
			https://cdn.kernel.org/pub/linux/kernel/v${kernel_base_version%%.*}.x/${cdn_patch}
				-> ${our_patch}
		"
		stable_patches+=( "${our_patch}" )

		# then incremental patches between minor versions
		incr=2
		target_incr="$(ver_cut 3)"
		while (( incr <= target_incr )); do
			cdn_patch="patch-${kernel_base_version}.$(( incr - 1 ))-${incr}.xz"
			# leftpad incr with 0 which allows 1000-1999
			our_incr="1$(printf '%0*d' 3 "$(( incr - 1 ))")"
			our_patch="${our_incr}_linux-${kernel_base_version}.${incr}.patch.xz"
			kernel_base_src_uris+="
				https://cdn.kernel.org/pub/linux/kernel/v${kernel_base_version%%.*}.x/incr/${cdn_patch}
					-> ${our_patch}
			"
			stable_patches+=( "${our_patch}" )
			incr=$(( incr + 1 ))
		done
	fi

	declare -g SRC_URI="${SRC_URI} ${kernel_base_src_uris}"
	declare -g S="${WORKDIR}/linux-${kernel_base_version}"
	declare -g RC_PATCHES=( "${rc_patches[@]}" )
	declare -g STABLE_PATCHES=( "${stable_patches[@]%.xz}" )
}

# adds cachyos config sources to SRC_URI
cachy_config_env_setup() {
	local base spec cond patch file flavour
	local cachy_config_uris=""
	base="https://raw.githubusercontent.com/CachyOS/linux-cachyos"
	base+="/${CONFIG_COMMIT}"
	if [[ ${PV} == *_rc* ]]; then
		# RC only has cachyos flavour
		cachy_config_uris+="${base}/linux-cachyos-rc/config -> ${CONFIG_P}-cachyos.config "
	else
		for flavour in ${FLAVOURS}; do
			file="${CONFIG_P}-${flavour}.config"
			if [[ "${flavour}" == "cachyos" ]]; then
				cachy_config_uris+="${flavour}? ( ${base}/linux-cachyos/config -> ${file} ) "
			else
				cachy_config_uris+="${flavour}? ( ${base}/linux-cachyos-${flavour}/config -> ${file} ) "
			fi
		done
	fi
	declare -g SRC_URI="${SRC_URI} ${cachy_config_uris}"
}

# adds cachyos patch sources to SRC_URI
# and sets up IUSE_PATTERN to check if a flag is in IUSE
cachy_patch_env_setup() {
	local -a iuse_arr
	read -r -a iuse_arr <<<"${IUSE}"
	iuse_arr=( "${iuse_arr[@]#+}" )
	local IFS="|"
	declare -g IUSE_PATTERN="${iuse_arr[*]}"
	unset IFS

	local base spec cond patch file
	local cachy_patch_uris=""
	base="https://raw.githubusercontent.com/CachyOS/kernel-patches"
	base+="/${PATCH_COMMIT}/$(ver_cut 1-2)"
	for spec in "${CACHY_PATCH_SPECS[@]}"; do
		IFS=":" read -r cond patch <<<"${spec}"
		file="${PATCH_P}-${patch##*/}"
		if [[ "${cond}" == "-" ]]; then
			cachy_patch_uris+="${base}/${patch} -> ${file} "
		elif [[ "${cond}" =~ ${IUSE_PATTERN} ]]; then
			cachy_patch_uris+="${cond}? ( ${base}/${patch} -> ${file} ) "
		fi
	done
	declare -g SRC_URI="${SRC_URI} ${cachy_patch_uris}"
}

# env setup helpers
kernel_base_env_setup
cachy_config_env_setup
cachy_patch_env_setup

# get the selected flavour from FLAVOURS
cachy_flavour() {
	local flavour
	for flavour in ${FLAVOURS}; do
		if use "${flavour}"; then
			printf -- "%s" "${flavour}" || die
			return 0
		fi
	done
	die "Could not get selected flavour"
}

# get the "cachy name" of the kernel
# as in CachyOS/linux-cachyos repo
cachy_version() {
	case "$(cachy_flavour)" in
		cachyos)
			printf -- "-cachyos" || die
			;;
		*)
			printf -- "-cachyos-%s" "$(cachy_flavour)" || die
			;;
	esac
}

# get the config file name
cachy_base_config() {
	printf -- "%s-%s.config" "${CONFIG_P}" "$(cachy_flavour)" || die
}

# move required patches to ${WORKDIR}/patches
# and ensure they get applied in correct order
cachy_stage_patches() {
	local target="${WORKDIR}/patches"
	einfo "Staging patches to be applied in ${target} ..."
	mkdir -p "${target}" || die

	# RC patches are not compressed and thus in DISTDIR
	if [[ -n "${RC_PATCHES[*]}" ]]; then
		einfo "Staging RC patches"
		pushd "${DISTDIR}" >/dev/null || die
		cp -t "${target}" "${RC_PATCHES[@]}" || die
		popd >/dev/null || die
	fi

	# stable patches are compressed and thus in WORKDIR
	if [[ -n "${STABLE_PATCHES[*]}" ]]; then
		einfo "Staging stable patches"
		pushd "${WORKDIR}" >/dev/null || die
		cp -t "${target}" "${STABLE_PATCHES[@]}" || die
		popd >/dev/null || die
	fi

	# Gentoo patches live in ${WORKDIR}/${GENTOO_PATCHSET}
	einfo "Staging Gentoo patches"
	pushd "${WORKDIR}/${GENTOO_PATCHSET}" >/dev/null || die
	local incr=2000
	local file
	for file in *.patch; do
		cp "${file}" "${target}/${incr}_${file#????-}" || die
		incr=$(( incr + 1 ))

		# we want everything up to the Gentoo KConfig patch
		# everything after it is considered experimental
		# according to gentoo-kernel ebuild
		if [[ "${file}" == *Add-Gentoo-Linux-support-config-settings* ]]; then
			break
		fi
	done
	popd >/dev/null || die

	# cachy patches need to be prefixed starting at 6000
	einfo "Staging Cachy patches"
	local incr=6000
	local spec cond patch file
	for spec in "${CACHY_PATCH_SPECS[@]}"; do
		IFS=":" read -r cond patch <<<"${spec}" || die
		file="${PATCH_P}-${patch##*/}"
		if [[ "${cond}" == "-" ]]; then
			true
		elif [[ "${cond}" =~ ${IUSE_PATTERN} ]] && use "${cond}"; then
			true
		else
			continue
		fi
		cp "${DISTDIR}/${file}" "${target}/${incr}_${file}" || die
		incr=$(( incr + 1 ))
	done

	# extra patches
	if [[ "$(cachy_flavour)" == deckify ]]; then
		# handheld.patch makes ath11k_pci use QCA206X firmware
		# this firmware A) is annoying to find and B) simply doesn't work
		cp -t "${target}" "${FILESDIR}/7000_revert-ath11k-firmware.patch" || die
	fi
}

# eapply-like wrapper for patch
cachy_apply() {
	local failed patch_cmd=patch
	local -x LC_COLLATE=POSIX

	# for bsd userland support, use gpatch if available
	type -P gpatch > /dev/null && patch_cmd=gpatch

	# final argument is directory containing patches
	# all previous args are passed to patch
	local -a patch_args
	local patch_dir
	while (( ${#} > 1 )); do
		patch_args+=( "${1}" ); shift
	done
	patch_dir="${1}"; shift

	# we always want to apply the full staged directory
	[[ ! -d "${patch_dir}" ]] && die "${patch_dir} is not a directory"

	# default args from /usr/lib/portage/pypy3.11/phase-helpers.sh
	# + cachy PKGBUILD --forward + user args
	local all_patch_args=(
		-p1 -f -g0 --no-backup-if-mismatch -s
		--forward "${patch_args[@]}"
	)

	local file
	local -a patches
	for file in "${patch_dir}"/*; do
		if [[ "${file}" != *.patch ]]; then
			eqawarn "Not a patch file: ${file}"
		else
			patches+=( "${file}" )
		fi
	done

	if (( ${#patches[@]} == 0 )); then
		die "No patch files in ${patch_dir}"
	fi

	for file in "${patches[@]}"; do
		ebegin "Applying ${file##*/}"
		${patch_cmd} "${all_patch_args[@]}" < "${file}"
		failed=${?}
		if ! eend "${failed}"; then
			die "${patch_cmd} ${all_patch_args[*]} failed with ${file}"
		fi
	done
}

# auto-detect closest march value
cachy_processor_opt() {
	# not supported but in case someone
	# builds on non amd64 return default
	if ! use amd64; then
		printf "GENERIC"
		return 0
	fi

	# apply X86_NATIVE_CPU if we have -march=native
	if [[ "$(get-flag march)" == native ]]; then
		printf "NATIVE"
		return 0
	fi

	# get closest march for others
	# mostly shameless rip from qt6-build.eclass
	local march=$(
		$(tc-getCC) -E -P ${CFLAGS} ${CPPFLAGS} - <<-EOF | tail -n 1
			default
			#if (__CRC32__ + __LAHF_SAHF__ + __POPCNT__ + __SSE3__ + __SSE4_1__ + __SSE4_2__ + __SSSE3__) == 7
			x86-64-v2
			#  if (__AVX__ + __AVX2__ + __BMI__ + __BMI2__ + __F16C__ + __FMA__ + __LZCNT__ + __MOVBE__ + __XSAVE__) == 9
			x86-64-v3
			#    if (__AVX512BW__ + __AVX512CD__ + __AVX512DQ__ + __AVX512F__ + __AVX512VL__ + __EVEX256__ + __EVEX512__) == 7
			x86-64-v4
			#    endif
			#  endif
			#endif
		EOF
		pipestatus || die
	)
	case "${march}" in
		default) printf "GENERIC_V1";;
		x86-64-v2) printf "GENERIC_V2";;
		x86-64-v3) printf "GENERIC_V3";;
		x86-64-v4) printf "GENERIC_V4";;
		*) die "Got unknown march: ${march}";;
	esac
}

# print formatted kernel config line
# $1 can be one of set, unset, mod or val
# $2 config name as in CONFIG_<name>
# $3 if $1 is val set val as a config string
kconf() {
	if (( $# < 2 )); then
		die "kconf needs at least 2 args"
	fi
	case "$1" in
		set)
			printf -- "CONFIG_%s=y\n" "${2}" || die
			;;
		unset)
			printf -- "# CONFIG_%s is not set\n" "${2}" || die
			;;
		mod)
			printf -- "CONFIG_%s=m\n" "${2}" || die
			;;
		val)
			if [[ -z "${3}" ]]; then
				die "kconf val requires a value"
			fi
			printf -- "CONFIG_%s=%s\n" "${2}" "${3}" || die
			;;
		*)
			die "invalid option $1 for kconf"
			;;
	esac
}

# config defaults from CachyOS PKGBUILD
cachy_use_config() {
	# cachy config vars (only those that make sense in ebuild)
	# advanced users can override these with package.env
	case "$(cachy_flavour)" in
		cachyos)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=cachyos}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		bmq)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=bmq}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		bore)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=bore}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		deckify)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=cachyos}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		eevdf)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=eevdf}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		hardened)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=hardened}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=madvise}"
			;;
		rt-bore)
			: "${_cachy_config:=yes}"
			: "${_cpusched:=rt-bore}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=1000}"
			: "${_tickrate:=full}"
			: "${_preempt:=full}"
			: "${_hugepage:=always}"
			;;
		server)
			: "${_cachy_config:=no}"
			: "${_cpusched:=eevdf}"
			: "${_cc_harder:=yes}"
			: "${_per_gov:=no}"
			: "${_tcp_bbr3:=no}"
			: "${_HZ_ticks:=300}"
			: "${_tickrate:=idle}"
			: "${_preempt:=none}"
			: "${_hugepage:=always}"
			;;
		*) die "Unknown flavour" ;;
	esac

	: "${_processor_opt:="$(cachy_processor_opt)"}"

	if use cfi; then
		: "${_use_kcfi:=yes}"
	else
		: "${_use_kcfi:=no}"
	fi

	if use lto; then
		: "${_use_llvm_lto:=thin}"
	else
		: "${_use_llvm_lto:=none}"
	fi

	# print cachy config
	einfo "Selected cachy-config:"
	einfo "  _cachy_config=${_cachy_config}"
	einfo "  _cpusched=${_cpusched}"
	einfo "  _cc_harder=${_cc_harder}"
	einfo "  _per_gov=${_per_gov}"
	einfo "  _tcp_bbr3=${_tcp_bbr3}"
	einfo "  _HZ_ticks=${_HZ_ticks}"
	einfo "  _tickrate=${_tickrate}"
	einfo "  _preempt=${_preempt}"
	einfo "  _hugepage=${_hugepage}"
	einfo "  _processor_opt=${_processor_opt}"
	einfo "  _use_kcfi=${_use_kcfi}"
	einfo "  _use_llvm_lto=${_use_llvm_lto}"

	# _processor_opt
	local MARCH="${_processor_opt^^}"
	case "${MARCH}" in
		GENERIC) ;;
		GENERIC_V[1-4])
			kconf set GENERIC_CPU
			kconf unset MZEN4
			kconf unset X86_NATIVE_CPU
			kconf val X86_64_VERSION "${MARCH#GENERIC_V}"
			;;
		ZEN4)
			kconf unset GENERIC_CPU
			kconf set MZEN4
			kconf unset X86_NATIVE_CPU
			;;
		NATIVE)
			kconf unset GENERIC_CPU
			kconf unset MZEN4
			kconf set X86_NATIVE_CPU
			;;
		*) die "Invalid _processor_opt value: ${_processor_opt}" ;;
	esac

	# _cachy_config
	case "${_cachy_config}" in
		yes)
			kconf set CACHY
			;;
		no)	;;
		*) die "Invalid _cachy_config value: ${_cachy_config}" ;;
	esac

	# _cpusched
	case "${_cpusched}" in
		cachyos|bore|hardened)
			kconf set SCHED_BORE
			;;
		bmq)
			kconf set SCHED_ALT
			kconf set SCHED_BMQ
			;;
		eevdf) ;;
		rt)
			kconf set PREEMPT_RT
			;;
		rt-bore)
			kconf set SCHED_BORE
			kconf set PREEMPT_RT
			;;
		*) die "Invalid _cpusched value: ${_cpusched}" ;;
	esac

	# _use_kcfi
	case "${_use_kcfi}" in
		yes)
			kconf set ARCH_SUPPORTS_CFI_CLANG
			kconf set CFI_CLANG
			kconf set CFI_AUTO_DEFAULT
			;;
		no) ;;
		*) die "Invalid _use_kcfi value: ${_use_kcfi}" ;;
	esac

	# _use_llvm_lto
	case "${_use_llvm_lto}" in
		thin)
			kconf set LTO_CLANG_THIN
			;;
		full)
			kconf set LTO_CLANG_FULL
			;;
		none)
			kconf set LTO_NONE
			;;
		*) die "Invalid _use_llvm_lto value: ${_use_llvm_lto}" ;;
	esac

	# _HZ_ticks
	case "${_HZ_ticks}" in
		100|250|500|600|750|1000)
			kconf unset HZ_300
			kconf set "HZ_${_HZ_ticks}"
			kconf val HZ "${_HZ_ticks}"
			;;
		300)
			kconf set HZ_300
			kconf val HZ 300
			;;
		*) die "Invalid _HZ_ticks value: ${_HZ_ticks}" ;;
	esac

	# _per_gov
	case "${_per_gov}" in
		yes)
			kconf unset CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
			kconf set CPU_FREQ_DEFAULT_GOV_PERFORMANCE
			;;
		no) ;;
		*) die "Invalid _per_gov value: ${_per_gov}" ;;
	esac

	# _tickrate
	case "${_tickrate}" in
		periodic)
			kconf unset NO_HZ_IDLE
			kconf unset NO_HZ_FULL
			kconf unset NO_HZ
			kconf unset NO_HZ_COMMON
			kconf set HZ_PERIODIC
			;;
		idle)
			kconf unset HZ_PERIODIC
			kconf unset NO_HZ_FULL
			kconf set NO_HZ_IDLE
			kconf set NO_HZ
			kconf set NO_HZ_COMMON
			;;
		full)
			kconf unset HZ_PERIODIC
			kconf unset NO_HZ_IDLE
			kconf unset CONTEXT_TRACKING_FORCE
			kconf set NO_HZ_FULL_NODEF
			kconf set NO_HZ_FULL
			kconf set NO_HZ
			kconf set NO_HZ_COMMON
			kconf set CONTEXT_TRACKING
			;;
		*) die "Invalid _tickrate value: ${_tickrate}" ;;
	esac

	# _preempt
	if [[ "${_cpusched}" != rt* ]]; then
		case "${_preempt}" in
			full)
				kconf set PREEMPT_DYNAMIC
				kconf set PREEMPT
				kconf unset PREEMPT_VOLUNTARY
				kconf unset PREEMPT_LAZY
				kconf unset PREEMPT_NONE
				;;
			lazy)
				kconf set PREEMPT_DYNAMIC
				kconf unset PREEMPT
				kconf unset PREEMPT_VOLUNTARY
				kconf set PREEMPT_LAZY
				kconf unset PREEMPT_NONE
				;;
			voluntary)
				kconf unset PREEMPT_DYNAMIC
				kconf unset PREEMPT
				kconf set PREEMPT_VOLUNTARY
				kconf unset PREEMPT_LAZY
				kconf unset PREEMPT_NONE
				;;
			none)
				kconf unset PREEMPT_DYNAMIC
				kconf unset PREEMPT
				kconf unset PREEMPT_VOLUNTARY
				kconf unset PREEMPT_LAZY
				kconf set PREEMPT_NONE
				;;
			*) die "Invalid _preempt value: ${_preempt}" ;;
		esac
	fi

	# _cc_harder
	case "${_cc_harder}" in
		yes)
			kconf unset CC_OPTIMIZE_FOR_PERFORMANCE
			kconf set CC_OPTIMIZE_FOR_PERFORMANCE_O3
			;;
		no) ;;
		*) die "Invalid _cc_harder value: ${_cc_harder}" ;;
	esac

	# _tcp_bbr3
	case "${_tcp_bbr3}" in
		yes)
			kconf mod TCP_CONG_CUBIC
			kconf unset DEFAULT_CUBIC
			kconf set TCP_CONG_BBR
			kconf val DEFAULT_TCP_CONG "\"bbr\""
			if ! use server; then
				kconf mod NET_SCH_FQ_CODEL
				kconf set NET_SCH_FQ
				kconf unset CONFIG_DEFAULT_FQ_CODEL
				kconf set CONFIG_DEFAULT_FQ
			fi
			;;
		no)	;;
		*) die "Invalid _tcp_bbr3 value: ${_tcp_bbr3}" ;;
	esac

	# _hugepage
	case "${_hugepage}" in
		always)
			kconf unset TRANSPARENT_HUGEPAGE_MADVISE
			kconf set TRANSPARENT_HUGEPAGE_ALWAYS
			;;
		madvise)
			kconf unset TRANSPARENT_HUGEPAGE_ALWAYS
			kconf set TRANSPARENT_HUGEPAGE_MADVISE
			;;
		*) die "Invalid _hugepage value: ${_hugepage}" ;;
	esac

	# _user_ns
	kconf set USER_NS
}

pkg_setup() {
	if [[ "${MERGE_TYPE}" != binary ]] && use clang; then
		# tools passed as MAKEARGS in kernel-build.eclass
		einfo "Forcing LLVM toolchain due to USE=clang"
		declare -g AS="llvm-as"
		declare -g CC="clang"
		declare -g LD="ld.lld"
		declare -g AR="llvm-ar"
		declare -g NM="llvm-nm"
		declare -g STRIP="llvm-strip"
		declare -g OBJCOPY="llvm-objcopy"
		declare -g OBJDUMP="llvm-objdump"
		declare -g READELF="llvm-readelf"
		# explicit prepend_path to ensure vars point to correct version
		llvm_prepend_path -b "${LLVM_SLOT}"
		llvm-r2_pkg_setup
		einfo "AS: ${AS}"
		einfo "CC: ${CC}"
		einfo "LD: ${LD}"
		einfo "AR: ${AR}"
		einfo "NM: ${NM}"
		einfo "STRIP: ${STRIP}"
		einfo "OBJCOPY: ${OBJCOPY}"
		einfo "OBJDUMP: ${OBJDUMP}"
		einfo "READELF: ${READELF}"
	fi
	kernel-build_pkg_setup
}

src_prepare() {
	# prepare and stage patches
	cachy_stage_patches

	# remove problematic patches

	# apply package and user patches
	# eapply silently passes -F0 for some reason so we
	# have to use our own patch wrapper
	# (see /usr/lib/portage/pypy3.11/phase-helpers.sh)
	cachy_apply "${WORKDIR}/patches"
	eapply_user

	# Localversion
	kconf val LOCALVERSION "\"$(cachy_version)\"" > "${T}/version.config" || die

	# CachyOS config as base
	cp "${DISTDIR}/$(cachy_base_config)" .config || die

	# Package defaults
	cachy_use_config > "${T}/cachy-flavour-defaults.config" || die

	# Gentoo defaults
	local dist_conf_path="${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"

	local merge_configs=(
		"${T}/version.config"
		"${dist_conf_path}/base.config"
		"${dist_conf_path}/6.12+.config"
		"${T}/cachy-flavour-defaults.config"
	)
	use debug || merge_configs+=(
		"${dist_conf_path}/no-debug.config"
	)

	use secureboot && merge_configs+=( "${dist_conf_path}/secureboot.config" )

	kernel-build_merge_configs "${merge_configs[@]}"
}

pkg_postinst() {
	kernel-build_pkg_postinst

	# print info for included modules
	if has_version media-video/v4l2loopback; then
		elog "v4l2loopback is included in ${CATEGORY}/${PN} - no need for media-video/v4l2loopback"
	fi
}
