<a id="top"></a>

# Ansible BaseBook

This a basic playbook and roles collection.

* [Requirements](#requirements)
* [Project structure](#project-structure)
* [Usage](#usage)
* [Development](#development)
* [Skeleton](#skeleton)

[To top]

## Requirements

Ansible control node:

* OS: any that supports ansible installation
* ansible
* openssh-client
* bash (optional, in case you want to take advantage of helper bash scripts)
* sshpass (optional, for password-based ssh connections)

Ansible managed nodes:

* OS: latest versions of Alpine, Debian or alike (for Ubuntu latest LTS version), CentOS or alike
* openssh-server (running)
* ansible user (must be sudoer)
* python

<details><summary>Tips</summary>

  **Debian**-like managed node:
  ```sh
  # Performed by root user

  # Install prereqs
  apt-get update
  apt-get install -y openssh-server python3 sudo

  # Ensure ssh server running
  systemctl enable --now sshd

  # Create ansible user, replace USERNAME
  useradd -m USERNAME
  passwd USERNAME

  # Make ansible user sudoer
  usermod -aG sudo USERNAME
  ```

  **Alpine** managed node:
  ```sh
  # Performed by root user

  # Install prereqs
  apk add --update --no-cache openssh-server python3 sudo shadow

  # Ensure ssh server running
  rc-update add sshd
  rc-service sshd start

  # Create ansible user, replace USERNAME
  useradd -m USERNAME
  passwd USERNAME

  # Make ansible user sudoer
  echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
  usermod -aG wheel USERNAME
  ```
</details>

[To top]

## Project structure

```sh
├── .dev                # <- Development convenience scripts
├── ansible.cfg
├── bin                 # <- Playbook convenience scripts
├── playbook.yaml
├── requirements        # <- Required roles and collections
├── requirements.yaml   # <- Required roles and collections declaretions
├── roles
├── sample    # <- Configuration samples
└── skeleton  # <- New projects skeleton and install script
```

[To top]

## Usage

1.  Copy configurations from sample directory and edit them:

    ~~~sh
    cp -rfp ./sample/* ./
    ~~~

2.  Use `ansible-playbook` wrapper scripts from `bin` directory to deploy  
    In order to provoke vault password prompt by `bin` scripts create `vaulted.txt` file in the project root directory
    ```sh
    touch ./vaulted.txt
    ```

[To top]

## Development

1.  If your playbook development is under git source control run `.dev/dev-init.sh` script to ensure hooks.
2.  See `docker` and `demo-noapp` roles for demos on how to write roles.
3.  Run `.dev/build-sample-args.sh` when completed to add configurations to sample vars file.

### `factum` role

A lot of roles depend on data collected by `factum`, so it's better to be the first role in the playbook. It provides the following:

```yaml
getent_passwd:
  root:
    - ...   # <- Useless
    - UID   # [1]
    - GID   # [2]
    - ...   # <- Useless
    - HOME  # [4]
    - SHELL # [5]
  # ...  # <- Other users

factum_os_family:         # <- Lowercase ansible_os_family
factum_os_like:           # <- More prioritized OS like
factum_ubuntu_codename:   # <- Ubuntu code name for Ubuntu-like distros
```

### `init` role

Performs all necessary initialization tasks (`factum` included), so it basically must be the first role in the playbook.

```yaml
- name: 'MyBook'
  hosts: all
  roles:
    - { role: init, tags: [always] }  # <- Required initial tasks
    # ... more roles
```

[To top]

## Skeleton

In order to create a new project with the same concept as this one, issue

```sh
bash -- <(
  curl -fsSL https://github.com/spaghetti-coder/ansible-basebook/raw/master/skeleton/skel-init.sh
) ./my/project/directory
```

And than review [README.md](./skeleton/README.md) file in the generated directory.

## Standalones

TODO

```sh
curl -fsSL https://github.com/spaghetti-coder/ansible-basebook/raw/master/roles/envar/files/envar.sh | sudo bash -s -- install
```

[To top]

[To top]: #top
