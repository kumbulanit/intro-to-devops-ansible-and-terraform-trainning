#!/usr/bin/env bash
################################################################################
# Oracle Database 19c Installation Script for Ubuntu 22.04 LTS
# 
# This script automates the installation of Oracle Database 19c on Ubuntu 22.04
# 
# Prerequisites:
#   - Ubuntu 22.04 LTS (64-bit)
#   - Minimum 8GB RAM (16GB+ recommended for production)
#   - Minimum 50GB free disk space
#   - Root or sudo access
#   - Oracle Database 19c installation files downloaded
#
# Usage:
#   1. Download Oracle Database 19c for Linux x86-64 from:
#      https://www.oracle.com/database/technologies/oracle-database-software-downloads.html
#   2. Place the downloaded zip file in /tmp/
#   3. Run: sudo ./install_oracle_db_ubuntu22.sh
#
# Author: DevOps Training
# Date: November 2025
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
ORACLE_BASE="/opt/oracle"
ORACLE_HOME="${ORACLE_BASE}/product/19c/dbhome_1"
ORACLE_SID="ORCL"
ORACLE_USER="oracle"
ORACLE_GROUP="oinstall"
ORACLE_DBA_GROUP="dba"
ORACLE_PASSWORD="Oracle123"  # Change this!
ORACLE_ZIP_FILE="${ORACLE_ZIP_FILE:-/tmp/LINUX.X64_193000_db_home.zip}"
ORACLE_INVENTORY="/opt/oraInventory"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

abort() {
    error "$*"
    exit 1
}

# Check if running as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        abort "This script must be run as root. Use: sudo $0"
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        warning "This script is designed for Ubuntu 22.04. Your OS may not be fully supported."
    fi
    
    # Check RAM (minimum 8GB)
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [[ ${total_mem} -lt 7 ]]; then
        abort "Insufficient RAM. Oracle Database requires at least 8GB RAM. Current: ${total_mem}GB"
    fi
    success "RAM check passed: ${total_mem}GB"
    
    # Check disk space (minimum 50GB)
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ ${available_space} -lt 50 ]]; then
        abort "Insufficient disk space. Required: 50GB, Available: ${available_space}GB"
    fi
    success "Disk space check passed: ${available_space}GB available"
    
    # Check if Oracle installation file exists
    if [[ ! -f "${ORACLE_ZIP_FILE}" ]]; then
        abort "Oracle installation file not found: ${ORACLE_ZIP_FILE}
        
Please download Oracle Database 19c from:
https://www.oracle.com/database/technologies/oracle-database-software-downloads.html
        
Place the file at: ${ORACLE_ZIP_FILE}"
    fi
    success "Oracle installation file found"
}

# Install required packages
install_dependencies() {
    log "Installing required packages..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    
    # Install Oracle prerequisites
    apt-get install -y \
        build-essential \
        libaio1 \
        libaio-dev \
        unixodbc \
        unixodbc-dev \
        sysstat \
        alien \
        libc6-dev \
        ksh \
        libstdc++6 \
        libstdc++5 \
        make \
        gcc \
        g++ \
        binutils \
        libelf-dev \
        elfutils \
        libxext6 \
        libxtst6 \
        libxi6 \
        libx11-6 \
        libxrender1 \
        libxrandr2 \
        libxinerama1 \
        net-tools \
        rlwrap \
        unzip \
        zip \
        xauth \
        xterm \
        x11-utils
    
    success "Dependencies installed"
}

# Configure kernel parameters
configure_kernel() {
    log "Configuring kernel parameters..."
    
    cat >> /etc/sysctl.conf <<'EOF'

# Oracle Database kernel parameters
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF
    
    sysctl -p > /dev/null
    success "Kernel parameters configured"
}

# Configure system limits
configure_limits() {
    log "Configuring system limits..."
    
    cat >> /etc/security/limits.conf <<EOF

# Oracle Database resource limits
${ORACLE_USER} soft nofile 1024
${ORACLE_USER} hard nofile 65536
${ORACLE_USER} soft nproc 16384
${ORACLE_USER} hard nproc 16384
${ORACLE_USER} soft stack 10240
${ORACLE_USER} hard stack 32768
${ORACLE_USER} hard memlock 134217728
${ORACLE_USER} soft memlock 134217728
EOF
    
    success "System limits configured"
}

# Create Oracle user and groups
create_oracle_user() {
    log "Creating Oracle user and groups..."
    
    # Create groups
    if ! getent group ${ORACLE_GROUP} > /dev/null; then
        groupadd -g 54321 ${ORACLE_GROUP}
        success "Created group: ${ORACLE_GROUP}"
    fi
    
    if ! getent group ${ORACLE_DBA_GROUP} > /dev/null; then
        groupadd -g 54322 ${ORACLE_DBA_GROUP}
        success "Created group: ${ORACLE_DBA_GROUP}"
    fi
    
    # Create oracle user
    if ! id ${ORACLE_USER} > /dev/null 2>&1; then
        useradd -u 54321 -g ${ORACLE_GROUP} -G ${ORACLE_DBA_GROUP} -s /bin/bash -m ${ORACLE_USER}
        success "Created user: ${ORACLE_USER}"
    fi
    
    # Set oracle user password
    echo "${ORACLE_USER}:${ORACLE_PASSWORD}" | chpasswd
    success "Set password for ${ORACLE_USER}"
}

