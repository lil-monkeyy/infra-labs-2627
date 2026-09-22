# Getting started

Throughout the lab assignments, you will be building an environment consisting of multiple virtual machines. The entire environment consists of about 9 VMs. Most of these are server systems without a graphical user interface, one is a workstation and one functions as a router.

The image below is a network diagram of the finished lab environment, showing assigned IP addresses and the different networks. Don't worry about the complexity for now, as you will be building the environment step by step. The diagram is provided here for reference.

![Lab environment network diagram](./0-getting-started/infra-labs-network.png)

Consequently, you will need suitable hardware. A recent, performant laptop (or desktop) computer with at least 16GB of RAM (preferably 32GB), a modern, mid- to high-end 64-bit Intel/AMD CPU with a sufficient number of cores, and an SSD with sufficient storage (about 80GB should be ok) is necessary. A recent Apple laptop with an Apple Silicon CPU is **not** supported.

On the software side, the operating system on your machine may be either Linux or Windows and you will need to have Git, VirtualBox and Vagrant installed. We are confident that at this point, you can figure out how to install or upgrade these tools on your own, as you should have already used them earlier in your studies.

You interact with the lab environment from your host machine in the terminal. On Windows, you can use either PowerShell or Git Bash. On Linux, you can use the default terminal (Bash, zsh, ...).

Before you start, make sure you have a personal Git repo with a copy of this repository. You should have received instructions on how to create a personal Git repo from your instructor. If you don't follow the Infrastructure Automation course, and are interested in doing the labs, you can just create a fork of this repository into your personal account, or clone it locally. **Please make your own repository private.**

## Config check

On each system where you use Git, you should check your **global Git configuration** and at least set your user name and email and some other basic settings as shown below.

```console
$ git config --global user.name "Your Name"
$ git config --global user.email "your.email@student.hogent.be"
$ git config --global core.autocrlf input
$ git config --global pull.rebase true
$ git config --global rebase.autostash true
```

Also, ensure that you have an **SSH key pair** and that the public key is registered in your GitHub account.

## Local working copy

Open a terminal and clone your repository to your local machine, using the SSH-URL. Move into the repository directory, and create a new branch for your work. The branch name doesn't really matter and can be e.g. `local`, `my_solution`, etc. You will be working in this branch throughout the labs.

## Start the initial lab environment

In a terminal, navigate into the `labenv` subdirectory, and run the following command:

```console
> cd labenv/
> vagrant status
Current machine states:

infra010                  not created (virtualbox)
control                   not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

The environment currently defines two virtual machines:

- `control`: a VM that will be used as a control node for Ansible.

    Installation and configuration is done with a shell script (labenv/scripts/control.sh) that is executed by Vagrant when the VM is created.

- `infra010`: a VM that will be used as a Docker host.

    Initial installation is done by an Ansible playbook that is run from the control node. At this point, you do not need to worry about the details of this playbook, as it will be covered in later assignments.

In the first assignment, you will be setting up the `infra010` as a Jenkins build server. The `control` node will be used throughout the labs to manage all other VMs that you will be creating. Starting the VMs is done with the `vagrant up` command. This command will create and start the VMs, and configure them.

**Possible issue for Linux users**: you might run into an error concerning the allowed IP-range of host-only networks in VirtualBox. The error message itself is quite self-explanatory: you should create/adapt the `/etc/vbox/networks.conf` file to allow all IP-addresses using the following line:

```config
* 0.0.0.0/0
```

After the command has finished successfully, you can check the status of the VMs again with `vagrant status`. You should see that both VMs are now running.

```console
$ vagrant status
Current machine states:

infra010                  running (virtualbox)
control                   running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

You should now be able to point your webbrowser to the IP address of the `infra010` VM <http://172.16.0.10:9000/> and see the Portainer web interface, a web-based management interface for Docker. You can follow the installation wizard to set up a password for the `admin` user. You can log in with this user and use Portainer to monitor what is happening on the VM. Portainer is not part of this assignment, but you can use it to inspect the running containers.

From this point, you can start working on the first [assignment on CI/CD](1-cicd.md). You may shut down the control node, as you won't actually need it for this assignment. You can do this with the `vagrant halt control` command. You can start it again later with `vagrant up control`.

All the information below is provided for later reference, but you do not need to worry about it for now.

## Performance problems?

If you encounter performance problems when using VirtualBox and/or Vagrant, they are most likely caused by Hyper-V. When you start a VirtualBox VM while Hyper-V is active, you lose the ability for hardware acceleration because it is monopolized by Hyper-V.

You can check this in the status bar of a VM window. A blue rectangular icon like the one shown below indicates that hardware acceleration is available.

![VirtualBox hardware acceleration available](./0-getting-started/virtualbox-vtx.png)

However, if you see an icon resembling a green turtle, it means that hardware acceleration is not available for VirtualBox.

![VirtualBox hardware acceleration unavailable](./0-getting-started/virtualbox-no-vtx.png)

 In that case, check if Hyper-V is completely disabled. Docker Desktop, Windows Subsystem for Linux 2, and similar tools are based on Hyper-V, so they must also not be active.

## Errata

It is possible that errors in the lab assignment will be corrected during the semester. These corrections will be published in the source repository with the assignment. You can also systematically apply these changes in your own personal GitHub repository where you are working on the lab assignments.

First, link your local copy to the source repository as a remote called `upstream`. We use the HTTPS-URL here, as you only have read access to the source repository.

```console
$ git remote add upstream https://github.com/HoGentTIN/infra-labs.git
```

Before applying changes from the source repository, you should always make sure that your local copy is up to date. Check with `git status` that there are no uncommitted changes in your local branch anymore.

To get the latest changes from the source repository, you can run the following command:

```console
$ git fetch upstream
```

Finally, rebase your local branch (called `local` in this example) on top of the latest changes from the source repository:

```console
$ git switch local
$ git rebase upstream/main
```
