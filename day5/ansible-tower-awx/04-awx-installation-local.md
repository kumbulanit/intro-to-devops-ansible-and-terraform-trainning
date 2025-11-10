# 🖥️ Topic 4: AWX Installation on Local Ubuntu

## 🎯 Objective

Install Ansible AWX on a local Ubuntu machine using Docker Compose (recommended method).

---

## 📋 Prerequisites

### System Requirements

```yaml
Operating System: Ubuntu 20.04 LTS or 22.04 LTS
RAM: Minimum 4GB (8GB recommended)
CPU: 2+ cores
Disk Space: 20GB free
```

### Software Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git
- Python 3.8+

---

## 🚀 Installation Methods

### Method 1: AWX Operator on Docker Compose (Recommended)

This is the official and easiest method for local development.

---

## 📦 Step-by-Step Installation

### Step 1: Update System

```bash
# Update package index
sudo apt update

# Upgrade existing packages
sudo apt upgrade -y

# Install basic utilities
sudo apt install -y curl git vim
```

### Step 2: Install Docker

```bash
# Remove old versions (if any)
sudo apt remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
# Expected: Docker version 24.0.x

# Add your user to docker group (to run docker without sudo)
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Test Docker
docker run hello-world
```

### Step 3: Install Docker Compose

```bash
# Docker Compose v2 is included with docker-compose-plugin
# Verify installation
docker compose version
# Expected: Docker Compose version v2.xx.x

# If you need standalone docker-compose:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### Step 4: Install AWX Operator

```bash
# Create AWX directory
mkdir -p ~/awx-deployment
cd ~/awx-deployment

# Clone AWX Operator repository
git clone https://github.com/ansible/awx-operator.git
cd awx-operator

# Check latest stable version
git tag | grep -v "rc" | sort -V | tail -n 1
# Example output: 2.7.2

# Checkout latest stable version
git checkout 2.7.2  # Use the version from previous command
```

### Step 5: Create AWX Configuration

```bash
# Create deployment directory
cd ~/awx-deployment
mkdir awx-instance
cd awx-instance

# Create kustomization.yaml
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.7.2
  - awx.yaml

# Set images to pull from Docker Hub (for Docker Compose)
images:
  - name: quay.io/ansible/awx-operator
    newName: quay.io/ansible/awx-operator
    newTag: 2.7.2

# Namespace where AWX will be deployed
namespace: awx
EOF

# Create AWX instance definition
cat > awx.yaml << 'EOF'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: NodePort
  ingress_type: none
  hostname: localhost
  nodeport_port: 30080
  
  # Admin credentials
  admin_user: admin
  admin_password_secret: awx-admin-password
  
  # PostgreSQL settings
  postgres_storage_class: local-path
  postgres_storage_requirements:
    requests:
      storage: 8Gi
  
  # Project data storage
  projects_persistence: true
  projects_storage_class: local-path
  projects_storage_size: 8Gi
  
  # Resource requirements
  web_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 1000m
      memory: 4Gi
  
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 1000m
      memory: 4Gi
EOF

# Create admin password secret
cat > admin-password-secret.yaml << 'EOF'
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
  namespace: awx
stringData:
  password: YourSecurePassword123!
type: Opaque
EOF

# Add secret to kustomization
cat >> kustomization.yaml << 'EOF'

secretGenerator:
  - name: awx-admin-password
    literals:
      - password=YourSecurePassword123!
EOF
```

### Step 6: Install Minikube (For Kubernetes)

AWX Operator requires Kubernetes. For local development, use Minikube:

```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube with Docker driver
minikube start --driver=docker --cpus=4 --memory=8192

# Verify
minikube status

# Enable metrics (optional)
minikube addons enable metrics-server
```

### Step 7: Deploy AWX

```bash
cd ~/awx-deployment/awx-instance

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Create namespace
kubectl create namespace awx

# Deploy AWX Operator
kubectl apply -k .

# Wait for operator to be ready (takes 2-5 minutes)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-operator -n awx --timeout=300s

# Check operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx -c awx-manager

# Wait for AWX deployment (takes 5-10 minutes)
kubectl get pods -n awx -w

# You should see pods like:
# awx-operator-controller-manager-xxxxx
# awx-postgres-xxxxx
# awx-web-xxxxx
# awx-task-xxxxx
```

### Step 8: Access AWX

```bash
# Get AWX service URL
minikube service awx-service -n awx --url

# Example output: http://192.168.49.2:30080

# Or use port forwarding
kubectl port-forward svc/awx-service -n awx 8080:80

