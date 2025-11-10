# Grant Admin Access to OpenStack Users

## Quick Start

If you're getting **403 Forbidden** or **Access Denied** errors when running playbooks, run this script on your **OpenStack controller node**:

```bash
./grant_admin_access.sh
```

## What This Script Does

1. Connects to OpenStack using admin credentials
2. Lists all users in the system
3. Lists all projects in the system
4. Grants `admin` role to every user on every project
5. Specifically ensures `demo` user has full admin access

## When to Use This

Use this script when you see errors like:

```
fatal: [localhost]: FAILED! => {"changed": false, "msg": "ForbiddenException: 403: Client Error...Access was denied to this resource."}
```

This typically happens with:
- Volume creation
- Network creation
- Security group management
- VM launching
- Floating IP allocation

## Prerequisites

The script must be run on the OpenStack controller node with:

1. **OpenStack CLI installed**:
   ```bash
   pip install python-openstackclient
   ```

2. **Admin credentials available** (the script uses these defaults):
   - Username: `admin`
   - Password: `secret`
   - Project: `admin`
   - Auth URL: `http://10.0.3.15/identity`

## Manual Alternative

If you only want to grant admin to the `demo` user (instead of all users):

```bash
# Source admin credentials
export OS_AUTH_URL=http://10.0.3.15/identity
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=secret
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3

# Grant admin role to demo user
openstack role add --user demo --project demo admin

# Verify
openstack role assignment list --user demo --project demo --names
```

## After Running the Script

1. The script updates permissions on the OpenStack server
2. No need to modify `clouds.yaml` - keep using `demo` credentials
3. Run your Ansible playbooks normally:
   ```bash
   ansible-playbook scenario1_basic_vm.yml
   ```

## Security Note

⚠️ **This is for demo/training environments only!**

Do NOT use this in production. In production environments:
- Use proper role-based access control (RBAC)
- Grant only necessary permissions
- Use service accounts with limited privileges
- Follow the principle of least privilege

## Troubleshooting

### Script says "OpenStack CLI not found"
```bash
pip install python-openstackclient
```

### Script can't connect to OpenStack
- Verify OpenStack is running: `systemctl status devstack@*`
- Check the endpoint is accessible: `curl http://10.0.3.15/identity`
- Verify admin password in the script matches your setup

### Still getting 403 errors after running script
- Wait 30 seconds for Keystone to refresh tokens
- Re-run the script
- Check if the user exists: `openstack user list`
- Verify roles: `openstack role assignment list --user demo --project demo --names`

## Success Verification

After running the script, you should see:

```
✓ demo user exists
✓ demo user is ready for volume creation and all operations

All users now have admin access for demo purposes.
You can now run Ansible playbooks without permission errors.
```

Then test with:
```bash
ansible-playbook scenario1_basic_vm.yml
```

The volume creation should now succeed! ✓
