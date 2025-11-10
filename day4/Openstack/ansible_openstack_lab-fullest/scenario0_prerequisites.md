# Scenario 0: OpenStack Prerequisites - Image Setup

## Overview

This scenario downloads and uploads 5 lightweight, cloud-ready images to your OpenStack environment. These images are optimized for demo and training purposes.

## Images Included

### 1. CirrOS 0.6.2 (13 MB)
- **Purpose**: Fastest boot time, minimal testing
- **Use Case**: Quick connectivity tests, network validation
- **Boot Time**: ~10 seconds
- **Features**: Minimal busybox-based Linux

### 2. Ubuntu 22.04 LTS (600 MB)
- **Purpose**: Production workloads, full-featured OS
- **Use Case**: Web servers, application deployment, LAMP stack
- **Boot Time**: ~30-45 seconds
- **Features**: Full Ubuntu ecosystem, apt package manager, long-term support

### 3. Debian 12 "Bookworm" (400 MB)
- **Purpose**: Stable, reliable server deployment
- **Use Case**: Database servers, enterprise applications
- **Boot Time**: ~25-40 seconds
- **Features**: Stable release, excellent security track record

### 4. Alpine Linux 3.19 (50 MB)
- **Purpose**: Ultra-lightweight, container-friendly
- **Use Case**: Microservices, containerized apps, minimal footprint
- **Boot Time**: ~15 seconds
- **Features**: musl libc, BusyBox, apk package manager

### 5. Fedora 39 (500 MB)
- **Purpose**: Latest features, cutting-edge packages
- **Use Case**: Development, testing new technologies
- **Boot Time**: ~30-45 seconds
- **Features**: Latest kernel, modern packages, SELinux enabled

## Prerequisites

### Required
- OpenStack cloud with Glance service
- Valid credentials in `clouds.yaml`
- Admin or sufficient permissions for image upload
- Internet connection to download images
- Minimum 2 GB disk space for downloads

### Optional
- Fast internet connection (recommended for faster downloads)
- SSD storage for better upload performance

## Usage

### Run the Prerequisites Setup

```bash
# Basic execution
ansible-playbook scenario0_prerequisites.yml

# With verbose output
ansible-playbook scenario0_prerequisites.yml -v

# Skip cleanup of downloaded files
ansible-playbook scenario0_prerequisites.yml -e "cleanup_downloads=false"
```

### Execution Time

Approximate time based on connection speed:

- **Fast Connection (100+ Mbps)**: 5-8 minutes
- **Medium Connection (50-100 Mbps)**: 10-15 minutes
- **Slow Connection (<50 Mbps)**: 20-30 minutes

The playbook shows progress for each image download and upload.

## What This Playbook Does

1. **Creates Download Directory**: `/tmp/openstack_images`
2. **Checks Existing Images**: Skips images already in OpenStack
3. **Downloads Images**: Only downloads missing images
4. **Uploads to Glance**: Uploads images to OpenStack
5. **Sets Properties**: Configures min_disk, min_ram, bootable flag
6. **Waits for Activation**: Ensures images are ready to use
7. **Verifies Bootability**: Confirms all images are bootable
8. **Displays Summary**: Shows all available images with details
9. **Cleans Up**: Optionally removes downloaded files

## Verification

### Check Images in OpenStack

```bash
# List all images
openstack image list

# Get details of specific image
openstack image show ubuntu-22.04

# Verify bootable flag
openstack image show ubuntu-22.04 -f value -c properties | grep bootable
```

### Test Image with Quick VM Launch

```bash
# Launch test VM with CirrOS (fastest)
openstack server create --flavor m1.tiny --image cirros-0.6.2 \
  --network private test-vm

# Check VM status
openstack server show test-vm

# Delete test VM
openstack server delete test-vm
```

## Troubleshooting

### Download Failures

**Problem**: Image download times out or fails

**Solutions**:
```bash
# Increase timeout
ansible-playbook scenario0_prerequisites.yml -e "download_timeout=1200"

# Download manually and place in /tmp/openstack_images/
wget https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img \
  -O /tmp/openstack_images/cirros-0.6.2.qcow2
```

### Upload Failures

