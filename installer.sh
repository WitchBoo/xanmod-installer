#!/bin/bash

# Clear terminal
clear

# Check if operating system is supported
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "debian" ] || ! [[ "$VERSION_ID" =~ ^(11|12)$ ]]; then
        echo "The script doesn't support your operating system."
        exit 1
    fi
else
    echo "Unable to determine operating system."
    exit 1
fi

# Check if XanMod is installed
if cat /proc/version | grep -q "xanmod"; then
    echo "XanMod is already installed."
    exit 1
fi

# Get XanMod supported version
XANMOD_VERSION=$(/usr/bin/awk '
BEGIN {
    while (!/flags/) if (getline < "/proc/cpuinfo" != 1) exit
    if (/lm/&&/cmov/&&/cx8/&&/fpu/&&/fxsr/&&/mmx/&&/syscall/&&/sse2/) level = 1
    if (level == 1 && /cx16/&&/lahf/&&/popcnt/&&/sse4_1/&&/sse4_2/&&/ssse3/) level = 2
    if (level == 2 && /avx/&&/avx2/&&/bmi1/&&/bmi2/&&/f16c/&&/fma/&&/abm/&&/movbe/&&/xsave/) level = 3
    if (level == 3 && /avx512f/&&/avx512bw/&&/avx512cd/&&/avx512dq/&&/avx512vl/) level = 4
    if (level > 0) { print level; exit }
    exit
}')

# Check if XanMod is supported
if [[ ! "$XANMOD_VERSION" =~ ^[1-4]$ ]]; then
    echo "XanMod is not supported with your CPU."
    exit 1
fi

# Choose a XanMod distribution
XANMOD_DISTRIBUTION_VALID=false
while [[ $XANMOD_DISTRIBUTION_VALID = false ]]; do
    if [[ ! $XANMOD_DISTRIBUTION ]]; then
        clear
    fi
    
    echo "XanMod Distributions:"
    echo "[0] - Stable Mainline [MAIN]"
    echo "[1] - Long Term Support [LTS]"
    echo "[2] - Stable Real-time [RT]"
    echo
    
    read -rp "Choose a distribution: " XANMOD_DISTRIBUTION
    
    # Check if is a valid option
    if [[ "$XANMOD_DISTRIBUTION" =~ ^[0-2]$ ]]; then
        XANMOD_DISTRIBUTION_VALID=true
    else
        echo "Invalid option. Please, select a valid option."
        echo
    fi
done

# Choose if the machine should restart after installation
RESTART_MACHINE=false
clear

read -rp "Restart machine after installation (y/N): " RESTART
# Check if is a valid option
if [[ "$RESTART" =~ [Yy] ]]; then
    RESTART_MACHINE=true
fi

# Get XanMod distribution based on the given option.
show_xanmod_distribution() {
    case $1 in
        0)
            echo "Stable Mainline [MAIN]"
        ;;
        1)
            echo "Long Term Support [LTS]"
        ;;
        2)
            echo "Stable Real-time [RT]"
        ;;
    esac
}

# Confirm installation
clear
echo "Information:"
echo "- Distribution: XanMod $(show_xanmod_distribution $XANMOD_DISTRIBUTION) v$XANMOD_VERSION"
echo "- Restart machine after installation: $(if [[ "$RESTART_MACHINE" = true ]]; then echo "yes"; else echo "no"; fi)"
echo

read -rp "Confirm installation (y/N): " CONFIRM
# Check if is a valid option
if [[ ! "$CONFIRM" =~ [Yy] ]]; then
    echo "Installation aborted."
    exit 0
fi


# Install XanMod
apt update && apt upgrade -y
apt install -y dirmngr ca-certificates software-properties-common apt-transport-https dkms curl
curl -fSsL https://dl.xanmod.org/archive.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/xanmod-archive-keyring.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
apt update && apt upgrade -y
echo "Installing XanMod $(show_xanmod_distribution $XANMOD_DISTRIBUTION) v$XANMOD_VERSION..."
case $XANMOD_DISTRIBUTION in
    0)
        apt install linux-xanmod-x64v$XANMOD_VERSION -y
    ;;
    1)
        apt install linux-xanmod-lts-x64v$XANMOD_VERSION -y
    ;;
    2)
        apt install linux-xanmod-rt-x64v$XANMOD_VERSION -y
    ;;
esac

echo "Installation script is done."

# Restart the machine.
if [[ "$RESTART_MACHINE" = true ]]; then
    echo "The machine will be restarted in 10 seconds."
    sleep 10 && sudo shutdown -r now
fi
