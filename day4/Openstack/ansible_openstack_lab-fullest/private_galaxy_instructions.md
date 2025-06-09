# 📦 Publishing Roles to Private Ansible Galaxy

## Step 1: Install Ansible Galaxy CLI Support
```bash
pip install ansible
```

## Step 2: Create Your Private Galaxy Repo
Use something like GitLab, GitHub Enterprise, or a local Artifactory.

## Step 3: Tag and Push Role
```bash
cd roles/basic_vm
git init
git remote add origin <your-private-repo-url>
git add .
git commit -m "initial"
git tag 1.0.0
git push --tags origin main
```

## Step 4: Use with Requirements File
```yaml
# requirements.yml
roles:
  - name: basic_vm
    src: git+<your-private-repo-url>
    version: 1.0.0
```

## Step 5: Install Role
```bash
ansible-galaxy install -r requirements.yml
```
