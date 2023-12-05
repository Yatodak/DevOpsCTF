#!/bin/bash

# Vérifier si lxc est installé
if ! command -v lxc &> /dev/null; then
    echo "LXC n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
    exit 1
fi

# Vérifier le nombre d'arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <nombre_de_machines_virtuelles> <mot_de_passe>"
    exit 1
fi

username=$1
password=$2
vm_name="CTF-$1"

# Création de l'instance en limitant la mémoire
lxc launch ctf-instance -c limits.memory=512MB $vm_name 
echo "La machine virtuelle $vm_name a été créée avec succès."

# Attendre que la machine démarre normalement, if uplink -> on avance
lxc_ip="$(lxc list | grep $vm_name | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
    while [ -z $lxc_ip ]
    do
        lxc_ip="$(lxc list | grep $vm_name | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
        sleep 0.5
    done
    echo "La machine a correctement démarré, ip récupérée"

# Personnalisation de l'instance pour l'utilisateur
    lxc exec $vm_name -- useradd -m -s /bin/bash -p "$(openssl passwd -1 $password)" $username
    echo "L'utilisateur $username a bien été créé dans l'instance"

    lxc exec $vm_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    echo "PasswordAuthentication activé pour $vm_name"
    
    lxc exec $vm_name -- bash -c 'echo "myuser ALL=(ALL) NOPASSWD: /opt/script.sh" >> /etc/sudoers'
    echo "Droits Sudoers ajouté dans $vm_name"
    
    lxc exec $vm_name -- service ssh restart
    echo "Service SSH Relancé"
    echo "L'adresse IP de l'instance de ${username} est ${lxc_ip}"
    echo "Adding connection profile to Guacamole"
    python /opt/CTFd/CTFd/utils/user/guac.py --create -u $username -p $password --add_connection --ip $lxc_ip
    echo "Connection Added"
