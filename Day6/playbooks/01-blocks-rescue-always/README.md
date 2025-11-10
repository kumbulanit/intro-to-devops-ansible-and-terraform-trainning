# Blocks, Rescue, and Always - Example Playbooks

This directory contains working examples for Topic 1: Blocks & Rollback.

## 📁 Files

- `basic-block.yml` - Simple block/rescue/always example
- `database-backup.yml` - Backup with error handling
- `web-deployment.yml` - Web server deployment with rollback
- `rolling-deployment.yml` - Multi-server rolling deployment
- `inventory.ini` - Sample inventory file

## 🚀 Quick Start

1. **Update inventory:**
   ```bash
   vi inventory.ini
   # Update with your server IPs
   ```

2. **Test basic block:**
   ```bash
   ansible-playbook -i inventory.ini basic-block.yml
   ```

3. **Run database backup:**
   ```bash
   ansible-playbook -i inventory.ini database-backup.yml
   ```

4. **Deploy web server:**
   ```bash
   ansible-playbook -i inventory.ini web-deployment.yml
   ```

## 📚 Examples Overview

### basic-block.yml
Simple demonstration of block, rescue, and always sections.

**Key concepts:**
- Basic block structure
- Rescue on failure
- Always executes cleanup

### database-backup.yml
Production-ready database backup with error handling.

**Features:**
- Pre-backup validation
- Compressed backups
- Error logging
- Automatic cleanup

### web-deployment.yml
Web server deployment with automatic rollback.

**Features:**
- Config backup
- Config validation
- Service restart
- Rollback on failure

### rolling-deployment.yml
Zero-downtime rolling deployment across multiple servers.

**Features:**
- Serial execution
- Health checks
- Automatic rollback
- Load balancer integration

## 🎯 Learning Path

1. Start with `basic-block.yml` to understand structure
2. Progress to `database-backup.yml` for practical error handling
3. Study `web-deployment.yml` for rollback patterns
4. Master `rolling-deployment.yml` for production deployments

## 💡 Tips

- Always test with `--check` mode first
- Use `-vvv` for detailed debugging
- Start with one server before scaling
- Keep backup of working configs
