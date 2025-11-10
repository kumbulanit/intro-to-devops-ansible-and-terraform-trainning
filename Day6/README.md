# Day 6: Advanced Ansible Techniques

## 📚 Course Overview

Welcome to Day 6 of the Ansible training! This day focuses on advanced Ansible techniques that enable you to write more robust, efficient, and production-ready playbooks.

### 🎯 Learning Objectives

By the end of Day 6, you will be able to:
- ✅ Implement error handling with blocks and rollback mechanisms
- ✅ Execute asynchronous tasks and manage long-running operations
- ✅ Use check mode for safe playbook testing
- ✅ Debug playbooks interactively using the Ansible debugger
- ✅ Delegate tasks and implement rolling updates
- ✅ Configure environment variables and work with proxies
- ✅ Manage language-specific version managers (nvm, rbenv, pyenv)
- ✅ Handle errors gracefully in production environments

### 📋 Prerequisites

Before starting Day 6, ensure you have:
- ✅ Completed Day 1-5 or equivalent Ansible experience
- ✅ OpenStack instance accessible (from Day 4)
- ✅ SSH access to target hosts
- ✅ Ansible 2.9+ installed
- ✅ Basic understanding of YAML and Jinja2
- ✅ Familiarity with Linux command line

### 🗂️ Course Structure

```
Day6/
├── README.md (this file)
├── 01-blocks-and-rollback.md
├── 02-async-and-polling.md
├── 03-check-mode-dry-run.md
├── 04-playbook-debugger.md
├── 05-delegation-rolling-updates.md
├── 06-environment-and-proxies.md
├── 07-version-managers.md
├── 08-error-handling.md
├── exercise-day6.md
├── playbooks/
│   ├── 01-blocks-rescue-always/
│   ├── 02-async-operations/
│   ├── 03-check-mode-examples/
│   ├── 04-debugger-examples/
│   ├── 05-delegation-rolling/
│   ├── 06-environment-proxy/
│   ├── 07-version-managers/
│   └── 08-error-handling/
└── labs/
    ├── lab1-blocks-rescue.md
    ├── lab2-async-tasks.md
    ├── lab3-check-mode.md
    ├── lab4-debugger.md
    ├── lab5-rolling-updates.md
    ├── lab6-proxy-setup.md
    ├── lab7-nvm-rbenv.md
    └── lab8-error-strategies.md
```

### 📖 Topics Covered

#### 1. Blocks & Rollback (90 minutes)
- Block structure and usage
- Rescue blocks for error handling
- Always blocks for cleanup
- Rollback strategies
- **Lab**: Database migration with rollback

#### 2. Asynchronous Actions and Polling (75 minutes)
- Long-running tasks
- Async and poll parameters
- Fire-and-forget tasks
- Checking async task status
- **Lab**: Parallel backups and downloads

#### 3. Check Mode - "Dry Run" (60 minutes)
- Using --check flag
- Check mode in tasks
- Diff mode
- Conditional check mode
- **Lab**: Safe deployment testing

#### 4. Playbook Debugger (90 minutes)
- Interactive debugging
- Breakpoints and watchpoints
- Variable inspection
- Task retry and skip
- **Lab**: Debug complex deployment

#### 5. Delegation, Rolling Updates, and Local Actions (120 minutes)
- Task delegation
- Run_once directive
- Serial execution
- Rolling updates
- Local actions
- **Lab**: Zero-downtime deployment

#### 6. Setting the Environment (60 minutes)
- Environment variables
- Proxy configuration
- Per-task environment
- System-wide settings
- **Lab**: Deploy behind corporate proxy

#### 7. Working With Language-Specific Version Managers (90 minutes)
- NVM (Node Version Manager)
- RVM/rbenv (Ruby)
- pyenv (Python)
- jenv (Java)
- **Lab**: Multi-version application deployment

#### 8. Error Handling In Playbooks (90 minutes)
- Failed_when and changed_when
- Ignore_errors
- Any_errors_fatal
- Max_fail_percentage
- Handlers and errors
- **Lab**: Production-grade error handling

### 🖥️ Lab Environment

All labs use your OpenStack instance from Day 4. For advanced topics, you may need:

```bash
# Verify OpenStack instance
openstack server list

# Test connectivity
ansible all -i inventory.ini -m ping

# Check Ansible version (need 2.9+)
ansible --version
```

### ⏱️ Estimated Time

| Topic | Theory | Lab | Total |
|-------|--------|-----|-------|
| Blocks & Rollback | 45 min | 45 min | 90 min |
| Async & Polling | 35 min | 40 min | 75 min |
| Check Mode | 30 min | 30 min | 60 min |
| Debugger | 45 min | 45 min | 90 min |
| Delegation & Rolling | 60 min | 60 min | 120 min |
| Environment & Proxies | 30 min | 30 min | 60 min |
| Version Managers | 45 min | 45 min | 90 min |
| Error Handling | 45 min | 45 min | 90 min |
| **Total** | **5h 35m** | **5h 40m** | **11h 15m** |

*Recommended: 2 full training days with breaks*

### 🚀 Quick Start

