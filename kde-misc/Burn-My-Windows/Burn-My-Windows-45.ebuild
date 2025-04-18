# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Disintegrate your windows with style"
HOMEPAGE="https://github.com/Schneegans/Burn-My-Windows"
SRC_URI="https://github.com/Schneegans/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	kde-plasma/kwin:6
	kde-frameworks/kwidgetsaddons:6[designer]
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-lang/perl
	sys-devel/gettext
"
# Allow choosing of the wanted effects
EFFECTS=(
	"aura-glow:Aura Glow [Burn-My-Windows]:A radiant edge-lit animation"
	"doom:Doom [Burn-My-Windows]:Melt your windows"
	"energize-a:Energize A [Burn-My-Windows]:Beam your windows away"
	"energize-b:Energize B [Burn-My-Windows]:Using different transporter technology results in an alternative visual effect"
	"fire:Fire [Burn-My-Windows]:The classic effect inspired by Compiz"
	"focus:Focus [Burn-My-Windows]:Focus dude, focus!"
	"glide:Glide [Burn-My-Windows]:Fade the window to transparency with subtle 3D effects"
	"glitch:Glitch [Burn-My-Windows]:This effect applies some intentional graphics issues to your windows"
	"hexagon:Hexagon [Burn-My-Windows]:With glowing lines and hexagon-shaped tiles, this effect looks very sci-fi"
	"incinerate:Incinerate [Burn-My-Windows]:A less snappy but definitely more fancy take on the fire effect"
	"pixelate:Pixelate [Burn-My-Windows]:Pixelate the window and randomly hide the pixels"
	"pixel-wheel:Pixel Wheel [Burn-My-Windows]:Pixelate the window and hide the pixels in a wheel-like fashion"
	"pixel-wipe:Pixel Wipe [Burn-My-Windows]:Pixelate the window and hide the pixels radially, starting from the pointer position"
	"portal:Portal [Burn-My-Windows]:Transfer your windows to other locations in space and time"
	"rgbwarp:RGB Warp [Burn-My-Windows]:Red Blue and Green go bye bye"
	"team-rocket:Team Rocket [Burn-My-Windows]:... is blasting off again!"
	"tv:TV Effect [Burn-My-Windows]:Make windows close like turning off a TV"
	"tv-glitch:TV Glitch [Burn-My-Windows]:Make your windows close like a very glitchy old-school TV"
	"wisps:Wisps [Burn-My-Windows]:Let your windows be carried away to the realm of dreams by these little fairies"
)
IUSE="${EFFECTS[*]%%:*}"
REQUIRED_USE="|| ( ${EFFECTS[*]%%:*} )"

PATCHES=( "${FILESDIR}/36-blacklist-spectacle.patch" )

