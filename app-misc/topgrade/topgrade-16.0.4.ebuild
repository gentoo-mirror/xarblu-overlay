# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Autogenerated by pycargoebuild 0.14.0

EAPI=8

CRATES="
	addr2line@0.21.0
	adler@1.0.2
	aho-corasick@1.1.3
	android-tzdata@0.1.1
	android_system_properties@0.1.5
	anstream@0.6.14
	anstyle-parse@0.2.4
	anstyle-query@1.1.0
	anstyle-wincon@3.0.3
	anstyle@1.0.7
	arc-swap@1.7.1
	async-broadcast@0.7.1
	async-channel@2.3.1
	async-executor@1.12.0
	async-fs@2.1.2
	async-io@2.3.3
	async-lock@3.4.0
	async-process@2.2.3
	async-recursion@1.1.1
	async-signal@0.2.8
	async-task@4.7.1
	async-trait@0.1.80
	atomic-waker@1.1.2
	autocfg@1.3.0
	backtrace@0.3.71
	base64@0.21.7
	base64@0.22.1
	base64ct@1.6.0
	bitflags@1.3.2
	bitflags@2.5.0
	block-buffer@0.10.4
	block@0.1.6
	blocking@1.6.1
	bstr@1.9.1
	bumpalo@3.16.0
	byteorder@1.5.0
	bytes@1.6.0
	cc@1.2.16
	cfg-if@1.0.0
	cfg_aliases@0.1.1
	cfg_aliases@0.2.1
	chrono@0.4.38
	clap@4.5.7
	clap_builder@4.5.7
	clap_complete@4.5.5
	clap_derive@4.5.5
	clap_lex@0.7.1
	clap_mangen@0.2.21
	color-eyre@0.6.3
	color-spantrace@0.2.1
	colorchoice@1.0.1
	concurrent-queue@2.5.0
	console@0.15.8
	const-oid@0.9.6
	const-random-macro@0.1.16
	const-random@0.1.18
	core-foundation-sys@0.8.7
	cpufeatures@0.2.12
	crc32fast@1.4.2
	crossbeam-deque@0.8.5
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.20
	crunchy@0.2.2
	crypto-common@0.1.6
	curve25519-dalek-derive@0.1.1
	curve25519-dalek@4.1.3
	der@0.7.9
	deranged@0.3.11
	digest@0.10.7
	dirs-next@2.0.0
	dirs-sys-next@0.1.2
	dirs-sys@0.4.1
	dirs-sys@0.5.0
	dirs@5.0.1
	dirs@6.0.0
	displaydoc@0.2.4
	dlv-list@0.5.2
	ed25519-dalek@2.1.1
	ed25519@2.2.3
	either@1.12.0
	encode_unicode@0.3.6
	endi@1.1.0
	enumflags2@0.7.10
	enumflags2_derive@0.7.10
	equivalent@1.0.1
	errno@0.3.9
	etcetera@0.8.0
	event-listener-strategy@0.5.2
	event-listener@5.3.1
	eyre@0.6.12
	fastrand@1.9.0
	fastrand@2.1.0
	fiat-crypto@0.2.9
	filetime@0.2.23
	flate2@1.0.30
	fnv@1.0.7
	form_urlencoded@1.2.1
	futures-channel@0.3.30
	futures-core@0.3.30
	futures-executor@0.3.30
	futures-io@0.3.30
	futures-lite@2.3.0
	futures-macro@0.3.30
	futures-sink@0.3.30
	futures-task@0.3.30
	futures-util@0.3.30
	futures@0.3.30
	generic-array@0.14.7
	getrandom@0.2.15
	gimli@0.28.1
	glob@0.3.1
	globset@0.4.14
	globwalk@0.8.1
	hashbrown@0.12.3
	hashbrown@0.14.5
	heck@0.5.0
	hermit-abi@0.3.9
	hex@0.4.3
	home@0.5.9
	http-body-util@0.1.2
	http-body@1.0.0
	http@1.1.0
	httparse@1.9.3
	hyper-rustls@0.26.0
	hyper-util@0.1.5
	hyper@1.3.1
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.60
	icu_collections@1.5.0
	icu_locid@1.5.0
	icu_locid_transform@1.5.0
	icu_locid_transform_data@1.5.0
	icu_normalizer@1.5.0
	icu_normalizer_data@1.5.0
	icu_properties@1.5.0
	icu_properties_data@1.5.0
	icu_provider@1.5.0
	icu_provider_macros@1.5.0
	idna@1.0.0
	ignore@0.4.22
	indenter@0.3.3
	indexmap@1.9.3
	indexmap@2.2.6
	indicatif@0.17.8
	instant@0.1.13
	ipnet@2.9.0
	is_terminal_polyfill@1.70.0
	itoa@1.0.11
	jetbrains-toolbox-updater@5.0.0
	js-sys@0.3.69
	json@0.12.4
	lazy_static@1.4.0
	libc@0.2.172
	libredox@0.1.3
	linked-hash-map@0.5.6
	linux-raw-sys@0.4.14
	litemap@0.7.3
	log@0.4.21
	mac-notification-sys@0.6.1
	malloc_buf@0.0.6
	matchers@0.1.0
	memchr@2.7.2
	memoffset@0.9.1
	merge@0.1.0
	merge_derive@0.1.0
	mime@0.3.17
	miniz_oxide@0.7.3
	mio@0.8.11
	nix@0.28.0
	nix@0.29.0
	normpath@1.2.0
	notify-rust@4.11.0
	ntapi@0.4.1
	nu-ansi-term@0.46.0
	num-conv@0.1.0
	num-traits@0.2.19
	num_cpus@1.16.0
	number_prefix@0.4.0
	objc-foundation@0.1.1
	objc2-core-foundation@0.3.0
	objc@0.2.7
	objc_id@0.1.1
	object@0.32.2
	once_cell@1.19.0
	option-ext@0.2.0
	ordered-multimap@0.7.3
	ordered-stream@0.2.0
	overload@0.1.1
	owo-colors@3.5.0
	parking@2.2.0
	parselnk@0.1.1
	percent-encoding@2.3.1
	pin-project-internal@1.1.5
	pin-project-lite@0.2.14
	pin-project@1.1.5
	pin-utils@0.1.0
	piper@0.2.3
	pkcs8@0.10.2
	polling@3.7.1
	portable-atomic@1.6.0
	powerfmt@0.2.0
	ppv-lite86@0.2.17
	proc-macro-crate@3.1.0
	proc-macro-error-attr@1.0.4
	proc-macro-error@1.0.4
	proc-macro2@1.0.94
	quick-xml@0.23.1
	quick-xml@0.31.0
	quote@1.0.36
	rand@0.8.5
	rand_chacha@0.3.1
	rand_core@0.6.4
	redox_syscall@0.4.1
	redox_users@0.4.5
	redox_users@0.5.0
	regex-automata@0.1.10
	regex-automata@0.4.7
	regex-split@0.1.0
	regex-syntax@0.6.29
	regex-syntax@0.8.4
	regex@1.10.5
	reqwest@0.12.4
	ring@0.17.13
	roff@0.2.1
	rust-i18n-macro@3.0.0
	rust-i18n-support@3.0.1
	rust-i18n@3.0.1
	rust-ini@0.21.0
	rustc-demangle@0.1.24
	rustc_version@0.4.0
	rustix@0.38.34
	rustls-pemfile@2.1.2
	rustls-pki-types@1.7.0
	rustls-webpki@0.102.4
	rustls@0.22.4
	rustversion@1.0.17
	ryu@1.0.18
	same-file@1.0.6
	self-replace@1.3.7
	self_update@0.40.0
	semver@1.0.23
	serde@1.0.203
	serde_derive@1.0.203
	serde_json@1.0.117
	serde_repr@0.1.19
	serde_spanned@0.6.6
	serde_urlencoded@0.7.1
	serde_yaml@0.8.26
	sha1@0.10.6
	sha2@0.10.8
	sharded-slab@0.1.7
	shell-words@1.1.0
	shellexpand@3.1.0
	shlex@1.3.0
	signal-hook-registry@1.4.2
	signature@2.2.0
	slab@0.4.9
	smallvec@1.13.2
	socket2@0.5.7
	spki@0.7.3
	stable_deref_trait@1.2.0
	static_assertions@1.1.0
	strsim@0.11.1
	strum@0.26.2
	strum_macros@0.26.4
	subtle@2.5.0
	syn@1.0.109
	syn@2.0.99
	sync_wrapper@0.1.2
	synstructure@0.13.1
	sys-locale@0.3.1
	sysinfo@0.34.2
	tar@0.4.41
	tauri-winrt-notification@0.2.1
	tempfile@3.10.1
	thiserror-impl@1.0.61
	thiserror-impl@2.0.12
	thiserror@1.0.61
	thiserror@2.0.12
	thread_local@1.1.8
	time-core@0.1.2
	time-macros@0.2.18
	time@0.3.36
	tiny-keccak@2.0.2
	tinystr@0.7.6
	tokio-rustls@0.25.0
	tokio@1.38.2
	toml@0.7.8
	toml@0.8.14
	toml_datetime@0.6.6
	toml_edit@0.19.15
	toml_edit@0.21.1
	toml_edit@0.22.14
	tower-layer@0.3.2
	tower-service@0.3.2
	tower@0.4.13
	tracing-attributes@0.1.27
	tracing-core@0.1.32
	tracing-error@0.2.0
	tracing-log@0.2.0
	tracing-subscriber@0.3.18
	tracing@0.1.40
	trim-in-place@0.1.7
	triomphe@0.1.13
	try-lock@0.2.5
	typenum@1.17.0
	uds_windows@1.1.0
	unicode-ident@1.0.12
	unicode-width@0.1.13
	untrusted@0.9.0
	url@2.5.1
	urlencoding@2.1.3
	utf16_iter@1.0.5
	utf8_iter@1.0.4
	utf8parse@0.2.2
	valuable@0.1.0
	version_check@0.9.4
	walkdir@2.5.0
	want@0.3.1
	wasi@0.11.0+wasi-snapshot-preview1
	wasm-bindgen-backend@0.2.92
	wasm-bindgen-futures@0.4.42
	wasm-bindgen-macro-support@0.2.92
	wasm-bindgen-macro@0.2.92
	wasm-bindgen-shared@0.2.92
	wasm-bindgen@0.2.92
	web-sys@0.3.69
	webpki-roots@0.26.2
	which@6.0.1
	widestring@0.4.3
	wildmatch@2.3.4
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.8
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-core@0.52.0
	windows-core@0.56.0
	windows-implement@0.56.0
	windows-interface@0.56.0
	windows-result@0.1.2
	windows-sys@0.48.0
	windows-sys@0.52.0
	windows-sys@0.59.0
	windows-targets@0.48.5
	windows-targets@0.52.6
	windows-version@0.1.1
	windows@0.56.0
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.48.5
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.48.5
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.48.5
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.48.5
	windows_x86_64_msvc@0.52.6
	winnow@0.5.40
	winnow@0.6.13
	winreg@0.52.0
	winsafe@0.0.19
	write16@1.0.0
	writeable@0.5.5
	xattr@1.3.1
	xdg-home@1.2.0
	yaml-rust@0.4.5
	yoke-derive@0.7.4
	yoke@0.7.4
	zbus@4.2.2
	zbus_macros@4.2.2
	zbus_names@3.0.0
	zerofrom-derive@0.1.4
	zerofrom@0.1.4
	zeroize@1.8.1
	zerovec-derive@0.10.3
	zerovec@0.10.4
	zip@0.6.6
	zipsign-api@0.1.1
	zvariant@4.1.1
	zvariant_derive@4.1.1
	zvariant_utils@2.0.0
"

inherit cargo shell-completion

DESCRIPTION="Upgrade all the things"
HOMEPAGE="https://github.com/topgrade-rs/topgrade"
SRC_URI="
	https://github.com/topgrade-rs/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="GPL-3"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD CC0-1.0 ISC MIT
	MPL-2.0 Unicode-3.0 Unicode-DFS-2016
"
SLOT="0"
KEYWORDS="~amd64"

src_install() {
	cargo_src_install

	# shell completions and man page
	( PATH="$(cargo_target_dir)" topgrade --gen-completion bash || die ) | newbashcomp - "${PN}"
	( PATH="$(cargo_target_dir)" topgrade --gen-completion zsh || die ) | newzshcomp - "_${PN}"
	( PATH="$(cargo_target_dir)" topgrade --gen-completion fish || die ) | newfishcomp - "${PN}.fish"
	( PATH="$(cargo_target_dir)" topgrade --gen-manpage || die ) | newman - "${PN}.1"
}