**Problem**: 403 Forbidden or permission denied

**Solution**:
```bash
# Grant admin permissions
./grant_admin_access.sh

# Or use admin credentials
# Edit clouds.yaml to use admin user
```

### Image Not Active

**Problem**: Image stuck in "queued" or "saving" status

**Solutions**:
```bash
# Check Glance service
systemctl status openstack-glance-api

# Check image status
openstack image show <image-name>

# Force activate (if needed)
openstack image set --active <image-name>
```

## Cleanup

### Remove All Demo Images

```bash
# Run teardown playbook
ansible-playbook scenario0_prerequisites_teardown.yml

# Confirm removal
openstack image list
```

### Manual Cleanup

```bash
# Remove specific image
openstack image delete ubuntu-22.04

# Remove all demo images
for img in cirros-0.6.2 ubuntu-22.04 debian-12 alpine-3.19 fedora-39; do
  openstack image delete $img
done
```

## Image Selection Guide

### For Testing & Development
- **CirrOS**: Network tests, quick validation
- **Alpine**: Minimal services, fast iteration

### For Production-Like Scenarios
- **Ubuntu 22.04**: Web apps, LAMP stack
- **Debian 12**: Database servers, stable apps

### For Latest Features
- **Fedora 39**: Testing new technologies

## Integration with Other Scenarios

After running this playbook, all other scenarios can use these images:

```yaml
# In any scenario playbook
vars:
  image_name: "ubuntu-22.04"  # or any other uploaded image
```

### Recommended Image per Scenario

- **scenario1-5**: `cirros-0.6.2` (fast testing)
- **scenario7**: `ubuntu-22.04` (multi-network)
- **scenario8**: `alpine-3.19` (autoscaling)
- **scenario11**: `ubuntu-22.04` (cloud-init/user-data)
- **scenario12**: `debian-12` (LAMP stack)
- **scenario14**: `ubuntu-22.04` (HAProxy)
- **scenario16**: `ubuntu-22.04` (full stack)

## Security Notes

### Image Verification

These images are downloaded from official sources:
- **CirrOS**: Official CirrOS project
- **Ubuntu**: Official Ubuntu Cloud Images
- **Debian**: Official Debian Cloud Images
- **Alpine**: Official Alpine Linux
- **Fedora**: Official Fedora Project

### Checksum Verification (Optional)

For production use, verify checksums:

```bash
# Download checksum file
wget https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS

# Verify image
sha256sum -c SHA256SUMS 2>&1 | grep jammy-server-cloudimg-amd64.img
```

## Advanced Options

### Custom Image Addition

Edit `scenario0_prerequisites.yml` to add your own images:

```yaml
images:
  - name: "my-custom-image"
    url: "https://example.com/my-image.qcow2"
    format: "qcow2"
    min_disk: 5
    min_ram: 1024
    description: "My custom image"
```

### Keep Downloaded Files

```bash
# Don't delete downloads after upload
ansible-playbook scenario0_prerequisites.yml -e "cleanup_downloads=false"

# Files remain in /tmp/openstack_images/
```

### Skip Existing Images

The playbook automatically skips images that already exist in OpenStack. No need to remove them first.

## Performance Tips

1. **Use SSD Storage**: Faster uploads to Glance
2. **Parallel Downloads**: Downloads run sequentially by default for reliability
3. **Local Mirror**: Set up local mirror for repeated setups
4. **Direct Upload**: For repeated use, keep images in `/tmp/openstack_images/`

## Support

If you encounter issues:

1. Check OpenStack logs: `/var/log/glance/`
2. Verify network connectivity: `ping download.cirros-cloud.net`
3. Check disk space: `df -h /tmp`
4. Verify Glance API: `openstack image list`

## Next Steps

After successful image upload:

```bash
# Verify images
openstack image list

# Run first scenario with uploaded images
ansible-playbook scenario1_basic_vm.yml

# Or try quick CirrOS test
ansible-playbook scenario1_basic_vm.yml -e "image_name=cirros-0.6.2"
```

---

**Status**: ✅ Production Ready  
**Estimated Time**: 5-15 minutes  
**Images**: 5 lightweight cloud images  
**Total Size**: ~1.5 GB downloads
