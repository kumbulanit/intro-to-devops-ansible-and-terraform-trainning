# 🗼 Topic 1: What is Ansible Tower and AWX

## 🎯 Objective

Understand Ansible Tower (Red Hat) and AWX (open-source upstream) - their features, architecture, benefits, and use cases in enterprise automation.

---

## 📖 What is Ansible Tower?

**Ansible Tower** is Red Hat's commercial enterprise web-based solution for managing Ansible automation at scale.

**AWX** is the open-source upstream project for Ansible Tower, providing similar functionality for free.

### Key Features

#### 1. **Web-Based User Interface**
- Graphical dashboard for managing automation
- No need for command-line access
- Visual job monitoring and reporting

#### 2. **Role-Based Access Control (RBAC)**
- Granular permissions management
- Team-based access control
- Audit trails for compliance

#### 3. **Job Scheduling**
- Schedule playbook runs
- Recurring job execution
- Dependency management

#### 4. **Inventory Management**
- Dynamic inventory sync
- Cloud provider integration
- Custom inventory sources

#### 5. **Credential Management**
- Secure credential storage
- Encrypted vault integration
- Credential sharing across teams

#### 6. **REST API**
- Full API access
- Integration with external systems
- Automation of Tower itself

#### 7. **Workflow Builder**
- Visual workflow design
- Conditional execution
- Multi-playbook orchestration

#### 8. **Job Templates**
- Reusable playbook configurations
- Parameter validation
- Survey forms for user input

---

## 🏗️ Architecture

### Ansible Tower Architecture

```plaintext
┌─────────────────────────────────────────────────────┐
│                  Load Balancer                      │
│              (HAProxy/Nginx - Optional)             │
└─────────────────────┬───────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
┌───────▼──────┐           ┌────────▼────────┐
│  Tower Node  │           │  Tower Node     │
│  (Primary)   │           │  (Secondary)    │
│              │           │                 │
│ - Web UI     │           │ - Web UI        │
│ - API        │           │ - API           │
│ - Task Mgr   │           │ - Task Mgr      │
└──────┬───────┘           └────────┬────────┘
       │                            │
       └────────────┬───────────────┘
                    │
        ┌───────────▼──────────────┐
        │   PostgreSQL Database    │
        │   - Jobs                 │
        │   - Inventory            │
        │   - Credentials          │
        │   - Activity Logs        │
        └──────────────────────────┘
                    │
        ┌───────────▼──────────────┐
        │   Redis/RabbitMQ         │
        │   (Message Queue)        │
        └──────────────────────────┘
                    │
        ┌───────────▼──────────────┐
        │   Execution Nodes        │
        │   (Optional Isolated)    │
        │   - Run playbooks        │
        │   - Remote execution     │
        └──────────────────────────┘
```

### AWX Architecture

```plaintext
┌─────────────────────────────────────┐
│         AWX Web Container           │
│  - Django Application               │
│  - REST API                         │
│  - Web Interface                    │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      AWX Task Container             │
│  - Job Execution                    │
│  - Ansible Runner                   │
│  - Inventory Updates                │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│       PostgreSQL Database           │
│  - Configuration Data               │
│  - Job History                      │
└─────────────────────────────────────┘
             │
┌────────────▼────────────────────────┐
│          Redis Cache                │
│  - Session Management               │
│  - Task Queue                       │
└─────────────────────────────────────┘
```

---

## 💡 Key Concepts

### 1. **Organizations**
Logical collections of users, teams, projects, and inventories.

```
Organization: MyCompany
├── Teams
│   ├── DevOps Team
│   ├── Network Team
│   └── Security Team
├── Users
├── Projects
└── Inventories
```

### 2. **Projects**
Collections of Ansible playbooks from source control (Git, SVN, etc.).

**Example Project:**
```yaml
Name: Web Application Deployment
SCM Type: Git
SCM URL: https://github.com/mycompany/ansible-playbooks.git
SCM Branch: main
Update on Launch: Yes
```

### 3. **Inventories**
Lists of hosts organized into groups.

**Types:**
- Static inventory
- Dynamic inventory (cloud, CMDB)
- Smart inventory (filtered hosts)

