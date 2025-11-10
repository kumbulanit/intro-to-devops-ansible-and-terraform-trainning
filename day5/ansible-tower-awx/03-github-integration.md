# 🔗 Topic 3: GitHub Integration with Ansible Tower/AWX and Jenkins

## 🎯 Objective

Learn how to integrate Ansible Tower/AWX and Jenkins with GitHub to automatically pull and push Ansible playbooks, enabling GitOps workflows.

---

## 📖 Overview

Integrating your automation platform with GitHub enables:
- **Version control** for all playbooks
- **Automated deployment** on code push
- **Collaboration** through pull requests
- **Audit trail** of all changes
- **Rollback capability** to previous versions

---

## 🏗️ Architecture Patterns

### Pattern 1: Jenkins + GitHub (Recommended for CI/CD)

```plaintext
┌─────────────────────────────────────────┐
│           GitHub Repository             │
│   ├── playbooks/                       │
│   ├── roles/                           │
│   ├── inventories/                     │
│   ├── Jenkinsfile                      │
│   └── ansible.cfg                      │
└──────────────┬──────────────────────────┘
               │
               │ 1. Push/PR
               │ 2. Webhook
               │
┌──────────────▼──────────────────────────┐
│         Jenkins Master                   │
│   ├── GitHub Plugin                     │
│   ├── Ansible Plugin                    │
│   └── Multibranch Pipeline             │
└──────────────┬──────────────────────────┘
               │
               │ 3. Checkout code
               │ 4. Run ansible-playbook
               │
┌──────────────▼──────────────────────────┐
│        Target Servers                    │
└──────────────────────────────────────────┘
```

### Pattern 2: AWX/Tower + GitHub (Recommended for Ops)

```plaintext
┌─────────────────────────────────────────┐
│           GitHub Repository             │
│   ├── playbooks/                       │
│   ├── roles/                           │
│   └── inventories/                     │
└──────────────┬──────────────────────────┘
               │
               │ 1. AWX polls every 5 min
               │    OR webhook triggers
               │
┌──────────────▼──────────────────────────┐
│          AWX/Tower                       │
│   ├── Project (linked to repo)         │
│   ├── Job Template                      │
│   └── Webhook Receiver                 │
└──────────────┬──────────────────────────┘
               │
               │ 2. Run job template
               │
┌──────────────▼──────────────────────────┐
│        Target Servers                    │
└──────────────────────────────────────────┘
```

---

## 🔧 Part 1: Jenkins + GitHub Integration

### Step 1: Install Required Plugins

**Plugins to Install:**
1. GitHub Plugin
2. GitHub Branch Source Plugin
3. Ansible Plugin
4. Git Plugin (usually pre-installed)

```bash
# Install via Jenkins CLI (optional)
java -jar jenkins-cli.jar -s http://localhost:8080/ \
    install-plugin github github-branch-source ansible git
```

### Step 2: Configure GitHub Credentials in Jenkins

**Navigate to:** Jenkins → Manage Jenkins → Manage Credentials

**Add Credential:**

```yaml
Kind: Username with password
Username: your-github-username
Password: your-personal-access-token
ID: github-credentials
Description: GitHub Access Token
```

**Generate GitHub Personal Access Token:**

1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with scopes:
   - `repo` (full control)
   - `admin:repo_hook` (webhook management)

### Step 3: Create Repository Structure

