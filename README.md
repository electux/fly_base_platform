# Yocto Base Platform for Mellow Fly-Pi-lite2.1 (Fly H3)

This repository serves as a **Yocto Base Platform (BSP / Board Support Package) Repository** for the **Mellow Fly-Pi-lite2.1 (`fly-h3`)** Allwinner H3 board using **Yocto 5.0 LTS (Scarthgap)**.

It is designed to be:
1. **Standalone Build Environment**: Clone it and build a base console image directly for testing.
2. **Reusable BSP Submodule**: Include it as a Git submodule in higher-level product/project repositories, separating hardware/BSP details from application-specific layers.

---

## Hardware Target (`fly-h3`)

* **Board**: Mellow Fly-Pi-lite2.1 (`mellow,fly-h3`)
* **SoC**: Allwinner H3 (Quad-core ARM Cortex-A7, 32-bit `sun8i`)
* **GPU**: Mali-400 MP2
* **RAM**: 512 MB DDR3
* **Storage**: MicroSD (TF card) on `mmc0`
* **Wireless**: Onboard 2.4 GHz Wi-Fi (RTL8189FTV over SDIO `mmc1`)
* **Interfaces**: 2× USB 2.0 Host, UART0 Serial Console (`115200;ttyS0`), FPC-HDMI, FPC-TFT

---

## Directory Structure

```
fly_base_platform/
├── configs/
│   └── meta-fly-base/                         # Base hardware BSP layer for Fly-Pi-lite2.1
│       ├── conf/
│       │   ├── layer.conf                     # Layer configuration (scarthgap, priority 11)
│       │   ├── machine/
│       │   │   └── fly-h3.conf                # Custom MACHINE inheriting sun8i.inc
│       │   └── templates/
│       │       └── default/
│       │           ├── bblayers.conf.sample   # Layers configured with ##OEROOT## relative paths
│       │           ├── local.conf.sample      # Default configuration template
│       │           └── conf-notes.txt         # Welcome message and helper commands
│       ├── recipes-bsp/
│       │   └── u-boot/                        # U-Boot boot.cmd selecting sun8i-h3-fly-h3.dtb
│       ├── recipes-kernel/
│       │   └── linux/                         # Mainline kernel bbappend + sun8i-h3-fly-h3.dts
│       └── recipes-core/
│           └── images/                        # Base image customization hook
├── layers/                                    # Upstream Yocto layers managed as Git Submodules
│   ├── poky/                                  # Core Yocto metadata and BitBake (scarthgap)
│   ├── meta-openembedded/                     # Extra recipes (oe, python, networking, multimedia)
│   ├── meta-arm/                              # ARM toolchain & support (required by meta-sunxi)
│   └── meta-sunxi/                            # Allwinner SoC BSP layer (scarthgap)
├── scripts/
│   └── setup-env.sh                           # Intelligent environment wrapper script
├── README.md
└── LICENSE
```

---

## 1. Standalone Quickstart (Direct Build)

### Prerequisites

Ensure your build host has the required packages installed for Yocto Scarthgap. For Ubuntu/Debian:

```bash
sudo apt-get install gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \
     debianutils iputils-ping python3-git python3-jinja2 python3-subunit \
     zstd liblz4-tool file locales libsdl1.2-dev xterm lz4
```

### Step 1: Clone the Repository
Clone with `--recurse-submodules` to fetch the locked Yocto branches immediately:

```bash
git clone --recurse-submodules https://github.com/electux/fly_base_platform.git
cd fly_base_platform
```

*(If you already cloned without submodules, run `git submodule update --init --recursive`)*.

### Step 2: Initialize the Build Environment
Source the setup wrapper script:

```bash
source scripts/setup-env.sh [optional-build-directory-name]
```

This wrapper script:
- Verifies and initializes missing submodules.
- Detects the absolute repository root path dynamically.
- Automatically points `TEMPLATECONF` to `configs/meta-fly-base/conf/templates/default`.
- Initializes the Yocto build directory (defaults to `build-fly-h3/`).

### Step 3: Trigger the Build
Run BitBake to build one of the available console-only reference images:

* **Minimal Console Image (`core-image-minimal`)**: Smallest bootable image (kernel, BusyBox, basic init/shell). Good for quick verification.
  ```bash
  bitbake core-image-minimal
  ```

