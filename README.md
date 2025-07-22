# 🛠️ Process Manager CLI (Bash)

A simple yet interactive terminal-based task manager written in **Bash**, allowing users to view, sort, filter, and manage system processes. Includes logging, session summaries, and basic user authentication via `users.txt`.

---

## 📸 Features

- User authentication with 3 login attempts  
- View top active processes (CPU/MEM)  
- Sort and filter processes dynamically  
- Graceful and forced process termination  
- Start a demo “busy” process (`yes > /dev/null &`)  
- Session summary and detailed logs  

---

## 📂 File Structure

```
.
├── CLI_task_manager.sh        # Main script
├── users.txt              # Format: username:password
├── actions.log            # Auto-generated log file
└── README.md              # You're reading it
```

---

## 🧑‍💻 Prerequisites

### ✅ Linux Users

- No extra setup (assuming Bash is installed)  
- To fix Windows line-ending issues:
  ```bash
  sudo apt install dos2unix
  dos2unix users.txt task_manager.sh
  ```

### ✅ Windows Users

> ⚠️ **This script won’t run properly in Git Bash or Command Prompt.**

1. Install **WSL** (Windows Subsystem for Linux):  
   ```powershell
   wsl --install
   ```  
   Then reboot and install a distro (e.g., Ubuntu).

2. Open WSL and run:
   ```bash
   sudo apt update
   sudo apt install dos2unix
   dos2unix users.txt task_manager.sh
   ```

---

## 🔐 User Login Setup

- Format each line in `users.txt` as: `username:password`  
- Ensure there are **no blank lines** at the end—otherwise use `dos2unix` to clean it up.

---

## 🚀 Running the Project

```bash
chmod +x CLI_task_manager.sh
./CLI_task_manager.sh
```

---

## 📝 Sample Log Output

```
2025-07-22 20:01:14 | User: system | LOGIN | PID: - | CMD: - | User 'system' logged in
2025-07-22 20:02:45 | User: system | KILLED | PID: 5345 | CMD: firefox | Normal kill
```

---

## 🧹 Troubleshooting

| Problem                              | Solution |
|-------------------------------------|----------|
| `Permission denied`                 | `chmod +x task_manager.sh` |
| `bad interpreter`                   | `dos2unix task_manager.sh` |
| `Login not working`                 | Clean `users.txt`, remove blank lines |
| Process kill fails                  | Use `sudo` or kill your own process |

---

## 📌 Notes

- Always double-check processes before killing, especially with `sudo`.


---

- All session actions are logged in `actions.log` for review.