```bash
# Create local repository
mkdir ansible-automation
cd ansible-automation

# Initialize repository
git init

# Create structure
mkdir -p {playbooks,roles,inventories/{production,staging},group_vars,host_vars}

# Create Jenkinsfile
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_FORCE_COLOR = 'true'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['staging', 'production'],
            description: 'Target environment'
        )
        choice(
            name: 'PLAYBOOK',
            choices: ['site.yml', 'webservers.yml', 'databases.yml'],
            description: 'Playbook to execute'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Validate Syntax') {
            steps {
                sh """
                    ansible-playbook \
                        --syntax-check \
                        playbooks/${params.PLAYBOOK}
                """
            }
        }
        
        stage('Dry Run') {
            steps {
                sh """
                    ansible-playbook \
                        -i inventories/${params.ENVIRONMENT}/hosts \
                        playbooks/${params.PLAYBOOK} \
                        --check \
                        --diff
                """
            }
        }
        
        stage('Approval') {
            when {
                expression { params.ENVIRONMENT == 'production' }
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
            }
        }
        
        stage('Deploy') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    sh """
                        ansible-playbook \
                            -i inventories/${params.ENVIRONMENT}/hosts \
                            playbooks/${params.PLAYBOOK} \
                            --private-key=\$SSH_KEY \
                            -v
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
        always {
            cleanWs()
        }
    }
}
EOF

# Create sample playbook
cat > playbooks/site.yml << 'EOF'
---
- name: Deploy Web Application
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install nginx
      ansible.builtin.package:
        name: nginx
        state: present
    
    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes
EOF

# Create inventory
cat > inventories/staging/hosts << 'EOF'
[webservers]
web1.staging.example.com
web2.staging.example.com

[databases]
db1.staging.example.com
EOF

# Commit and push
git add .
git commit -m "Initial Ansible automation structure"
git remote add origin https://github.com/YOUR_USERNAME/ansible-automation.git
git push -u origin main
```

### Step 4: Create Jenkins Multibranch Pipeline

**Jenkins → New Item:**

1. **Name:** `ansible-automation`
2. **Type:** Multibranch Pipeline
3. **Branch Sources:**
   - **Add source:** Git/GitHub
   - **Repository URL:** `https://github.com/YOUR_USERNAME/ansible-automation.git`
   - **Credentials:** Select `github-credentials`
4. **Build Configuration:**
   - **Mode:** by Jenkinsfile
   - **Script Path:** `Jenkinsfile`
5. **Scan Multibranch Pipeline Triggers:**
   - ✅ Periodically if not otherwise run
   - **Interval:** 5 minutes
6. **Save**

### Step 5: Configure GitHub Webhook (Auto-Trigger)

**In GitHub Repository:**

1. Settings → Webhooks → Add webhook
2. **Payload URL:** `http://JENKINS_URL/github-webhook/`
3. **Content type:** `application/json`
4. **Events:** Just the push event
5. **Active:** ✅
6. Add webhook

**Test:**
```bash
# Make a change
echo "# Test" >> README.md
git add README.md
git commit -m "Test webhook"
git push

# Jenkins should automatically trigger build
```

### Step 6: Advanced Jenkinsfile with Branch Strategy

```groovy
// Jenkinsfile
@Library('shared-library') _

def getEnvironment(branchName) {
    switch(branchName) {
        case 'main':
            return 'production'
        case 'develop':
            return 'staging'
        case ~/feature\/.*/:
            return 'development'
        default:
            return 'development'
    }
}

pipeline {
    agent any
    
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_FORCE_COLOR = 'true'
        DEPLOY_ENV = "${getEnvironment(env.BRANCH_NAME)}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Validate') {
            steps {
                sh 'find playbooks -name "*.yml" -exec ansible-playbook --syntax-check {} \\;'
                sh 'ansible-lint playbooks/*.yml || true'
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    ansible-playbook \
                        -i inventories/${DEPLOY_ENV}/hosts \
                        playbooks/site.yml \
                        --check \
                        --diff
                '''
            }
        }
        
        stage('Approval') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input(
                        message: "Deploy to ${DEPLOY_ENV}?",
                        ok: 'Deploy',
                        submitter: 'admin,devops-team'
                    )
                }
            }
        }
        
        stage('Deploy') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    ),
                    string(
                        credentialsId: 'vault-password',
                        variable: 'VAULT_PASS'
                    )
                ]) {
                    sh '''
                        echo "$VAULT_PASS" > .vault_pass
                        
                        ansible-playbook \
                            -i inventories/${DEPLOY_ENV}/hosts \
                            playbooks/site.yml \
                            --private-key=$SSH_KEY \
                            --vault-password-file=.vault_pass \
                            -v
                        
                        rm -f .vault_pass
                    '''
                }
            }
        }
        
        stage('Smoke Test') {
            steps {
                sh '''
                    ansible-playbook \
                        -i inventories/${DEPLOY_ENV}/hosts \
                        playbooks/smoke-test.yml
                '''
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: """
                    ✅ Deployment Successful
                    Environment: ${DEPLOY_ENV}
                    Branch: ${env.BRANCH_NAME}
                    Commit: ${env.GIT_COMMIT_MSG}
                    Build: ${env.BUILD_URL}
                """
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: """
                    ❌ Deployment Failed
                    Environment: ${DEPLOY_ENV}
                    Branch: ${env.BRANCH_NAME}
                    Build: ${env.BUILD_URL}
                """
            )
        }
    }
}
```