* **Standard Console Image (`core-image-base`)**: Console image with full base hardware support. Recommended for headless production/IoT devices.
  ```bash
  bitbake core-image-base
  ```

* **Full Command-Line Console Image (`core-image-full-cmdline`)**: Console image replacing BusyBox utilities with full GNU/Linux tools.
  ```bash
  bitbake core-image-full-cmdline
  ```

The resulting SD card image is generated at:
`build-fly-h3/tmp/deploy/images/fly-h3/<image>-fly-h3.wic.gz`

### Step 4: Flash & Login
Flash the `.wic.gz` image to a MicroSD card (e.g., via `bmaptool` or `zcat ... | sudo dd of=/dev/sdX bs=4M status=progress`):
* **Serial Console**: UART0 at `115200 8N1` (`ttyS0`)
* **Username**: `root`
* **Password**: No password (leave blank and press Enter, enabled via `debug-tweaks`).

---

## 2. Integration into a Parent Product Repository

To use this repository as a submodule in a larger project (separating your hardware BSP baseline from your application metadata):

### Recommended Product Structure

```
my-product-project/           # Parent Git repository
├── submodules/
│   └── fly-base-platform/    # Git submodule: This fly_base_platform repo
│       ├── layers/
│       │   ├── poky/
│       │   ...
│       └── scripts/
│           └── setup-env.sh
├── project-layers/           # Custom, project-specific layers
│   └── meta-product-app/     # Recipes for your apps, services, UIs, etc.
├── configs/                  # Configurations specific to this product
│   ├── bblayers.conf.sample  # bblayers configuration including base and product layers
│   └── local.conf.sample     # Product-specific features and variables
├── setup-project.sh          # Wrapper script at the root level
└── README.md
```

### Setting up the Parent's `bblayers.conf.sample`

Because `fly-base-platform` uses relative paths referenced from the Poky root directory (`##OEROOT##`), you can add your custom product layers seamlessly in the parent's `configs/bblayers.conf.sample`:

```ini
POKY_BBLAYERS_CONF_VERSION = "2"
BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ##OEROOT##/meta \
  ##OEROOT##/meta-poky \
  ##OEROOT##/meta-yocto-bsp \
  ##OEROOT##/../meta-openembedded/meta-oe \
  ##OEROOT##/../meta-openembedded/meta-python \
  ##OEROOT##/../meta-openembedded/meta-networking \
  ##OEROOT##/../meta-openembedded/meta-multimedia \
  ##OEROOT##/../meta-arm/meta-arm-toolchain \
  ##OEROOT##/../meta-arm/meta-arm \
  ##OEROOT##/../meta-sunxi \
  ##OEROOT##/../../configs/meta-fly-base \
  ##OEROOT##/../../../../project-layers/meta-product-app \
  "
```

### Sourcing from the Root via `setup-project.sh`

```bash
#!/usr/bin/env bash
# Initialize product workspace

# 1. Initialize submodules if not already done
if [ ! -f "submodules/fly-base-platform/layers/poky/oe-init-build-env" ]; then
    echo "[!] Initializing submodules..."
    git submodule update --init --recursive
fi

# 2. Point TEMPLATECONF to the parent project's config
export TEMPLATECONF="$(pwd)/configs"

# 3. Source environment from the BSP submodule
source submodules/fly-base-platform/layers/poky/oe-init-build-env "build-product"
```

---

## Customization Tips (`local.conf`)

* **Reduce Disk Space consumption**:
  Uncomment `INHERIT += "rm_work"` in `local.conf` to delete intermediate build directories for completed recipes.
* **Shared Build Cache**:
  Uncomment and point `DL_DIR` and `SSTATE_DIR` to a shared cache directory across projects.

---

## Troubleshooting

### Ubuntu 24.04 LTS User Namespace Restriction
Ubuntu 24.04 restricts unprivileged user namespaces by default via AppArmor, which blocks BitBake sandboxes.

* **Temporary Fix** (until reboot):
  ```bash
  echo 0 | sudo tee /proc/sys/kernel/apparmor_restrict_unprivileged_userns
  ```

* **Persistent Fix** (recommended):
  ```bash
  echo "kernel.apparmor_restrict_unprivileged_userns=0" | sudo tee /etc/sysctl.d/60-apparmor-namespace.conf
  sudo sysctl -p /etc/sysctl.d/60-apparmor-namespace.conf
  ```
