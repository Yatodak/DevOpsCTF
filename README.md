# DevOps Themed Capture the Flag By Synapsys
![image](https://github.com/Yatodak/DevOpsCTF/assets/57355439/6502f1e1-8035-4d53-a593-f8ce35185ac6)

## Introduction

We created based on other software a Capture the Flag with the DevOps theme wich is not a very trendy
So as we work in a DevOps Team as consultant we created one within our idle time between contracts to play with our coworkers

We decided to share our work, might not be perfect to be honest because we're newbies for a lot of technologies used this project and we're just out of school this year !
We're going to improve this work when we have the time to do it so don't expect regular updates, but we're happy to ear your issues and advices related to this project and add the improvements you may propose if they're worth it !


## Requirements

1. May Work on any debian based Distro (tested on Ubuntu 22.04)
2. Full access to Sudo
3. On the Host
  1. Another disk without any data (gonna be formated to be used by lxc with ZFS)
  2. The lxc image exported of your environment in tar.gz archive format  


## Installation

1. Copy the repo
2. Start the init.sh script `./init.sh` wich will setup everything needed to work (CTFd interface, Guacamole, LXC, Nginx as reverse proxy)
   you just need to answer the prompt when needed
3. Connect to the ServerName you entered in the init script
4. Start playing or building your own game