### 4. **Job Templates**
Definitions for running Ansible playbooks.

**Example Job Template:**
```yaml
Name: Deploy Web Application
Project: Web Application Deployment
Playbook: site.yml
Inventory: Production Servers
Credentials: SSH Key
Variables:
  app_version: 1.2.3
  environment: production
```

### 5. **Credentials**
Secure storage for authentication.

**Credential Types:**
- Machine (SSH)
- Source Control (Git)
- Cloud (AWS, Azure, OpenStack)
- Network
- Vault Password

### 6. **Workflows**
Chain multiple job templates together.

```plaintext
Workflow: Full Stack Deployment
│
├─► Deploy Database (on success)
│   │
│   ├─► Deploy Application (on success)
│   │   │
│   │   ├─► Run Tests (on success)
│   │   │   │
│   │   │   ├─► Deploy Load Balancer (on success)
│   │   │   └─► Rollback (on failure)
│   │   └─► Rollback (on failure)
│   └─► Notify Team (on failure)
└─► Notify Team (on failure)
```

---

## 🆚 Ansible Tower vs AWX

| Feature | Ansible Tower | AWX |
|---------|---------------|-----|
| **License** | Commercial (Red Hat) | Open Source (Apache 2.0) |
| **Cost** | Paid subscription | Free |
| **Support** | Red Hat Enterprise Support | Community |
| **Updates** | Stable, tested releases | Rapid development |
| **LTS** | Long-term support | Latest features |
| **Installation** | Bundled installer | Container-based |
| **Upgrades** | Managed, predictable | Frequent, manual |
| **Documentation** | Comprehensive | Community-driven |
| **Best For** | Enterprise production | Development, testing, cost-sensitive |

---

## 📊 Benefits of Using Tower/AWX

### For Organizations

1. **Centralized Management**
   - Single pane of glass for all automation
   - Consistent execution across teams
   - Audit and compliance tracking

2. **Security & Compliance**
   - Encrypted credential storage
   - RBAC for access control
   - Complete audit logs

3. **Scalability**
   - Manage thousands of nodes
   - Distributed execution
   - High availability support

4. **Collaboration**
   - Team-based organization
   - Shared projects and inventories
   - Approval workflows

### For DevOps Teams

1. **Self-Service**
   - Non-experts can run playbooks
   - Validated parameters
   - Reduced bottlenecks

2. **Visibility**
   - Real-time job status
   - Historical reporting
   - Performance metrics

3. **Efficiency**
   - Reusable templates
   - Scheduled automation
   - Workflow orchestration

---

## 🔧 Use Cases

### 1. **Configuration Management**
```yaml
Job Template: Configure Web Servers
- Ensure nginx installed
- Deploy configuration files
- Restart services if needed
- Validate configuration
```

### 2. **Application Deployment**
```yaml
Workflow: Deploy Application
1. Backup current version
2. Deploy new version to staging
3. Run integration tests
4. Deploy to production (if tests pass)
5. Run smoke tests
6. Notify team
```

### 3. **Cloud Provisioning**
```yaml
Job Template: Provision OpenStack Infrastructure
- Create networks and subnets
- Launch instances
- Configure security groups
- Assign floating IPs
- Configure monitoring
```

### 4. **Security Compliance**
```yaml
Job Template: Security Hardening
- Apply CIS benchmarks
- Update packages
- Configure firewall rules
- Disable unused services
- Generate compliance report
```

### 5. **Disaster Recovery**
```yaml
Workflow: DR Failover
1. Verify primary site status
2. Promote replica database
3. Update DNS records
4. Start application servers
5. Validate services
6. Notify stakeholders
```

---

## 📈 Tower/AWX Dashboard Overview

### Main Dashboard Components

#### 1. **Job Activity**
```
Recent Jobs:
✅ Deploy Production - SUCCESS (5m ago)
✅ Backup Database - SUCCESS (15m ago)
⚠️  Update Staging - RUNNING
❌ Security Scan - FAILED (1h ago)
```

#### 2. **Inventory Status**
```
Total Hosts: 150
├─ Available: 145
├─ Failed: 3
└─ Unreachable: 2
```

