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
    lxc launch ubuntu:20.04 $vm_name
    sleep 5
    echo "La machine virtuelle $vm_name a été créée avec succès."
#On donne toutes les permissions pour se connecter a notre machine en ssh
    #lxc exec $vm_name useradd -m -p "$(openssl passwd -1 $2)" $1
    lxc exec $vm_name -- useradd -m -p "$(openssl passwd -1 $2)" $username
    lxc exec $vm_name -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    lxc exec $vm_name -- service ssh restart
    lxc_ip="$(lxc list | grep $vm_name | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
    echo (f"L'adresse IP de l'instance de {username} est {lxc_ip}")
    echo "PasswordAuthentication activé pour $vm_name"
    echo "Adding connection profile to Guacamole"
    python /home/tbarbay/guac.py --create -u $username -p $password --add_connection --ip $lxc_ip


#On copie le script pour lancer le serv http et la page d'index depuis l'ordinateur local
#    lxc file push /home/alebihan/pageweb.py $vm_name/root/
#    lxc file push /home/alebihan/index.html $vm_name/root/
#On lance en arriere plan le serv http au lancement de la vm
#    lxc exec $vm_name -- nohup python3 /root/pageweb.py &
