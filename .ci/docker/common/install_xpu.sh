#!/bin/bash
set -xe


# Intel® software for general purpose GPU capabilities.
# Refer to https://dgpu-docs.intel.com/releases/stable_647_21_20230714.html

# Intel® oneAPI Base Toolkit (version 2024.0.0) has been updated to include functional and security updates.
# Refer to https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html

# Users should update to the latest version as it becomes available

function install_ubuntu() {
    # Driver
    sudo apt update
    sudo apt install -y gpg-agent wget rsync

    . /etc/os-release
    if [[ ! " jammy " =~ " ${VERSION_CODENAME} " ]]; then
        echo "Ubuntu version ${VERSION_CODENAME} not supported"
    else
        wget -qO - https://repositories.intel.com/gpu/intel-graphics.key |sudo gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu ${VERSION_CODENAME}/lts/2350 unified" | \
        sudo tee /etc/apt/sources.list.d/intel-gpu-${VERSION_CODENAME}.list
        sudo apt update
    fi
    sudo apt install -y linux-headers-$(uname -r) flex bison xpu-smi # intel-fw-gpu intel-i915-dkms
    sudo apt install -y \
        intel-opencl-icd intel-level-zero-gpu level-zero \
        intel-media-va-driver-non-free libmfx1 libmfxgen1 libvpl2 \
        libegl-mesa0 libegl1-mesa libegl1-mesa-dev libgbm1 libgl1-mesa-dev libgl1-mesa-dri \
        libglapi-mesa libgles2-mesa-dev libglx-mesa0 libigdgmm12 libxatracker2 mesa-va-drivers \
        mesa-vdpau-drivers mesa-vulkan-drivers va-driver-all vainfo hwinfo clinfo
    sudo apt install -y \
        libigc-dev intel-igc-cm libigdfcl-dev libigfxcmrt-dev level-zero-dev

    # oneAPI
    mkdir _install_basekit && cd _install_basekit
    wget https://af01p-fm.devtools.intel.com/artifactory/compilers-archive-fm-local/compiler_ppkg-hotfix/linux/20240321/l_20240321_oneapipkg.tar.gz --no-proxy
    tar xf l_20240321_oneapipkg.tar.gz
    mkdir -p /opt/intel/oneapi
    rsync -avz --delete linux_qa_release/ /opt/intel/oneapi/
    cd .. && rm -rf _install_basekit

    # Cleanup
    apt-get autoclean && apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

function install_centos() {
    dnf install -y 'dnf-command(config-manager)'
    dnf config-manager --add-repo \
        https://repositories.intel.com/gpu/rhel/8.6/production/2328/unified/intel-gpu-8.6.repo
    # To add the EPEL repository needed for DKMS
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        # https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

    # Create the YUM repository file in the /temp directory as a normal user
    tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

    # Move the newly created oneAPI.repo file to the YUM configuration directory /etc/yum.repos.d
    mv /tmp/oneAPI.repo /etc/yum.repos.d

    # The xpu-smi packages
    dnf install -y flex bison xpu-smi
    # Compute and Media Runtimes
    dnf install -y \
        intel-opencl intel-media intel-mediasdk libmfxgen1 libvpl2\
        level-zero intel-level-zero-gpu mesa-dri-drivers mesa-vulkan-drivers \
        mesa-vdpau-drivers libdrm mesa-libEGL mesa-libgbm mesa-libGL \
        mesa-libxatracker libvpl-tools intel-metrics-discovery \
        intel-metrics-library intel-igc-core intel-igc-cm \
        libva libva-utils intel-gmmlib libmetee intel-gsc intel-ocloc hwinfo clinfo
    # Development packages
    dnf install -y --refresh \
        intel-igc-opencl-devel level-zero-devel intel-gsc-devel libmetee-devel \
        level-zero-devel
    # Install Intel® oneAPI Base Toolkit
    dnf install intel-basekit -y

    # Cleanup
    dnf clean all
    rm -rf /var/cache/yum
    rm -rf /var/lib/yum/yumdb
    rm -rf /var/lib/yum/history
}


# The installation depends on the base OS
ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
case "$ID" in
    ubuntu)
        install_ubuntu
    ;;
    centos)
        install_centos
    ;;
    *)
        echo "Unable to determine OS..."
        exit 1
    ;;
esac
