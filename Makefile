IMAGE_TAG=wordpress:apache

SCW_REGION=fr-par

NAMESPACE_NAME=wordpress
CONTAINER_NAME=wordpress

CONTAINER_MIN_SCALE=1
CONTAINER_MAX_SCALE=1
CONTAINER_MEMORY=1024

DB_INSTANCE_NAME=wordpress
DB_USER=wordpress
DB_NAME=rdb
DB_PASSWORD=W0rdpress!
DB_NODE_TYPE=DB-DEV-S

# DEPLOYMENT

# Function to get the container ID
define container_id
	ns_id=$(shell scw container container \
		  list -o json | \
		  jq -r '.[] | select(.name=="$(CONTAINER_NAME)") | .id')

	$(1) := $$(ns_id)
endef

# Function to get the container host
define container_host
	host=$(shell scw container container \
		  list -o json | \
		  jq -r '.[] | select(.name=="$(CONTAINER_NAME)") | .domain_name')

	$(1) := $$(host)
endef

# Function to get the namespace ID
define namespace_id
	ns_id=$(shell scw container namespace \
		  list region=${SCW_REGION} -o json | \
		  jq -r '.[] | select(.name=="$(NAMESPACE_NAME)") | .id')
	$(1) := $$(ns_id)
endef

# Function to get the database host
define db_host
	host=$(shell scw rdb instance \
		  list -o json | \
		  jq -r '.[] | select(.name=="$(DB_INSTANCE_NAME)") | .endpoint.ip')
	$(1) := $$(host)
endef

# Function to get the database port
define db_port
	port=$(shell scw rdb instance \
		  list -o json | \
		  jq -r '.[] | select(.name=="$(DB_INSTANCE_NAME)") | .endpoint.port')
	$(1) := $$(port)
endef

# Function to get the database ID
define db_id
	db_id=$(shell scw rdb instance \
		  list -o json | \
		  jq -r '.[] | select(.name=="$(DB_INSTANCE_NAME)") | .id')
	$(1) := $$(db_id)
endef

.PHONY: create-db
create-db:
	scw rdb \
		instance \
		create \
		engine=MySQL-8 \
		name=${DB_INSTANCE_NAME} \
		user-name=${DB_USER} \
		node-type=${DB_NODE_TYPE} \
		password=${DB_PASSWORD} \
		disable-backup=true

.PHONY: delete-db
delete-db:
	$(eval $(call db_id,_db))
	scw rdb \
		instance \
		delete \
		${_db}

.PHONY: create-namespace
create-namespace:
	scw container namespace \
		create \
		name=${NAMESPACE_NAME} \
		region=${SCW_REGION}
	sleep 10

.PHONY: create-container
create-container:
	$(eval $(call namespace_id,_id))
	$(eval $(call db_host,_db))
	$(eval $(call db_port,_p))
	scw container container create \
		namespace-id=${_id} \
		name=${CONTAINER_NAME} \
		min-scale=${CONTAINER_MIN_SCALE} \
		max-scale=${CONTAINER_MAX_SCALE} \
		memory-limit=${CONTAINER_MEMORY} \
		port=80 \
		registry-image=${IMAGE_TAG} \
		region=${SCW_REGION} \
		environment-variables.WORDPRESS_DB_HOST=${_db}:${_p} \
		environment-variables.WORDPRESS_DB_NAME=${DB_NAME} \
		environment-variables.WORDPRESS_DB_USER=${DB_USER} \
		environment-variables.WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
	sleep 10

.PHONY: deploy-container
deploy-container:
	$(eval $(call container_id,_id))
	scw container container deploy ${_id} \
	region=${SCW_REGION}

.PHONY: delete-container
delete-container:
	$(eval $(call container_id,_id))
	scw container container \
		delete \
		${_id} \
		region=${SCW_REGION}

.PHONY: url
url:
	$(eval $(call container_host,_h))
	echo "https://${_h}"

.PHONY: db-endpoint
db-endpoint:
	$(eval $(call db_host,_h))
	echo "${_h}"

.PHONY: sql
sql:
	$(eval $(call db_host,_h))
	$(eval $(call db_port,_p))
	mysql --host=${_h} --user=${DB_USER} --password=${DB_PASSWORD} --port=${_p} ${DB_NAME}

.PHONY: deploy
deploy: create-db create-namespace create-container deploy-container
	$(eval $(call container_host,_h))
	echo "Deploy finished. Check it out at ${_h}"

# LOCAL DEV

.PHONY: dc-up
dc-up:
	docker compose build
	docker compose up -d

.PHONY: dc-down
dc-down:
	docker compose down