#### 3. **Project Sync Status**
```
Projects:
✅ Web Apps - Synced (1m ago)
✅ Database - Synced (5m ago)
⏱️ Monitoring - Syncing...
```

#### 4. **Scheduled Jobs**
```
Upcoming:
- Daily Backup (in 2h)
- Weekly Patching (in 1d)
- Monthly Report (in 7d)
```

---

## 🛠️ Basic Tower/AWX Operations

### Creating a Job Template (Web UI)

1. **Navigate to Templates**
   - Click "Templates" in left menu
   - Click "Add" → "Job Template"

2. **Configure Template**
   ```
   Name: Deploy Web Application
   Job Type: Run
   Inventory: Production Servers
   Project: My Playbooks
   Playbook: site.yml
   Credentials: Production SSH Key
   ```

3. **Add Variables**
   ```yaml
   app_version: "{{ app_version }}"
   environment: production
   deploy_strategy: rolling
   ```

4. **Add Survey (Optional)**
   ```
   Question: Application Version
   Type: Text
   Variable: app_version
   Default: 1.0.0
   Required: Yes
   ```

5. **Save and Launch**

### Using the API

```bash
# Get authentication token
curl -k -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' \
  https://tower.example.com/api/v2/authtoken/

# Launch a job template
curl -k -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  https://tower.example.com/api/v2/job_templates/10/launch/

# Check job status
curl -k -H "Authorization: Bearer YOUR_TOKEN" \
  https://tower.example.com/api/v2/jobs/100/
```

---

## 🔍 When to Use Tower/AWX

### ✅ Good Use Cases

- Large enterprise with multiple teams
- Need for RBAC and audit trails
- Non-technical users need to run playbooks
- Compliance and security requirements
- Scheduled automation at scale
- Need for centralized management

### ❌ When to Consider Alternatives

- Small team (< 5 people)
- All users are technical
- Limited budget (consider AWX)
- Heavy CI/CD integration needed (consider Jenkins)
- Existing investment in other tools
- Simple automation needs

---

## 💰 Pricing (Ansible Tower)

**Red Hat Ansible Automation Platform:**
- Standard: ~$5,000 per 100 nodes/year
- Premium: ~$14,000 per 100 nodes/year
- Includes support and updates

**AWX:**
- Free and open source
- Community support
- Self-managed

---

## 🎓 Tower/AWX Terminology

| Term | Description |
|------|-------------|
| **Organization** | Top-level container for resources |
| **Project** | Collection of playbooks from SCM |
| **Inventory** | List of managed hosts |
| **Job Template** | Saved configuration for running playbooks |
| **Workflow** | Chain of job templates |
| **Credential** | Authentication information |
| **Survey** | Form for collecting job parameters |
| **Notification** | Alert sent on job completion |
| **Schedule** | Automated job execution |
| **Activity Stream** | Audit log of all changes |

---

## 📚 Learning Resources

### Official Documentation
- [Ansible Tower Documentation](https://docs.ansible.com/ansible-tower/)
- [AWX GitHub Repository](https://github.com/ansible/awx)
- [AWX Operator](https://github.com/ansible/awx-operator)

### Training
- Red Hat DO467: Advanced Automation with Ansible Tower
- Red Hat DO374: Developing Automation with Ansible

### Community
- [AWX Mailing List](https://groups.google.com/g/awx-project)
- [Ansible Community Forum](https://forum.ansible.com/)
- [Reddit r/ansible](https://reddit.com/r/ansible)

---

## ✅ Summary

**Ansible Tower/AWX provides:**
- ✅ Centralized automation platform
- ✅ Web-based user interface
- ✅ Role-based access control
- ✅ Secure credential management
- ✅ Job scheduling and workflows
- ✅ REST API integration
- ✅ Audit and compliance features

**Choose Tower if:**
- Enterprise environment
- Need commercial support
- Require stability and LTS

**Choose AWX if:**
- Cost-sensitive
- Development/testing
- Want latest features
- Comfortable with self-management

---

## 🔗 Next Steps

Continue to **Topic 2: Jenkins vs Tower** to understand when to use Jenkins as an alternative automation platform.