# Create directory structure
create_directories() {
    log "Creating Oracle directory structure..."
    
    mkdir -p ${ORACLE_BASE}
    mkdir -p ${ORACLE_HOME}
    mkdir -p ${ORACLE_INVENTORY}
    mkdir -p /u01/app/oracle/oradata
    mkdir -p /u01/app/oracle/fast_recovery_area
    
    chown -R ${ORACLE_USER}:${ORACLE_GROUP} ${ORACLE_BASE}
    chown -R ${ORACLE_USER}:${ORACLE_GROUP} ${ORACLE_INVENTORY}
    chown -R ${ORACLE_USER}:${ORACLE_GROUP} /u01
    
    chmod -R 775 ${ORACLE_BASE}
    chmod -R 775 ${ORACLE_INVENTORY}
    
    success "Directory structure created"
}

# Configure Oracle user environment
configure_oracle_env() {
    log "Configuring Oracle user environment..."
    
    cat >> /home/${ORACLE_USER}/.bashrc <<EOF

# Oracle Database environment variables
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${ORACLE_SID}
export PATH=\${PATH}:\${ORACLE_HOME}/bin
export LD_LIBRARY_PATH=\${ORACLE_HOME}/lib:/lib:/usr/lib
export CLASSPATH=\${ORACLE_HOME}/jlib:\${ORACLE_HOME}/rdbms/jlib
export NLS_LANG=AMERICAN_AMERICA.UTF8
export ORACLE_INVENTORY=${ORACLE_INVENTORY}

# Command aliases
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
EOF
    
    chown ${ORACLE_USER}:${ORACLE_GROUP} /home/${ORACLE_USER}/.bashrc
    success "Oracle environment configured"
}

# Extract Oracle installation files
extract_oracle_files() {
    log "Extracting Oracle installation files (this may take several minutes)..."
    
    su - ${ORACLE_USER} -c "unzip -qo ${ORACLE_ZIP_FILE} -d ${ORACLE_HOME}"
    
    success "Oracle files extracted"
}

# Create response file for silent installation
create_response_file() {
    log "Creating Oracle installation response file..."
    
    cat > /tmp/db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=${ORACLE_GROUP}
INVENTORY_LOCATION=${ORACLE_INVENTORY}
ORACLE_HOME=${ORACLE_HOME}
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=${ORACLE_DBA_GROUP}
oracle.install.db.OSOPER_GROUP=${ORACLE_DBA_GROUP}
oracle.install.db.OSBACKUPDBA_GROUP=${ORACLE_DBA_GROUP}
oracle.install.db.OSDGDBA_GROUP=${ORACLE_DBA_GROUP}
oracle.install.db.OSKMDBA_GROUP=${ORACLE_DBA_GROUP}
oracle.install.db.OSRACDBA_GROUP=${ORACLE_DBA_GROUP}
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
DECLINE_SECURITY_UPDATES=true
EOF
    
    chown ${ORACLE_USER}:${ORACLE_GROUP} /tmp/db_install.rsp
    success "Response file created"
}

# Install Oracle Database software
install_oracle_software() {
    log "Installing Oracle Database software (this may take 15-30 minutes)..."
    
    su - ${ORACLE_USER} -c "${ORACLE_HOME}/runInstaller -silent -responseFile /tmp/db_install.rsp -ignorePrereqFailure" || true
    
    # Wait for installation to complete
    sleep 10
    
    # Run root scripts
    if [[ -f ${ORACLE_INVENTORY}/orainstRoot.sh ]]; then
        log "Running orainstRoot.sh..."
        ${ORACLE_INVENTORY}/orainstRoot.sh
    fi
    
    if [[ -f ${ORACLE_HOME}/root.sh ]]; then
        log "Running root.sh..."
        ${ORACLE_HOME}/root.sh
    fi
    
    success "Oracle software installation completed"
}

# Create database
create_database() {
    log "Creating Oracle database ${ORACLE_SID} (this may take 20-40 minutes)..."
    
    cat > /tmp/dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0
gdbName=${ORACLE_SID}
sid=${ORACLE_SID}
databaseConfigType=SI
templateName=General_Purpose.dbc
sysPassword=${ORACLE_PASSWORD}
systemPassword=${ORACLE_PASSWORD}
emConfiguration=NONE
datafileDestination=/u01/app/oracle/oradata
recoveryAreaDestination=/u01/app/oracle/fast_recovery_area
storageType=FS
characterSet=AL32UTF8
nationalCharacterSet=AL16UTF16
listeners=LISTENER
memoryPercentage=40
automaticMemoryManagement=TRUE
totalMemory=4096
EOF
    
    chown ${ORACLE_USER}:${ORACLE_GROUP} /tmp/dbca.rsp
    
    su - ${ORACLE_USER} -c "dbca -silent -createDatabase -responseFile /tmp/dbca.rsp" || {
        warning "DBCA may have encountered warnings. Checking database status..."
    }
    
    success "Database creation completed"
}

