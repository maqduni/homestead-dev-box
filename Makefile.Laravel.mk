# Define in the main makefile
# BACKUP_FOLDER = /var/tmp/db_backups
# DEV_FOLDER = /home/vagrant/Code/{PROJECT_NAME}
# HOMESTEAD_BOX_FOLDER=../homestead-dev-box

# Environment variables
ENV_FILE = ./server/.env
include $(ENV_FILE)

# Constants
XDEBUG_PARAMS='"-dxdebug.mode=debug -dxdebug.start_with_request=yes -dxdebug.client_port=9003 -dxdebug.client_host=$(APP_DEBUG_REMOTE_HOST) -dxdebug.discover_client_host=false -dxdebug.idekey=$(APP_DEBUG_IDE_KEY)"'

test:
	echo 'test'

#
# Production deployment
#
deploy_server_start:
	(cd server; php artisan down --retry=360)
	make db_backup
	git pull
	(cd server; composer install)
	(cd server; composer dump-autoload --optimize)
	(cd server; php artisan migrate)
	make cache_config
	# manually run make restart_workers
deploy_client_to_prod:
	npm run prod
	scp -r public $(PROD_USER)@$(PROD_HOST):$(PROD_FOLDER)
deploy_server_finish:
	(cd server; php artisan up)


#
# Development box
#
# todo: dev_configure to run all configuration commands to set up dev instance?
dev_vm_up:
	(cd $(HOMESTEAD_BOX_FOLDER) && vagrant up)
dev_vm_halt:
	(cd $(HOMESTEAD_BOX_FOLDER) && vagrant halt)

dev_watch:
	npm run watch
dev_artisan:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php artisan $(CMD)'
dev_artisan_debug:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php $(XDEBUG_PARAMS) artisan $(CMD)'

dev_migrate:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php artisan migrate'
dev_rollback:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php artisan migrate:rollback --step=1'
dev_seed:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php artisan db:seed --class=DatabaseSeeder'

dev_ngrok:
	make dev_sc CMD='ngrok authtoken $(NGROK_AUTH_TOKEN); ngrok http -host-header=rewrite $(APP_URL):80'

#
# Database
#
# todo: this is an exact copy of what's in the Laravel makefile
# todo: create a cron job to create daily database backups
# todo: transfer the backup to S3 https://laravel.com/docs/5.8/homestead#configuring-minio
prod_list_backups:
	# NOTE: delete files using a name mask "ls -1 | grep '{MASK}' | xargs rm -f"
	make prod_ssh_cmd CMD='cd $(BACKUP_FOLDER); ls -lh'
prod_db_backup:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER); make db_backup'

dev_db_restore:
	make dev_sc CMD='cd $(DEV_FOLDER); make db_restore BACKUP_NAME=$(BACKUP_NAME)'
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
# Unit tests
#
dev_phpunit:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; ./vendor/bin/phpunit -c phpunit.xml $(CMD)'
dev_phpunit_debug:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; php $(XDEBUG_PARAMS) ./vendor/bin/phpunit -c phpunit.xml $(CMD)'


#
# Cache
#
cache_config:
	(cd server; php artisan route:cache; php artisan config:cache; php artisan view:cache)
clear_config_cache:
	(cd server; php artisan route:clear; php artisan config:clear; php artisan view:clear)

dev_cache: dev_autoload dev_clear_config_cache
dev_clear_config_cache:
	make dev_sc CMD='cd $(DEV_FOLDER); make clear_config_cache'
dev_autoload:
	make dev_sc CMD='cd $(DEV_FOLDER)/server; composer dump-autoload'


#
# Logs
#
list_prod_logs:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER)/server/storage/logs; ls -l'
prod_logs:
	#ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER)/server/storage/logs; tail -n 200 -f `ls -t | head -1`'
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER)/server/storage/logs; tail -n 200 -f laravel-2025-01-15.log'
dev_logs:
	make dev_sc CMD='cd $(DEV_FOLDER)/server/storage/logs; tail -n 100 -f laravel.log'


#
# SSH
#
prod_ssh:
	ssh $(PROD_USER)@$(PROD_HOST) -t 'cd $(PROD_FOLDER)/server; bash -l'
prod_ssh_cmd:
	ssh $(PROD_USER)@$(PROD_HOST) -t '$(CMD)'

dev_ssh:
	make dev_sc CMD='cd $(DEV_FOLDER); bash -l'
dev_sc: # todo: merge this command with dev_ssh once I figure out how to assign variable names properly in bash
	(cd $(HOMESTEAD_BOX_FOLDER) && make ssh CMD="$(CMD)")


#
# Queue, Schedule, Horizon
#
create_queue_worker:
	# make create_queue_worker APP_FOLDER="$(PROD_FOLDER)" APP_USER="$(PROD_USER)"
	$(APP_FOLDER)/shell/create_queue_worker.sh "$(APP_FOLDER)" "$(APP_USER)"
create_schedule_worker:
	$(APP_FOLDER)/shell/create_schedule_worker.sh "$(APP_FOLDER)" "$(APP_USER)"
create_horizon_worker:
	$(APP_FOLDER)/shell/create_horizon_worker.sh "$(APP_FOLDER)" "$(APP_USER)"

restart_supervisor_workers:
	sudo supervisorctl restart laravel_queue-worker:*
	sudo supervisorctl restart laravel_schedule-worker:*
stop_supervisor_workers:
	sudo supervisorctl stop laravel_queue-worker:*
	sudo supervisorctl stop laravel_schedule-worker:*

dev_create_queue_worker:
	make dev_sc CMD='cd $(DEV_FOLDER); make create_queue_worker APP_FOLDER="$(DEV_FOLDER)" APP_USER="vagrant"'
dev_create_schedule_worker:
	make dev_sc CMD='cd $(DEV_FOLDER); make create_schedule_worker APP_FOLDER="$(DEV_FOLDER)" APP_USER="vagrant"'
dev_create_horizon_worker:
	make dev_sc CMD='cd $(DEV_FOLDER); make create_horizon_worker APP_FOLDER="$(DEV_FOLDER)" APP_USER="vagrant"'

retry_failed_jobs:
	(cd server; php artisan queue:retry all)
see_failed_jobs:
	(cd server; php artisan queue:failed)
process_all_jobs:
	(cd server; php artisan queue:work --stop-when-empty)

dev_run_queue:
	make dev_artisan_debug CMD='queue:work database --queue=publish,default --sleep=3 --tries=3 --timeout=60'
dev_run_schedule:
	make dev_artisan_debug CMD='schedule:run'
dev_run_horizon:
	make dev_artisan CMD='horizon'

#
# Diagnostics
#
check_disk_space:
	df -h
check_folder_size:
	du -sh
