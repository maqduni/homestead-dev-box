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
# todo: Production deployment
#
deploy_server:
	echo 'deploy_server'


#
# Development box
#
# todo: dev_configure to run all configuration commands to set up dev instance?
dev_vm_up:
	(cd $(HOMESTEAD_BOX_FOLDER) && vagrant up)
dev_vm_halt:
	(cd $(HOMESTEAD_BOX_FOLDER) && vagrant halt)

#
# Database
#
# todo: this is an exact copy of what's in the Laravel makefile
prod_list_backups:
	# NOTE: delete files using a name mask "ls -1 | grep '{MASK}' | xargs rm -f"
	make prod_ssh_cmd CMD='cd $(BACKUP_FOLDER); ls -1'
prod_db_backup:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER); make db_backup'

dev_db_restore_from_prod:
	make dev_sc CMD='cd $(DEV_FOLDER); make db_restore_from_prod BACKUP_NAME=$(BACKUP_NAME)'

db_backup:
	mkdir -p $(BACKUP_FOLDER)
	$(eval BACKUP_NAME := $(DB_DATABASE)_$(shell date '+%Y%m%d_%H%M%S'))
	mysqldump $(DB_DATABASE) | gzip > $(BACKUP_FOLDER)/$(BACKUP_NAME).sql.gz
db_restore:
	# make db_restore BACKUP_NAME=
	mysql $(DB_DATABASE) < $(BACKUP_NAME).sql
db_download_from_prod:
	# make db_download_from_prod BACKUP_NAME=
	mkdir -p $(BACKUP_FOLDER)
	scp $(PROD_USER)@$(PROD_HOST):$(BACKUP_FOLDER)/$(BACKUP_NAME).sql.gz $(BACKUP_NAME).sql.gz
	gunzip -k $(BACKUP_NAME).sql.gz
db_restore_from_prod:
	# make db_restore_from_prod BACKUP_NAME=
	make db_download_from_prod BACKUP_NAME=$(BACKUP_NAME)
	make db_restore BACKUP_NAME=$(BACKUP_NAME)
# todo: Switch to the current DB context
db_connect:
	mysql -u root -p

#
# SSH
#
prod_ssh:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER); bash -l'
prod_ssh_cmd:
	ssh $(PROD_USER)@$(PROD_HOST) -t '$(CMD)'

dev_ssh:
	make dev_sc CMD='cd $(DEV_FOLDER); bash -l'
dev_sc: # todo: merge this command with dev_ssh once I figure out how to assign variable names properly in bash
	(cd $(HOMESTEAD_BOX_FOLDER) && make ssh CMD="$(CMD)")

