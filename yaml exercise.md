### **YAML Practical Exercise: From Basics to Advanced**

This step-by-step exercise starts with simple YAML concepts and gradually progresses to advanced features, providing hands-on experience.

---

### **Objective**
- Understand YAML basics and syntax.
- Learn to avoid YAML pitfalls.
- Work with YAML dictionaries, lists, and advanced structures like lists of dictionaries and alternate formats.
- Explore the relationship between YAML and JSON.

---

### **Prerequisites**
1. Install a YAML linter (`yamllint`) and a JSON processor (`jq`):
   ```bash
   sudo apt install yamllint jq -y
   ```
2. Set up a working directory:
   ```bash
   mkdir yaml_practical && cd yaml_practical
   ```

---

### **Part 1: YAML Basics**

#### **1. Creating a Basic YAML File**
1. Create a file called `basic.yaml`:
   ```bash
   nano basic.yaml
   ```
2. Add the following content:
   ```yaml
   name: John Doe
   age: 30
   location: New York
   ```

3. Validate the file:
   ```bash
   yamllint basic.yaml
   ```

#### **2. YAML Gotchas**
1. Create a file `gotchas.yaml`:
   ```bash
   nano gotchas.yaml
   ```
2. Add common mistakes:
   ```yaml
   key: value
   key2: value2
   key3: no: yes  # Missing quotes for special characters
   list:
     - item1
      - item2  # Incorrect indentation
   ```

3. Fix the errors:
   - Quote special characters (`"no: yes"`).
   - Correct the indentation.

4. Validate the corrected file:
   ```bash
   yamllint gotchas.yaml
   ```

---

### **Part 2: YAML Intermediate Structures**

#### **1. Working with Dictionaries**
1. Create `dictionary.yaml`:
   ```bash
   nano dictionary.yaml
   ```
2. Add a nested dictionary:
   ```yaml
   server:
     host: localhost
     port: 8080
   database:
     user: admin
     password: secret
   ```

3. Add a `logging` dictionary:
   ```yaml
   logging:
     level: INFO
     file: /var/log/app.log
   ```

4. Validate the file:
   ```bash
   yamllint dictionary.yaml
   ```

---

#### **2. YAML Lists**
1. Create `list.yaml`:
   ```bash
   nano list.yaml
   ```
2. Add a list:
   ```yaml
   fruits:
     - apple
     - banana
     - cherry
   tasks:
     - build
     - test
     - deploy
   ```

3. Convert it to JSON:
   ```bash
   python3 -c "import yaml, json; print(json.dumps(yaml.safe_load(open('list.yaml')), indent=2))"
   ```

---

#### **3. YAML List of Dictionaries**
1. Create `list_of_dictionaries.yaml`:
   ```bash
   nano list_of_dictionaries.yaml
   ```
2. Add content:
   ```yaml
   users:
     - name: Alice
       email: alice@example.com
       role: admin
     - name: Bob
       email: bob@example.com
       role: user
   ```

3. Add more entries for practice. Validate using:
   ```bash
   yamllint list_of_dictionaries.yaml
   ```

---

### **Part 3: YAML Advanced Concepts**

#### **1. YAML Alternate Format**
1. Create `alternate_format.yaml`:
   ```bash
   nano alternate_format.yaml
   ```
2. Use inline syntax:
   ```yaml
   server: { host: localhost, port: 8080 }
   tasks: [build, test, deploy]
   ```

3. Mix block and inline styles:
   ```yaml
   database:
     name: appdb
     credentials: { user: admin, password: secret }
   ```

4. Convert to JSON and observe the structure:
   ```bash
   python3 -c "import yaml, json; print(json.dumps(yaml.safe_load(open('alternate_format.yaml')), indent=2))"
   ```

---

#### **2. YAML and JSON Conversion**
1. Create `example.json`:
   ```bash
   nano example.json
   ```
2. Add JSON content:
   ```json
   {
     "server": {
       "host": "localhost",
       "port": 8080
     },
     "tasks": ["build", "test", "deploy"]
   }
   ```

3. Convert JSON to YAML:
   ```bash
   python3 -c "import yaml, json; print(yaml.dump(json.load(open('example.json')), default_flow_style=False))" > example.yaml
   ```

4. View the YAML:
   ```bash
   cat example.yaml
   ```

---

### **Part 4: YAML Integration Exercise**

#### **1. Create a Complete YAML File**
Combine dictionaries, lists, and lists of dictionaries in `complete.yaml`:
```yaml
application:
  name: myapp
  version: 1.0.0
  servers:
    - name: web1
      host: 192.168.1.1
      role: frontend
    - name: db1
      host: 192.168.1.2
      role: backend
  tasks:
    - build
    - test
    - deploy
  logging:
    level: DEBUG
    file: /var/log/app.log
```

#### **2. Validate and Convert**
1. Validate the file:
   ```bash
   yamllint complete.yaml
   ```

2. Convert it to JSON:
   ```bash
   python3 -c "import yaml, json; print(json.dumps(yaml.safe_load(open('complete.yaml')), indent=2))" > complete.json
   ```

3. View the JSON:
   ```bash
   cat complete.json
   ```

---

### **Deliverables**
- Valid YAML files (`basic.yaml`, `gotchas.yaml`, etc.).
- Converted JSON files (`list.json`, `example.json`, etc.).
- A combined YAML file (`complete.yaml`) showcasing all concepts.

---

### **Best Practices**
1. Always validate YAML files before using them.
2. Use consistent indentation (2 spaces).
3. Quote special characters (`yes`, `no`, `true`, `false`).
4. Use comments to describe complex sections.
5. Convert between JSON and YAML to ensure compatibility with systems that require one format.

