# OpenStack Demo Images - Quick Reference

## Overview
Run `ansible-playbook scenario0_prerequisites.yml` to download and upload all 5 images.

## Images Summary

| Image | Size | Boot Time | Min RAM | Min Disk | Best For |
|-------|------|-----------|---------|----------|----------|
| **cirros-0.6.2** | 13 MB | ~10s | 64 MB | 1 GB | Quick tests, network validation |
| **ubuntu-22.04** | 600 MB | ~30-45s | 512 MB | 3 GB | Production apps, LAMP stack |
| **debian-12** | 400 MB | ~25-40s | 512 MB | 2 GB | Stable servers, databases |
| **alpine-3.19** | 50 MB | ~15s | 256 MB | 1 GB | Microservices, containers |
| **fedora-39** | 500 MB | ~30-45s | 768 MB | 4 GB | Latest features, development |

## Quick Commands

```bash
# Setup all images
ansible-playbook scenario0_prerequisites.yml

# List images
openstack image list

# Remove all demo images
ansible-playbook scenario0_prerequisites_teardown.yml

# Test with CirrOS (fastest)
ansible-playbook scenario1_basic_vm.yml -e "image_name=cirros-0.6.2"
```

## Recommended Usage by Scenario

```yaml
scenario1-6:  cirros-0.6.2    # Fast testing
scenario7:    ubuntu-22.04    # Multi-network
scenario8:    alpine-3.19     # Autoscaling
scenario11:   ubuntu-22.04    # Cloud-init
scenario12:   debian-12       # LAMP stack
scenario14:   ubuntu-22.04    # HAProxy
scenario16:   ubuntu-22.04    # Full stack
```

## Image Features

### CirrOS 0.6.2
- ✅ Minimal BusyBox Linux
- ✅ Cloud-init enabled
- ✅ SSH access ready
- ⚡ Fastest boot time
- 📦 Perfect for testing

### Ubuntu 22.04 LTS
- ✅ Full Ubuntu environment
- ✅ APT package manager
- ✅ 5 years support
- ✅ Cloud-init enabled
- 🏢 Production-ready

### Debian 12 "Bookworm"
- ✅ Stable and reliable
- ✅ Excellent security
- ✅ APT package manager
- ✅ Cloud-init enabled
- 🔒 Enterprise choice

### Alpine Linux 3.19
- ✅ Ultra-lightweight
- ✅ APK package manager
- ✅ musl libc based
- ✅ Container-friendly
- ⚡ Fast and efficient

### Fedora 39
- ✅ Latest kernel
- ✅ Modern packages
- ✅ DNF package manager
- ✅ SELinux enabled
- 🚀 Cutting-edge

## Troubleshooting

### Download Issues
```bash
# Increase timeout
ansible-playbook scenario0_prerequisites.yml -e "download_timeout=1200"
```

### Permission Issues
```bash
# Grant admin access
./grant_admin_access.sh
```

### Verify Images
```bash
# Check all images
openstack image list

# Verify bootable
openstack image show ubuntu-22.04 -c properties
```

## All Images Are:
- ✅ Cloud-init enabled
- ✅ Bootable
- ✅ SSH-ready
- ✅ From official sources
- ✅ Tested and verified

---

**Total Download**: ~1.5 GB  
**Setup Time**: 5-15 minutes  
**All Images**: Lightweight & Demo-ready
