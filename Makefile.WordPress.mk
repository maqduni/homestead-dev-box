# Define in the main makefile
# BACKUP_FOLDER = /var/tmp/db_backups
# DEV_FOLDER = /home/vagrant/Code/{PROJECT_NAME}
# HOMESTEAD_BOX_FOLDER=../homestead-dev-box

# Environment variables
ENV_FILE = ./.env
include $(ENV_FILE)

# Constants
XDEBUG_PARAMS='"-dxdebug.remote_enable=1 -dxdebug.remote_autostart=on -dxdebug.remote_mode=req -dxdebug.remote_port=9000 -dxdebug.remote_host=$(APP_DEBUG_REMOTE_HOST) -dxdebug.remote_connect_back=0 -dxdebug.idekey=$(APP_DEBUG_IDE_KEY)"'

test:
	echo 'test'

#
# SSH
#
prod_ssh:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER); bash -l'
prod_ssh_cmd:
	ssh $(PROD_USER)@$(PROD_HOST) -t '$(CMD)'

dev_ssh:
	make dev_sc CMD='cd $(DEV_FOLDER); bash -l'
dev_sc: # TODO: merge this command with dev_ssh once I figure out how to assign variable names properly in bash
	(cd $(HOMESTEAD_BOX_FOLDER) && make ssh CMD="$(CMD)")