# Access at: http://localhost:8080

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
# Output: YourSecurePassword123!
```

**Login Credentials:**
- **Username:** `admin`
- **Password:** `YourSecurePassword123!` (or what you set)

---

## 🐳 Alternative: Docker Compose Only (Simplified)

If you want to avoid Kubernetes complexity:

### Create Standalone Docker Compose Setup

```bash
# Create directory
mkdir -p ~/awx-docker
cd ~/awx-docker

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:13
    container_name: awx-postgres
    environment:
      POSTGRES_DB: awx
      POSTGRES_USER: awx
      POSTGRES_PASSWORD: awxpass
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres-data:/var/lib/postgresql/data/pgdata
    networks:
      - awx-network
    restart: unless-stopped

  redis:
    image: redis:7
    container_name: awx-redis
    networks:
      - awx-network
    restart: unless-stopped

  awx-web:
    image: quay.io/ansible/awx:23.5.0
    container_name: awx-web
    hostname: awx-web
    user: root
    environment:
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: awx
      DATABASE_USER: awx
      DATABASE_PASSWORD: awxpass
      REDIS_HOST: redis
      REDIS_PORT: 6379
      AWX_ADMIN_USER: admin
      AWX_ADMIN_PASSWORD: YourSecurePassword123!
    volumes:
      - awx-projects:/var/lib/awx/projects
    ports:
      - "8080:8052"
    networks:
      - awx-network
    depends_on:
      - postgres
      - redis
    command: >
      bash -c "
      awx-manage migrate --noinput &&
      awx-manage create_preload_data &&
      awx-manage provision_instance --hostname=awx-web &&
      awx-manage register_queue --queuename=default --hostnames=awx-web &&
      supervisord -c /etc/supervisord.conf
      "
    restart: unless-stopped

  awx-task:
    image: quay.io/ansible/awx:23.5.0
    container_name: awx-task
    hostname: awx-task
    user: root
    environment:
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: awx
      DATABASE_USER: awx
      DATABASE_PASSWORD: awxpass
      REDIS_HOST: redis
      REDIS_PORT: 6379
    volumes:
      - awx-projects:/var/lib/awx/projects
    networks:
      - awx-network
    depends_on:
      - postgres
      - redis
      - awx-web
    command: >
      bash -c "
      awx-manage provision_instance --hostname=awx-task &&
      awx-manage register_queue --queuename=default --hostnames=awx-task &&
      supervisord -c /etc/supervisord.conf
      "
    restart: unless-stopped

volumes:
  postgres-data:
  awx-projects:

networks:
  awx-network:
    driver: bridge
EOF

# Start AWX
docker compose up -d

# Check logs
docker compose logs -f

# Wait for services to be ready (5-10 minutes)
docker compose ps

# Access AWX at: http://localhost:8080
# Username: admin
# Password: YourSecurePassword123!
```

---

## ✅ Verification

### Check AWX Status

```bash
# Check pods (Minikube method)
kubectl get pods -n awx

# Check services
kubectl get svc -n awx

# Check Docker containers (Docker Compose method)
docker ps

# Expected containers:
# - awx-web
# - awx-task
# - awx-postgres
# - awx-redis
```

### Test Web Interface

1. Open browser: `http://localhost:8080`
2. Login with admin credentials
3. Navigate to: **Dashboard**
4. You should see AWX welcome screen

### Test API

```bash
# Get auth token
curl -X POST http://localhost:8080/api/v2/tokens/ \
  -u admin:YourSecurePassword123! \
  -H "Content-Type: application/json" \
  -d '{}'

# Test API endpoint
curl -X GET http://localhost:8080/api/v2/ping/ \
  -u admin:YourSecurePassword123!

# Expected output: {"version": "23.5.0", ...}
```

---

## 🔧 Post-Installation Configuration

### Configure Settings

1. **Organization:**
   - AWX UI → Organizations → Add
   - Name: `Default`

2. **Credential:**
   - AWX UI → Credentials → Add
   - Name: `SSH Key`
   - Type: `Machine`
   - Username: `ubuntu`
   - SSH Private Key: Paste your private key

3. **Inventory:**
   - AWX UI → Inventories → Add
   - Name: `Local Servers`

4. **Project:**
   - AWX UI → Projects → Add
   - Name: `Ansible Playbooks`
   - SCM Type: `Git`
   - SCM URL: `https://github.com/YOUR_REPO/ansible-playbooks.git`

---

## 🛠️ Troubleshooting

### Issue: Pods not starting

```bash
# Check events
kubectl get events -n awx --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n awx <pod-name>

# Describe pod for details
kubectl describe pod -n awx <pod-name>
```

### Issue: Out of memory

```bash
# Increase Minikube memory
minikube stop
minikube delete
minikube start --driver=docker --cpus=4 --memory=10240
```

### Issue: Cannot access AWX

```bash
# Check if service is running
kubectl get svc -n awx

# Test port forward
kubectl port-forward svc/awx-service -n awx 8080:80

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

### Issue: Docker Compose method not working

```bash
# Check logs
docker compose logs awx-web
docker compose logs awx-task

# Restart services
docker compose restart

# Full reset
docker compose down -v
docker compose up -d
```

---

## 📚 Next Steps

- **Configure OpenStack integration:** See `05-awx-installation-openstack.md`
- **Add inventories:** Link to OpenStack dynamic inventory
- **Create job templates:** Set up automated deployments
- **Configure RBAC:** Create teams and assign permissions

---

## 🔗 Useful Commands

```bash
# Minikube
minikube start                 # Start Minikube
minikube stop                  # Stop Minikube
minikube delete                # Delete Minikube cluster
minikube dashboard             # Open Kubernetes dashboard

# kubectl
kubectl get all -n awx         # View all resources
kubectl logs -f <pod> -n awx   # Stream logs
kubectl exec -it <pod> -n awx bash  # Shell into pod

# Docker Compose
docker compose up -d           # Start services
docker compose down            # Stop services
docker compose logs -f         # View logs
docker compose restart         # Restart services
```

---

## 🔗 Next Topic

Continue to **Topic 5: AWX Installation on OpenStack** to deploy AWX on an OpenStack VM.
