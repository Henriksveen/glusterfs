#!/bin/bash

init() {
    echo "Initiate glusterfs."
	read -r -p "Adding Heketi as a RESTful management interface? [y/N] " response
    
    vagrant up
	case "$response" in
	    [yY][eE][sS]|[yY]) 
            echo "Setup heketi.."
            vagrant ssh gluster01 -c '/vagrant/heketi.sh'
	        ;;
	    *)
            echo "Setup without heketi"
            vagrant ssh gluster01 -c '/vagrant/create-gluster-cluster.sh'
	        ;;
	esac
}

up() {
    vagrant up
}

stop() {
    vagrant halt
}

prune() {
    vagrant destroy -f
    vagrant global-status --prune
}

command="${1}"
shift
case "${command}" in
	init)
	    init;;  
	up)
	    up;;
	stop)
	    stop;;
	prune)
	    prune;;
	*) echo "invalid command '${command}' (init,up,stop,prune)";;
esac