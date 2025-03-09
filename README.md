# 🚀 setup-station 🌟

_Your epic, ultra-smart, shell configuration ninja 🥷_

---

## 🧐 Wait, what's this all about?

Ever dreamed of the perfect shell experience that literally "gets you"? Introducing **setup-station**, a magical codebase designed to transform your terminal into a hyper-aware command center. ✨ 

Say goodbye to repetitive environment setups! Say hello to intelligent dotfile sourcing and environment detection! 🙌  

(Yes, it's sourced straight from your `.zshrc`, because running it directly simply won't do!)

---

## ⚡️ Features you can't live without:

- 🎩 Automatic OS & Environment Detection (macOS 🍎 / Linux 🐧 / Cloud ☁️)
- 👩‍💻 Clever configurations for devs (`git`, `docker🍃`, `VS Code`)
- 🔐 Easy encryption/decryption utilities built right in (your files love privacy too!)
- 🌩️ Instant cloud AWS credential switcheroos powered by fancy tokentamer scripts
- 📑 Customizable for **personal** or **work** machines—no more accidental commits from company laptops 😉

---

## 🌲 What's growing in here?

```
source/
├─ general/            ← Handy general tools and utils
│   └─ crypt.sh        ← Quick encrypt/decrypt files safely & securely
│   
├─ indeed/             ← Work-specific magic ✨ for Indeeders 🍀
│   ├─ dependency_installer.sh ← Auto-installs essentials (jq, fzf...)
│   ├─ tokentamer.sh    ← AWS account-jumping like a pro 🤖🎟️ 
│   └─ macos/
│       └─ code_compile.sh  ← Generate instant docs from Indeed projects!
│    
├─ tools/              ← Developer-quality-of-life boosters 😌🍹
│   ├── docker.sh      💙 Docker compose shortcuts that'll amaze!
│   ├── vscode.sh      💚 VS Code power-ups: git diffs made easy!
│   └── git.sh         🤍 *Coming Soon!* Git productivity hacks await...
└── main.sh            ⭐ Full-featured dynamic env setup orchestrator ⭐ 
```

---

## 🚦 Getting set up is stupid-simple:

Just source it directly in your `.zshrc` file:
```zsh
source ~/path/to/setup-station/source/main.sh  
```

Need debugging info? Just yell:
```zsh  
export DEBUG=1  
source ~/path/to/setup-station/source/main.sh  
```

Watch debug logs unfold before your eyes during startup. Magical indeed!

---

## Suitable For...

✅ Terminal Ninjas | ✅ DevOps Dragons | ✅ Shell Script Wizards | ✅ Tired Developers Crying 😭 into their dotfiles late at night  

This is YOUR **new best friend** on the command line.

---

#### Made by the one & only [madpin](https://github.com/madpin) 🇵🇹✨

Grab it now: `git clone git@github.com:madpin/setup-station.git` 

Happy hacking! 🚀🌙🤖⚡

---  

> _"Welcome home. Your terminal has never been happier."_