# modded generate() from kwin/build.sh to allow USE flags and skip unneeded steps
# This function is called for each effect. The parameters are as follows:
# $1: The nick of the effect (e.g. "energize-a")
# $2: The name of the effect (e.g. "Energize A")
# $3: A short description of the effect (e.g. "Beam your windows away")
generate() {
	(( $# == 3 )) || die "Needs 3 args"

	einfo "Generating ${1}: ${2} ${3}"

	# We use the nick for the effect's directory name by replacing dashes with underscoares.
	DIR_NAME="kwin6_effect_$(echo "$1" || die | tr '-' '_' || die)"

	# We transform the nick to CamelCase for the JavaScript class name.
	EFFECT_CLASS="BurnMyWindows$(sed -r 's/(^|-)(\w)/\U\2/g' <<<"$1" || die)Effect"

	# Now create all required resource directories.
	mkdir -p "$BUILD_DIR/$DIR_NAME/contents/shaders" || die
	mkdir -p "$BUILD_DIR/$DIR_NAME/contents/code" || die
	mkdir -p "$BUILD_DIR/$DIR_NAME/contents/config" || die
	mkdir -p "$BUILD_DIR/$DIR_NAME/contents/ui" || die

	# Copy the translations.
	cp -r "$BUILD_DIR/locale" "$BUILD_DIR/$DIR_NAME/contents" || die

	# Copy the config file if it exists.
	if [ -f "$1/main.xml" ]; then
	  cp "$1/main.xml" "$BUILD_DIR/$DIR_NAME/contents/config" || die
	fi

	# Copy the ui file if it exists.
	if [ -f "$1/config.ui" ]; then
	  cp "$1/config.ui" "$BUILD_DIR/$DIR_NAME/contents/ui" || die
	fi

	# Now we create the effect's JavaScript source file. This is done by taking main.js.in
	# and replacing some placeholders with effect-specific files and values.
	ON_SETTINGS_CHANGE=""
	ON_ANIMATION_BEGIN=""

	# If the effect's directory contains a onSettingsChanged.js, we replace the
	# corresponding placeholder with it's content. We replace all occurences of / temporily
	# so that the REGEX works.
	if [ -f "$1/onSettingsChanged.js" ]; then
	  ON_SETTINGS_CHANGE=$(tr '/' '\f' < "$1/onSettingsChanged.js" || die)
	fi

	# Similarily, we will inject the contents of onAnimationBegin.js.
	if [ -f "$1/onAnimationBegin.js" ]; then
	  ON_ANIMATION_BEGIN=$(tr '/' '\f' < "$1/onAnimationBegin.js" || die)
	fi

	cp main.js.in "$BUILD_DIR/$DIR_NAME/contents/code/main.js"
	perl -pi -e "s/%ON_SETTINGS_CHANGE%/$ON_SETTINGS_CHANGE/g;" \
		"$BUILD_DIR/$DIR_NAME/contents/code/main.js" || die
	perl -pi -e "s/%ON_ANIMATION_BEGIN%/$ON_ANIMATION_BEGIN/g;" \
		"$BUILD_DIR/$DIR_NAME/contents/code/main.js" || die
	perl -pi -e "s/%EFFECT_CLASS%/$EFFECT_CLASS/g;" \
		"$BUILD_DIR/$DIR_NAME/contents/code/main.js" || die
	perl -pi -e "s/%SHADER_NAME%/$1/g;" \
		"$BUILD_DIR/$DIR_NAME/contents/code/main.js" || die
	perl -pi -e "s/\f/\//g;" \
		"$BUILD_DIR/$DIR_NAME/contents/code/main.js" || die

	# Now create the metadata.json file. Again, we replace some placeholders.
	cp metadata.json.in "$BUILD_DIR/$DIR_NAME/metadata.json" || die
	perl -pi -e "s/%ICON%/$1/g;" \
		"$BUILD_DIR/$DIR_NAME/metadata.json" || die
	perl -pi -e "s/%NAME%/$2/g;" \
		"$BUILD_DIR/$DIR_NAME/metadata.json" || die
	perl -pi -e "s/%DESCRIPTION%/$3/g;" \
		"$BUILD_DIR/$DIR_NAME/metadata.json" || die
	perl -pi -e "s/%DIR_NAME%/$DIR_NAME/g;" \
		"$BUILD_DIR/$DIR_NAME/metadata.json" || die

	# Now create the two required shader files. We prepend the common.glsl to each shader.
	# We also define KWIN and KWIN_LEGACY. The code in common.glsl takes some different
	# paths based on these defines.
	{
	  echo "#version 140" || die
	  echo "#define KWIN" || die
	  echo "#define PLASMA6" || die
	  echo "" || die
	  echo "// This file is automatically generated during the build process." || die
	  echo "" || die
	  cat "../resources/shaders/common.glsl" || die
	  cat "../resources/shaders/$1.frag" || die
	} > "$BUILD_DIR/$DIR_NAME/contents/shaders/$1_core.frag"

	{
	  echo "#define KWIN_LEGACY" || die
	  echo "#define PLASMA6" || die
	  echo "" || die
	  echo "// This file is automatically generated during the build process." || die
	  echo "" || die
	  cat "../resources/shaders/common.glsl" || die
	  cat "../resources/shaders/$1.frag" || die
	} > "$BUILD_DIR/$DIR_NAME/contents/shaders/$1.frag"
}

src_compile() {
	# We only care for the kwin effects here
	cd "${WORKDIR}/${P}/kwin" || die

	# setup build dir
	BUILD_DIR="${WORKDIR}/${P}_build"
	mkdir -p "${BUILD_DIR}" || die

	# compile the translations.
	local file
	for file in ../po/*.po; do
		echo "Compiling ${file}" || die
		lang=$(basename "${file}" .po || die)
		mkdir -p "${BUILD_DIR}/locale/${lang}/LC_MESSAGES" || die
		msgfmt "${file}" -o "${BUILD_DIR}/locale/${lang}/LC_MESSAGES/burn-my-windows.mo" || die
	done

	# build effects based on USE
	local spec nick name desc
	for spec in "${EFFECTS[@]}"; do
		IFS=':' read -r nick name desc <<<"${spec}" || die
		use "${nick}" && generate "${nick}" "${name}" "${desc}"
	done
}

src_install() {
	insinto /usr/share/kwin/effects/
	doins -r "${BUILD_DIR}"/kwin6_effect_*
}
