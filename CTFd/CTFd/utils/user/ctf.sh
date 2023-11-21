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

# Nombre de machines virtuelles à créer
#num_vms=$1
# Créer les machines virtuelles
#for ((i=1; i<=$num_vms; i++)); do
    vm_name="CTF-$1"
    lxc launch ubuntu:22.04 $vm_name
    sleep 5
    echo "La machine virtuelle $vm_name a été créée avec succès."
# On donne toutes les permissions pour se connecter a notre machine en ssh
    lxc exec $vm_name -- useradd -m -p "$(openssl passwd -1 $2)" $username
    echo "L'utilisateur $username a bien été créé dans l'instance"
    lxc exec $vm_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    echo "PasswordAuthentication activé pour $vm_name"
    lxc exec $vm_name -- service ssh restart
    echo "Service SSH Relancé"
    lxc_ip="$(lxc list | grep $vm_name | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
    echo "L'adresse IP de l'instance de ${username} est ${lxc_ip}"
    echo "Adding connection profile to Guacamole"
    python /opt/CTFd/CTFd/utils/user/guac.py --create -u $username -p $password --add_connection --ip $lxc_ip
    echo "Connection Added"
