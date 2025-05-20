
🧪 Ansible Vault Hands-On Lab

Goal: Learn how to:

	•	Encrypt sensitive data using Ansible Vault.
	•	Encrypt whole files (e.g., variables, playbooks).
	•	Use Vault password files for automation.
	•	Run encrypted playbooks.
	•	Re-key, decrypt, and edit encrypted files.

⸻

✅ Prerequisites
•	Ubuntu/Debian system with Ansible installed:
```bash
sudo apt update && sudo apt install ansible -y
```

	•	Basic Ansible knowledge (playbooks, inventory).
	•	Working directory:
```bash
mkdir -p ~/ansible-vault-lab/group_vars && cd ~/ansible-vault-lab
```


⸻

🗂️ Step 1: Setup Lab Structure
```bash
mkdir -p group_vars/all vars secrets playbooks
touch inventory
```
Sample inventory:
```yaml
localhost ansible_connection=local
```

⸻

🔐 Step 2: Encrypting a Variables File
```bash
ansible-vault create group_vars/all/vault.yml
```
Add:
```yaml
db_user: "admin"
db_password: "S3cureP@ssw0rd"
```
Now, you can:
Edit:
```yaml
ansible-vault edit group_vars/all/vault.yml

```
View:
```yaml
ansible-vault view group_vars/all/vault.yml
```

Rekey (change the password):
```bash
ansible-vault rekey group_vars/all/vault.yml
```
Step 3: Using the Encrypted Variable File in a Playbook

Create a playbook: playbooks/use_vault_vars.yml
```yaml
---
- name: Demonstrate Ansible Vault Encrypted Variables
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../group_vars/all/vault.yml

  tasks:
    - name: Show encrypted DB credentials
      debug:
      msg: "DB User: {{ db_user }}, DB Password: {{ db_password }}"
```
Run the playbook:
```bash
ansible-playbook -i inventory playbooks/use_vault_vars.yml --ask-vault-pass
```

⸻

Step 4: Encrypting an Entire Playbook File

Let’s encrypt the whole playbook:
```bash
ansible-vault encrypt playbooks/use_vault_vars.yml
```
Now open the file:
```bash
cat playbooks/use_vault_vars.yml
```
🧠 You’ll see it’s fully encrypted.

Run the playbook:
```bash
ansible-playbook -i inventory playbooks/use_vault_vars.yml --ask-vault-pass
```

⸻

🔁 Step 5: Decrypting a File

To restore it to plaintext:
```bash
ansible-vault decrypt playbooks/use_vault_vars.yml
```
To re-encrypt it:
```bash
ansible-vault encrypt playbooks/use_vault_vars.yml
```

⸻

🗝️ Step 6: Using a Vault Password File

For automation (e.g., CI/CD), avoid interactive prompts.

Create .vault_pass.txt:
```bash
echo "myvaultpassword" > .vault_pass.txt
chmod 600 .vault_pass.txt
```
Now run:
```bash
ansible-playbook -i inventory playbooks/use_vault_vars.yml --vault-password-file .vault_pass.txt
```
Also works with other vault commands:
```bash
ansible-vault view group_vars/all/vault.yml --vault-password-file .vault_pass.txt
```

⸻

📦 Step 7: Encrypting Only Specific Values in a File (Inline Vault)
1.	Create a file: vars/secrets.yml
```yaml
api_key: !vault |
$ANSIBLE_VAULT;1.1;AES256
35386365666539313662323430656362326162303130363131393038636633376362383662393934
```
🔧 Use ansible-vault encrypt_string to create this.

Run:
```bash
ansible-vault encrypt_string --vault-password-file .vault_pass.txt '12345-abcde-key' --name 'api_key'
```
Paste the output into vars/secrets.yml.

Use in a playbook:
```yaml
---
- name: Use inline vault secret
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../vars/secrets.yml

  tasks:
    - name: Show API Key
      debug:
      msg: "The API Key is {{ api_key }}"

```
⸻

🧪 Step 8: Encrypting Multiple Files at Once
```bash
ansible-vault encrypt vars/secrets.yml group_vars/all/vault.yml
```

⸻

🔄 Step 9: Rekeying Multiple Files
```bash
ansible-vault rekey group_vars/all/vault.yml vars/secrets.yml
```

⸻

🧹 Step 10: Teardown Script (Optional)

If you want to clean up all files:
```bash
#!/bin/bash
rm -rf ~/ansible-vault-lab
echo "Lab directory removed."
```

⸻

✅ Summary Table

Task	Command
Create Vault-encrypted file	ansible-vault create filename.yml
Encrypt existing file	ansible-vault encrypt filename.yml
Decrypt file	ansible-vault decrypt filename.yml
Edit encrypted file	ansible-vault edit filename.yml
View encrypted file	ansible-vault view filename.yml
Rekey	ansible-vault rekey filename.yml
Encrypt string (inline)	ansible-vault encrypt_string 'value' --name 'key'


⸻