# Configure listener
configure_listener() {
    log "Configuring Oracle Net Listener..."
    
    cat > ${ORACLE_HOME}/network/admin/listener.ora <<EOF
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLE_SID})
      (ORACLE_HOME = ${ORACLE_HOME})
      (SID_NAME = ${ORACLE_SID})
    )
  )

ADR_BASE_LISTENER = ${ORACLE_BASE}
EOF
    
    cat > ${ORACLE_HOME}/network/admin/tnsnames.ora <<EOF
${ORACLE_SID} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${ORACLE_SID})
    )
  )
EOF
    
    chown ${ORACLE_USER}:${ORACLE_GROUP} ${ORACLE_HOME}/network/admin/*.ora
    
    # Start listener
    su - ${ORACLE_USER} -c "lsnrctl start" || true
    
    success "Listener configured and started"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service for Oracle Database..."
    
    cat > /etc/systemd/system/oracle-db.service <<EOF
[Unit]
Description=Oracle Database Service
After=network.target

[Service]
Type=forking
User=${ORACLE_USER}
Group=${ORACLE_GROUP}
Environment="ORACLE_HOME=${ORACLE_HOME}"
Environment="ORACLE_SID=${ORACLE_SID}"
ExecStart=${ORACLE_HOME}/bin/dbstart ${ORACLE_HOME}
ExecStop=${ORACLE_HOME}/bin/dbshut ${ORACLE_HOME}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure Oracle for auto-startup
    sed -i 's/:N$/:Y/' /etc/oratab
    
    systemctl daemon-reload
    systemctl enable oracle-db.service
    
    success "Systemd service created"
}

# Verify installation
verify_installation() {
    log "Verifying Oracle Database installation..."
    
    # Check if database is running
    if su - ${ORACLE_USER} -c "sqlplus -s / as sysdba <<< 'SELECT status FROM v\$instance;' | grep -q OPEN"; then
        success "Database is running"
    else
        warning "Database may not be running. Check logs at: ${ORACLE_BASE}/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
    fi
    
    # Check listener
    if su - ${ORACLE_USER} -c "lsnrctl status | grep -q 'The command completed successfully'"; then
        success "Listener is running"
    else
        warning "Listener may not be running"
    fi
}

# Display summary
display_summary() {
    cat <<EOF

${GREEN}╔═══════════════════════════════════════════════════════════════╗
║     Oracle Database 19c Installation Complete                ║
╚═══════════════════════════════════════════════════════════════╝${NC}

${BLUE}Installation Details:${NC}
  Oracle Base:     ${ORACLE_BASE}
  Oracle Home:     ${ORACLE_HOME}
  Database SID:    ${ORACLE_SID}
  Oracle User:     ${ORACLE_USER}
  Oracle Password: ${ORACLE_PASSWORD}

${BLUE}Connection Information:${NC}
  Hostname:        localhost
  Port:            1521
  Service Name:    ${ORACLE_SID}
  
${BLUE}To connect as SYSDBA:${NC}
  su - ${ORACLE_USER}
  sqlplus / as sysdba

${BLUE}To connect as SYSTEM:${NC}
  sqlplus system/${ORACLE_PASSWORD}@localhost:1521/${ORACLE_SID}

${BLUE}Service Management:${NC}
  Start:   sudo systemctl start oracle-db
  Stop:    sudo systemctl stop oracle-db
  Status:  sudo systemctl status oracle-db

${BLUE}Log Files:${NC}
  Alert Log:   ${ORACLE_BASE}/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
  Listener:    ${ORACLE_BASE}/diag/tnslsnr/$(hostname)/listener/trace/listener.log

${YELLOW}Important:${NC}
  1. Change the default passwords immediately!
  2. Configure firewall if needed: sudo ufw allow 1521/tcp
  3. Review security settings in production environments
  4. Set up regular backups using RMAN

${GREEN}For more information, visit:${NC}
  https://docs.oracle.com/en/database/oracle/oracle-database/19/

EOF
}

# Main installation flow
main() {
    log "Starting Oracle Database 19c installation on Ubuntu 22.04..."
    echo
    
    check_root
    check_requirements
    echo
    
    install_dependencies
    configure_kernel
    configure_limits
    create_oracle_user
    create_directories
    configure_oracle_env
    echo
    
    extract_oracle_files
    create_response_file
    install_oracle_software
    echo
    
    create_database
    configure_listener
    create_systemd_service
    echo
    
    verify_installation
    echo
    
    display_summary
    
    success "Oracle Database installation completed successfully!"
}

# Run main function
main "$@"
