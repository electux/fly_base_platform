FILESEXTRAPATHS:prepend:fly-h3 := "${THISDIR}/files:"

SRC_URI:append:fly-h3 = " \
    file://sun8i-h3-fly-h3.dts \
"

do_configure:prepend:fly-h3() {
    DTS_DIR="${S}/arch/arm/boot/dts/allwinner"
    cp "${WORKDIR}/sun8i-h3-fly-h3.dts" "${DTS_DIR}/sun8i-h3-fly-h3.dts"
    if ! grep -q "sun8i-h3-fly-h3.dtb" "${DTS_DIR}/Makefile"; then
        echo "dtb-\$(CONFIG_MACH_SUN8I) += sun8i-h3-fly-h3.dtb" >> "${DTS_DIR}/Makefile"
    fi
}
