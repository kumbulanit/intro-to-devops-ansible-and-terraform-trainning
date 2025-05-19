### **Gathering Facts in Ansible**



#### **How Facts are Gathered**

Ansible gathers facts by default at the beginning of every playbook run unless explicitly disabled. This process is managed by the `setup` module, which is responsible for collecting and returning facts. If you don't disable fact gathering, it happens automatically before any tasks are executed.

#### **Example of Gathering Facts**

```yaml
---
- name: Gather system facts
  hosts: all
  tasks:
    - name: Print all facts
      debug:
        var: ansible_facts
```

In this example:
- **`debug`**: This task prints all the facts collected by Ansible.
- **`ansible_facts`**: A dictionary of all facts gathered about the system.

When you run this playbook, Ansible will collect facts about the host and display them.

#### **Enabling and Disabling Fact Gathering**

By default, Ansible gathers facts at the start of each play. If you do not need facts for a specific playbook or play, you can disable the fact-gathering process to improve performance.

**Disable Fact Gathering:**

```yaml
---
- name: Playbook with no fact gathering
  hosts: all
  gather_facts: no
  tasks:
    - name: Run without facts
      command: uname -r
```

Setting **`gather_facts: no`** will skip the fact gathering, reducing the time it takes to run the playbook if you do not need this information.

#### **Accessing Specific Facts**

Rather than gathering all facts, you can access specific pieces of information during a playbook run using the fact variables.

For example:

```yaml
---
- name: Gather and use facts
  hosts: all
  tasks:
    - name: Print the hostname
      debug:
        var: ansible_hostname

    - name: Print the operating system
      debug:
        var: ansible_distribution
```

In this example:
- **`ansible_hostname`**: This fact contains the hostname of the target host.
- **`ansible_distribution`**: This fact contains the name of the operating system (e.g., `Ubuntu`, `CentOS`).

#### **Using Facts to Make Decisions (Conditional Execution)**

Facts can be used to make decisions about which tasks to run based on the system configuration.

**Example:**

```yaml
---
- name: Conditionally execute tasks based on OS type
  hosts: all
  gather_facts: yes
  tasks:
    - name: Install a package on Ubuntu
      apt:
        name: curl
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: Install a package on CentOS
      yum:
        name: curl
        state: present
      when: ansible_distribution == "CentOS"
```

In this example:
- **`when`**: This condition checks the value of `ansible_distribution` and only runs the corresponding task if the system's OS is Ubuntu or CentOS.

#### **Custom Facts**

In addition to the built-in facts gathered by Ansible, you can define custom facts. These facts are created and set manually by users and can be useful for passing specific variables to later tasks in the playbook.

To set custom facts, you can use the `set_fact` module:

**Example:**

```yaml
---
- name: Define and use custom facts
  hosts: all
  tasks:
    - name: Set a custom fact
      set_fact:
        custom_fact: "This is a custom fact"
      
    - name: Print the custom fact
      debug:
        var: custom_fact
```

Here:
- **`set_fact`**: This task defines a new fact called `custom_fact`.
- **`debug`**: The task prints the value of `custom_fact`.

#### **Using the Setup Module Directly**

If you want to gather facts manually, you can use the `setup` module directly in your playbooks.

**Example:**

```yaml
---
- name: Manually gather facts
  hosts: all
  tasks:
    - name: Gather facts
      setup:

    - name: Print the gathered facts
      debug:
        var: ansible_facts
```