---

## 🔧 Part 2: AWX/Tower + GitHub Integration

### Step 1: Add GitHub Credential in AWX

**AWX UI → Credentials → Add:**

```yaml
Name: GitHub Access Token
Organization: Default
Credential Type: Source Control
Username: your-github-username
Password: your-personal-access-token (or SSH key)
```

### Step 2: Create Project (Link to GitHub Repo)

**AWX UI → Projects → Add:**

```yaml
Name: Ansible Automation Project
Organization: Default
SCM Type: Git
SCM URL: https://github.com/YOUR_USERNAME/ansible-automation.git
SCM Credential: GitHub Access Token
SCM Update Options:
  ✅ Clean
  ✅ Delete on Update
  ✅ Update Revision on Launch
Update on Launch: ✅
```

**Manual Sync:**
- Click **Sync** button to pull latest code

### Step 3: Create Inventory

**AWX UI → Inventories → Add:**

```yaml
Name: Production Servers
Organization: Default
```

**Add Hosts:**
```yaml
Host: web1.example.com
Host: web2.example.com
Host: db1.example.com
```

**Or use Inventory from Git:**

Create `inventories/production.yml` in GitHub:

```yaml
---
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
    databases:
      hosts:
        db1.example.com:
```

Then create **Inventory Source** in AWX:

```yaml
Source: Sourced from a Project
Project: Ansible Automation Project
Inventory File: inventories/production.yml
Update on Launch: ✅
```

### Step 4: Create Job Template

**AWX UI → Templates → Add Job Template:**

```yaml
Name: Deploy Web Application
Job Type: Run
Inventory: Production Servers
Project: Ansible Automation Project
Playbook: playbooks/site.yml
Credentials: SSH Credential
Extra Variables:
  env: production
Options:
  ✅ Enable Webhook
  ✅ Prompt on Launch (for variables)
```

### Step 5: Configure GitHub Webhook for AWX

**After creating Job Template:**

1. Click **Webhook** button in job template
2. Copy **Webhook URL** and **Webhook Key**

**In GitHub Repository:**

1. Settings → Webhooks → Add webhook
2. **Payload URL:** `https://AWX_URL/api/v2/job_templates/XX/github/`
3. **Content type:** `application/json`
4. **Secret:** Paste the Webhook Key
5. **Events:** Just the push event
6. **Active:** ✅

**Test:**
```bash
# Push a change
echo "# Test AWX webhook" >> README.md
git add README.md
git commit -m "Test AWX webhook"
git push

# Check AWX Jobs - should auto-trigger
```

### Step 6: Advanced Project with Multiple Playbooks

**Directory Structure:**

```
ansible-automation/
├── playbooks/
│   ├── site.yml                  # Main playbook
│   ├── webservers.yml           # Web tier
│   ├── databases.yml            # DB tier
│   └── loadbalancers.yml        # LB tier
├── roles/
│   ├── common/
│   ├── nginx/
│   ├── postgresql/
│   └── haproxy/
├── inventories/
│   ├── production/
│   │   ├── hosts
│   │   └── group_vars/
│   └── staging/
│       ├── hosts
│       └── group_vars/
├── group_vars/
│   ├── all.yml
│   └── webservers.yml
└── ansible.cfg
```

**Create Multiple Job Templates in AWX:**

1. **Deploy Full Stack** → `playbooks/site.yml`
2. **Deploy Web Tier** → `playbooks/webservers.yml`
3. **Deploy Database** → `playbooks/databases.yml`
4. **Deploy Load Balancer** → `playbooks/loadbalancers.yml`

---

## 🔄 Part 3: Pull Request Workflow

