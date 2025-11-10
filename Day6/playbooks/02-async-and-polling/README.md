# Asynchronous Actions and Polling - Example Playbooks

This directory contains working examples for Topic 2: Asynchronous Actions and Polling.

## 📁 Files

- `fire-and-forget.yml` - Basic fire-and-forget pattern
- `polling-example.yml` - Async with polling
- `parallel-backups.yml` - Parallel backup operations
- `status-checking.yml` - Check async job status
- `system-updates.yml` - Async system updates
- `inventory.ini` - Sample inventory file
- `scripts/` - Helper scripts for testing

## 🚀 Quick Start

1. **Update inventory:**
   ```bash
   vi inventory.ini
   # Update with your server IPs
   ```

2. **Test fire-and-forget:**
   ```bash
   ansible-playbook -i inventory.ini fire-and-forget.yml
   ```

3. **Test polling:**
   ```bash
   ansible-playbook -i inventory.ini polling-example.yml
   ```

4. **Run parallel backups:**
   ```bash
   ansible-playbook -i inventory.ini parallel-backups.yml
   ```

## 📚 Examples Overview

### fire-and-forget.yml
Demonstrates launching tasks without waiting for completion.

**Key concepts:**
- `async: N poll: 0` pattern
- Background job execution
- Saving job IDs

### polling-example.yml
Shows how to monitor long-running tasks.

**Features:**
- Periodic status checks
- Progress monitoring
- Timeout handling

### parallel-backups.yml
Parallel backup operations across multiple servers.

**Features:**
- Simultaneous execution
- Progress tracking
- Result aggregation

### status-checking.yml
Check status of previously launched jobs.

**Features:**
- Job ID management
- Status queries
- Result retrieval

### system-updates.yml
Production-ready system update playbook.

**Features:**
- Package updates with async
- Reboot handling
- Health verification

## 🎯 Learning Path

1. Start with `fire-and-forget.yml` for basic async
2. Progress to `polling-example.yml` for monitoring
3. Study `parallel-backups.yml` for performance
4. Master `system-updates.yml` for production use

## 💡 Tips

- Use `poll: 0` for truly independent tasks
- Set realistic `async` timeout values
- Save job IDs for later status checks
- Use `strategy: free` for parallel execution
- Monitor critical operations with polling

## ⚡ Performance Comparison

**Sequential (slow):**
```bash
# Takes: 10 min × 5 servers = 50 minutes
ansible-playbook sequential-backup.yml
```

**Parallel async (fast):**
```bash
# Takes: ~10 minutes for all 5 servers
ansible-playbook -i inventory.ini parallel-backups.yml
```

## 🔧 Troubleshooting

**Task times out:**
- Increase `async` value
- Check task actually completes

**Lost job ID:**
- Save to file or variable
- Use `register` properly

**Can't check status:**
- Ensure same privileges (become)
- Job ID must be valid
