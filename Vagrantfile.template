Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "gitflow-dev"

  # VM Configuration with enhanced isolation
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "gitflow-isolated-dev"
    
    # Disable all possible device access
    vb.customize ["modifyvm", :id, "--clipboard", "disabled"]
    vb.customize ["modifyvm", :id, "--draganddrop", "disabled"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
    vb.customize ["modifyvm", :id, "--usbxhci", "off"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  # Network Configuration - Minimal required
  config.vm.network "private_network", type: "dhcp"

  # Disable default shared folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Development folder with strict permissions
  config.vm.synced_folder "./gitflow", "/home/vagrant/gitflow",
    create: true,
    owner: "vagrant",
    group: "vagrant",
    mount_options: ["dmode=755,fmode=644"],
    SharedFoldersEnableSymlinksCreate: false

  # Enhanced isolation setup with comprehensive validation
  config.vm.provision "shell", inline: <<-SHELL
    # Create isolation marker
    mkdir -p /etc/gitflow-isolation
    chmod 755 /etc/gitflow-isolation
    touch /etc/gitflow-isolation/isolated
    chmod 644 /etc/gitflow-isolation/isolated

    # Function to safely handle systemd units
    cat > /usr/local/bin/handle-systemd-unit <<'EOF'
#!/bin/bash

handle_unit() {
    local unit=$1
    local action=$2

    # Create the unit file if it doesn't exist
    if [[ "$action" == "mask" && ! -f "/etc/systemd/system/$unit" ]]; then
        echo "[Unit]
Description=$unit placeholder
[Service]
Type=simple
ExecStart=/bin/true" > "/etc/systemd/system/$unit"
    fi

    # Perform the action
    if systemctl list-unit-files | grep -q "^$unit"; then
        systemctl stop "$unit" 2>/dev/null || true
        systemctl "$action" "$unit" 2>/dev/null || true
        echo "✓ Unit $unit has been ${action}ed"
    else
        echo "ℹ️  Unit $unit not found, creating mask"
        ln -sf /dev/null "/etc/systemd/system/$unit"
    fi
}

# Function to handle services
handle_service() {
    local service=$1
    
    if systemctl list-unit-files | grep -q "^$service"; then
        systemctl stop "$service" 2>/dev/null || true
        systemctl mask "$service" 2>/dev/null || true
        echo "✓ Service $service has been masked"
    else
        echo "ℹ️  Service $service not found, creating mask"
        ln -sf /dev/null "/etc/systemd/system/$service"
    fi
}
EOF

    chmod +x /usr/local/bin/handle-systemd-unit

    # Create better automount blocking
    cat > /etc/systemd/system/block-automount.service <<EOF
[Unit]
Description=Block Automounting
DefaultDependencies=no
Before=tmp.mount
[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
[Install]
WantedBy=local-fs.target
EOF

    # Handle all mount units
    /usr/local/bin/handle-systemd-unit media-cdrom.mount mask
    /usr/local/bin/handle-systemd-unit media-usb.mount mask
    /usr/local/bin/handle-systemd-unit media-floppy.mount mask
    /usr/local/bin/handle-service udisks2.service

    # Enable blocking service
    systemctl enable block-automount.service
    
    # Reload systemd
    systemctl daemon-reload
    systemctl reset-failed

    # Create comprehensive isolation check script
    cat > /usr/local/bin/check-isolation <<'EOF'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_failed=0

print_result() {
    if [ $2 -eq 0 ]; then
        echo -e "$1: ${GREEN}✓ PASS${NC}"
    else
        echo -e "$1: ${RED}✗ FAIL${NC}"
        check_failed=1
    fi
}

echo -e "${YELLOW}🔍 Running Comprehensive Isolation Checks${NC}"
echo "============================================"

# 1. User and Environment Checks
echo -e "\n${YELLOW}1. User and Environment Checks:${NC}"

# Check user
USER_CHECK=$([ "$(whoami)" = "vagrant" ]; echo $?)
print_result "Current user is vagrant" $USER_CHECK

# Check hostname
HOSTNAME_CHECK=$([ "$(hostname)" = "gitflow-dev" ]; echo $?)
print_result "Hostname is gitflow-dev" $HOSTNAME_CHECK

# Check isolation marker
MARKER_CHECK=$([ -f "/etc/gitflow-isolation/isolated" ]; echo $?)
print_result "Isolation marker exists" $MARKER_CHECK

# 2. Network Isolation Checks
echo -e "\n${YELLOW}2. Network Isolation Checks:${NC}"

# Check network interfaces
NETWORK_CHECK=$(ip addr | grep -q "192.168.56"; echo $?)
print_result "Private network configured" $NETWORK_CHECK

# Check host connection
HOST_CHECK=$(ping -c 1 -W 1 host.vagrant.internal >/dev/null 2>&1; [ $? -ne 0 ]; echo $?)
print_result "Host connection blocked" $HOST_CHECK

# 3. Filesystem Isolation Checks
echo -e "\n${YELLOW}3. Filesystem Isolation Checks:${NC}"

# Check /vagrant mount
VAGRANT_CHECK=$([ ! -d "/vagrant" ] || [ -z "$(ls -A /vagrant 2>/dev/null)" ]; echo $?)
print_result "No default vagrant mount" $VAGRANT_CHECK

# Check gitflow directory permissions
GITFLOW_CHECK=$([ -d "/home/vagrant/gitflow" ] && [ "$(stat -c '%U:%G' /home/vagrant/gitflow)" = "vagrant:vagrant" ]; echo $?)
print_result "Gitflow directory permissions" $GITFLOW_CHECK

# 4. Package Environment Checks
echo -e "\n${YELLOW}4. Package Environment Checks:${NC}"

# Check APT isolation config
APT_CHECK=$([ -f "/etc/apt/apt.conf.d/99isolation" ]; echo $?)
print_result "APT isolation configured" $APT_CHECK

# Check package installation path
GIT_CHECK=$([ "$(which git)" = "/usr/bin/git" ]; echo $?)
print_result "Package installation path" $GIT_CHECK

# 5. Root Access Checks
echo -e "\n${YELLOW}5. Root Access Checks:${NC}"

# Check host root access
HOST_ROOT_CHECK=$([ ! -d "/host" ] && [ -z "$(ls -A /media 2>/dev/null)" ]; echo $?)
print_result "No host root access" $HOST_ROOT_CHECK

# 6. Device Access Checks
echo -e "\n${YELLOW}6. Device Access Checks:${NC}"

# Check USB devices
USB_CHECK=$(! lsusb | grep -qv "Bus 001 Device 001: ID"; echo $?)
print_result "USB access restricted" $USB_CHECK

# Check device mounts
DEVICE_CHECK=$(! mount | grep -q "^/dev/sd[b-z]"; echo $?)
print_result "External device mounts blocked" $DEVICE_CHECK

# 7. Automount Checks
echo -e "\n${YELLOW}7. Automount Checks:${NC}"

# Check systemd automount services
AUTOMOUNT_CHECK=$(systemctl is-active media-cdrom.mount media-usb.mount media-floppy.mount 2>/dev/null | grep -q "^active"; [ $? -ne 0 ]; echo $?)
print_result "Automount services disabled" $AUTOMOUNT_CHECK

# Check udisks2 service
UDISKS_CHECK=$(systemctl is-active udisks2.service 2>/dev/null | grep -q "^active"; [ $? -ne 0 ]; echo $?)
print_result "Udisks2 service disabled" $UDISKS_CHECK

# Final Results
echo -e "\n${YELLOW}Final Results:${NC}"
if [ $check_failed -eq 0 ]; then
    echo -e "${GREEN}✅ All isolation checks passed${NC}"
    exit 0
else
    echo -e "${RED}❌ Some isolation checks failed${NC}"
    echo -e "${YELLOW}⚠️  Environment might not be fully isolated${NC}"
    exit 1
fi
EOF

    chmod +x /usr/local/bin/check-isolation

    # Set up package restrictions
    cat > /etc/apt/apt.conf.d/99isolation <<EOF
APT::Get::AllowUnauthenticated "false";
Acquire::AllowInsecureRepositories "false";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

    # Block device mounting
    cat > /etc/udev/rules.d/99-block-devices.rules <<EOF
KERNEL=="sd[a-z]*", SUBSYSTEM=="block", GROUP="disk", MODE="0600"
EOF

    # Install required packages
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      devscripts \
      debhelper \
      git \
      python3 \
      python3-pip \
      jq \
      curl

    # Add check to bashrc
    sed -i '/check-isolation/d' /home/vagrant/.bashrc
    echo 'check-isolation || echo -e "\033[1;33m⚠️  Please verify environment isolation\033[0m"' >> /home/vagrant/.bashrc

    # Restrict device access
    chmod 600 /dev/sd* 2>/dev/null || true
  SHELL
end