#### Option 1: Follow in Order (Recommended)
```bash
cd ~/ansible_training/Day6/

# Start with topic 1
cat 01-blocks-and-rollback.md

# Complete lab 1
cd labs/
cat lab1-blocks-rescue.md

# Test playbooks
cd ../playbooks/01-blocks-rescue-always/
ansible-playbook -i inventory.ini example.yml
```

#### Option 2: Jump to Specific Topic
```bash
# Jump to specific topic (e.g., Async)
cd ~/ansible_training/Day6/
cat 02-async-and-polling.md

# Try the lab
cd labs/
cat lab2-async-tasks.md
```

#### Option 3: Hands-On Practice
```bash
# Go straight to playbooks
cd ~/ansible_training/Day6/playbooks/

# Each directory has working examples
ls -la
```

### 📝 Daily Exercise

At the end of Day 6, complete the comprehensive exercise:

```bash
cd ~/ansible_training/Day6/
cat exercise-day6.md
```

**Exercise**: Build a production-grade deployment playbook incorporating:
- Block-based error handling
- Async operations for parallel tasks
- Check mode validation
- Rolling updates with delegation
- Proper error strategies

### 🎓 Learning Path

```
┌─────────────────────────────────────────┐
│  Day 6: Advanced Ansible Techniques     │
└─────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────┐
    │  Morning Session (4 hours)  │
    ├─────────────────────────────┤
    │  • Blocks & Rollback        │
    │  • Async & Polling          │
    │  • Check Mode               │
    │  • Playbook Debugger        │
    └─────────────────────────────┘
                  ↓
         ☕ Lunch Break
                  ↓
    ┌─────────────────────────────┐
    │  Afternoon Session (4h)     │
    ├─────────────────────────────┤
    │  • Delegation & Rolling     │
    │  • Environment & Proxies    │
    │  • Version Managers         │
    │  • Error Handling           │
    └─────────────────────────────┘
                  ↓
    ┌─────────────────────────────┐
    │  Final Exercise (2-3 hours) │
    ├─────────────────────────────┤
    │  Build production playbook  │
    │  with all techniques        │
    └─────────────────────────────┘
```

### 💡 Best Practices Covered

Throughout Day 6, you'll learn:

1. **Error Handling**
   - Always use blocks for critical operations
   - Implement proper rollback mechanisms
   - Use rescue blocks for graceful degradation

2. **Performance**
   - Async for long-running tasks
   - Rolling updates for zero-downtime
   - Parallel execution strategies

3. **Safety**
   - Always test with --check first
   - Use debugger for complex issues
   - Implement max_fail_percentage

4. **Maintainability**
   - Clear error messages
   - Proper logging
   - Documented rollback procedures

5. **Production-Ready**
   - Environment variable management
   - Proxy configuration
   - Version manager integration

### 🔗 Related Topics

**From Previous Days:**
- Day 4: OpenStack instance management
- Day 5: Ansible Roles for code organization

**Next Steps:**
- Ansible Tower/AWX (Day 7)
- CI/CD Integration (Day 8)
- Production Deployment Strategies

### 📚 Additional Resources

- **Official Docs**: [Ansible Documentation - Advanced Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_advanced_syntax.html)
- **Error Handling**: [Ansible Error Handling Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)
- **Async Actions**: [Asynchronous Actions and Polling](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
- **Debugger**: [Playbook Debugger](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html)

### 🆘 Getting Help

If you encounter issues:

1. **Check the troubleshooting section** in each topic
2. **Review example playbooks** in the playbooks/ directory
3. **Use the debugger** to step through problematic tasks
4. **Test with --check** before making changes

### ✅ Completion Checklist

Mark off as you complete each section:

- [ ] 1. Blocks & Rollback - Theory
- [ ] 1. Blocks & Rollback - Lab
- [ ] 2. Async & Polling - Theory
- [ ] 2. Async & Polling - Lab
- [ ] 3. Check Mode - Theory
- [ ] 3. Check Mode - Lab
- [ ] 4. Playbook Debugger - Theory
- [ ] 4. Playbook Debugger - Lab
- [ ] 5. Delegation & Rolling - Theory
- [ ] 5. Delegation & Rolling - Lab
- [ ] 6. Environment & Proxies - Theory
- [ ] 6. Environment & Proxies - Lab
- [ ] 7. Version Managers - Theory
- [ ] 7. Version Managers - Lab
- [ ] 8. Error Handling - Theory
- [ ] 8. Error Handling - Lab
- [ ] Final Exercise
- [ ] Review and Practice

### 🎯 Success Criteria

You've successfully completed Day 6 when you can:

✅ Write playbooks with proper error handling using blocks  
✅ Implement async operations for parallel execution  
✅ Test changes safely using check mode  
✅ Debug complex playbooks interactively  
✅ Perform rolling updates with zero downtime  
✅ Configure environment variables and proxies  
✅ Deploy applications using version managers  
✅ Handle errors gracefully in production scenarios  

---

**Ready to become an Ansible expert? Let's begin with Topic 1: Blocks & Rollback! 🚀**

*Last Updated: November 10, 2025*
