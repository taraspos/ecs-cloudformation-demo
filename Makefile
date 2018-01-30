ECR_REPO ?= $(shell awless list repositories --format json | jq -r '.[].URI' 2> /dev/null | grep archer)
IMAGE_TAG ?= latest
PARENT_STACK_NAME := parent
USERS_STACK_NAME := test-users
ECS_STACK_NAME ?= archersaurus

image:
	awless --no-sync authenticate registry no-confirm=true --force
	docker build -t $(ECR_REPO):$(IMAGE_TAG) .
	docker push $(ECR_REPO):$(IMAGE_TAG)

deploy:
	awless update stack --no-sync --force \
		name=$(ECS_STACK_NAME) \
		template-file=templates/$(ECS_STACK_NAME).yml \
		stack-file=templates/$(ECS_STACK_NAME).config.yml \
		capabilities=CAPABILITY_IAM \
		parameters=[ImageTag:$(IMAGE_TAG)]

watch:
	awless tail stack-events $(ECS_STACK_NAME) --follow 

# provision initial infrastructure
users:
	awless create stack \
		name=$(USERS_STACK_NAME) \
		template-file=templates/users.yml \
		capabilities=CAPABILITY_NAMED_IAM

parent_create:
	awless create stack \
		name=$(PARENT_STACK_NAME) \
		template-file=templates/parent.yml \
		capabilities=CAPABILITY_IAM \
		stack-file=templates/parent.config.yml

parent: parent_create
	awless tail stack-events $(PARENT_STACK_NAME) --follow

archersaurus: image
	awless create stack \
		name=$(ECS_STACK_NAME) \
		template-file=templates/archersaurus.yml \
		capabilities=CAPABILITY_IAM \
		stack-file=templates/archersaurus.config.yml \
		parameters=[ImageTag:latest,ParentStack:$(PARENT_STACK_NAME)] \
		role=$$(awless show $$(awless list roles --filter name=CFDeployRole --ids) --values-for arn) \
		rollback-triggers=$$(awless list alarms --filter name=TaskFailAlarm --ids)

# some helpers for demo
repos:
	awless list repositories

show_users_stack:
	awless show $(USERS_STACK_NAME)

show_ecs_stack:
	awless show $(ECS_STACK_NAME)