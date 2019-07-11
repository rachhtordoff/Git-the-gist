RUN_TEST_NO_UPDATE:=bash test.sh --noinstall --no-update --novirtualenv --strict

MICROSERVICE_NAME:=gel_messages

help: ## Prints this help/overview message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-17s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

run: stop build start_foreground ## Builds all containers and (re)runs them in foreground.

restart: stop start ## Restarts all containers

build: ## Builds all containers
	bash test.sh --update
	docker-compose build
	@echo -e "\e[1m\e[93mYou may need to import data in order for the microservice to function. Run:\e[0m\nmake data\e[0;37m"

rebuild: down build start ## Fully rebuild containers

start: ## Starts all containers
	docker-compose up -d

start_foreground: ## Starts all containers in foreground
	docker-compose up

stop: ## Stops all containers
	docker-compose stop

down: ## Fully stops containers, removing persistence
	docker-compose down

clean: ## Cleans all build containers and images. Stops everything as well.
	docker-compose down --volumes --rmi all || true
	rm -rf cover .mypy_cache .venv* .coverage .pytest_cache *_test_results.xml

venv: ## Sets up local virtual env
	bash test.sh --no-update --install

status: ## Shows status of all containers
	docker-compose ps

test: ## Updates requirements, rules and runs all available tests locally.
	bash test.sh --strict

lint: ## Runs linter on source code and tests. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -p

unittest: ## Runs all unit tests without coverage test. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -u

component-test: ## Runs all component tests without coverage test. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -ct

coverage: ## Runs unit test coverage test. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -c

types: ## Runs types test. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -t

bdd: ## Runs all BDD tests. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -b

format: ## Runs the code formatter. Does not update requirements or rules.
	$(RUN_TEST_NO_UPDATE) -fmt

integration: ## Runs integration tests related to this microservice
	bash integration.sh

todo:
	$(RUN_TEST_NO_UPDATE) --todo

data: start db-import-remote ## Initialise all of the data backing services

test-data: start ## Add test data over the top of the existing data
	docker-compose exec ${MICROSERVICE_NAME} sh -c "python scripts/make_test_data.py"

db-import: ## Import database from local backup store
	bash build-scripts/db-import.sh --skip-prompt $(MICROSERVICE_NAME)

db-import-remote: db-get-latest-backup db-import ## Import database, checking remote for latest first

db-backup: ## Backup database
	bash build-scripts/db-backup.sh $(MICROSERVICE_NAME)

db-get-latest-backup: ## Get latest backup from remote
	bash build-scripts/db-get-latest-backup.sh $(MICROSERVICE_NAME)

db-migrate: clean build start db-import-remote ## Create an alembic migration
	bash build-scripts/db-make-migrations.sh $(MICROSERVICE_NAME) $(MIGRATION_NAME)

psql: ## Enter the database backing service cli
	docker-compose exec db psql -U postgres

sh:
	docker-compose run --rm --service-ports $(MICROSERVICE_NAME) sh
