VM_ID=devbox
DEV_FOLDER=/home/vagrant/Code

# TODO: Figure out how to use either the passed value or this default one
#CMD_DEFAULT=cd $(DEV_FOLDER); bash -l

# Commands
test:
	echo 'This is the Homestead development box'

ssh:
#	if [ -z "$(CMD)" ]; then echo "$(CMD_DEFAULT)"; else echo "$(CMD)"; fi
	vagrant ssh $(VM_ID) -- -t "$(CMD)"

provision:
	vagrant reload --provision