### GitHub Pull Request + Jenkins

**Jenkinsfile for PR validation:**

```groovy
pipeline {
    agent any
    
    stages {
        stage('PR Validation') {
            when {
                changeRequest()  // Only run on PRs
            }
            steps {
                // Syntax check
                sh 'ansible-playbook --syntax-check playbooks/*.yml'
                
                // Lint check
                sh 'ansible-lint playbooks/*.yml || true'
                
                // Dry run
                sh '''
                    ansible-playbook \
                        -i inventories/staging/hosts \
                        playbooks/site.yml \
                        --check
                '''
            }
        }
        
        stage('Comment on PR') {
            when {
                changeRequest()
            }
            steps {
                script {
                    def comment = """
                    ## Ansible Validation Results
                    
                    ✅ Syntax check passed
                    ✅ Lint check passed
                    ✅ Dry run completed
                    
                    Safe to merge!
                    """
                    
                    // Use GitHub API or plugin to comment
                    pullRequest.comment(comment)
                }
            }
        }
    }
}
```

### GitHub Branch Protection Rules

**Settings → Branches → Add rule:**

```yaml
Branch name pattern: main
Require pull request reviews before merging: ✅
Require status checks to pass before merging: ✅
  - Jenkins CI
Require branches to be up to date: ✅
Include administrators: ✅
```

---

## 🔐 Part 4: Secrets Management

### Option 1: Ansible Vault in Git

```bash
# Encrypt sensitive file
ansible-vault encrypt group_vars/production/vault.yml

# Add vault password to Jenkins
# Credentials → Add → Secret text
# ID: vault-password

# Use in Jenkinsfile
withCredentials([string(credentialsId: 'vault-password', variable: 'VAULT_PASS')]) {
    sh '''
        ansible-playbook site.yml \
            --vault-password-file=<(echo $VAULT_PASS)
    '''
}
```

### Option 2: Jenkins Credentials

```groovy
// Store secrets in Jenkins, inject at runtime
pipeline {
    stages {
        stage('Deploy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )
                ]) {
                    sh '''
                        ansible-playbook site.yml \
                            -e "db_user=$DB_USER" \
                            -e "db_password=$DB_PASS"
                    '''
                }
            }
        }
    }
}
```

### Option 3: AWX Credentials

AWX natively manages credentials and injects them at runtime without exposing values.

---

## 📊 Monitoring and Reporting

### Jenkins: HTML Publisher Plugin

```groovy
post {
    always {
        publishHTML(target: [
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'reports',
            reportFiles: 'ansible-report.html',
            reportName: 'Ansible Execution Report'
        ])
    }
}
```

### AWX: Notifications

**AWX → Notifications → Add:**

```yaml
Name: Slack Notifications
Type: Slack
URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
Messages:
  ✅ Job Start
  ✅ Job Success
  ❌ Job Failure
```

---

## ✅ Best Practices

### 1. **Repository Structure**
```
✅ Separate inventories by environment
✅ Use group_vars and host_vars
✅ Keep roles modular
✅ Include README with usage
✅ .gitignore for sensitive files
```

### 2. **Branch Strategy**
```
main → production
develop → staging
feature/* → development
```

### 3. **Commit Messages**
```bash
# Good
git commit -m "feat: add nginx SSL configuration"
git commit -m "fix: correct database connection string"
git commit -m "docs: update README with new variables"

# Bad
git commit -m "updates"
git commit -m "fixed stuff"
```

### 4. **Code Review**
```
✅ Require PR reviews
✅ Run automated checks
✅ Test in staging first
✅ Document changes
```

### 5. **Security**
```
✅ Never commit plaintext secrets
✅ Use Ansible Vault
✅ Rotate credentials regularly
✅ Audit access logs
```

---

## 🎯 Complete Example

See `04-complete-github-jenkins-example.md` for a full working example with:
- Complete repository structure
- Jenkinsfile with all stages
- Multiple playbooks
- Dynamic inventories
- Vault integration
- Webhook configuration

---

## 🔗 Next Steps

Continue to **Topic 4: AWX Installation** to set up your AWX instance locally or on OpenStack.
