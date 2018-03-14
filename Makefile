ECR_REPO ?= $(shell awless list repositories --format json | jq -r '.[].URI' 2> /dev/null | grep archer)
IMAGE_TAG ?= latest
PARENT_STACK_NAME := parent
USERS_STACK_NAME := test-users
STACK_NAME ?= archersaurus

image:
	awless --no-sync authenticate registry no-confirm=true --force
	docker build -t $(ECR_REPO):$(IMAGE_TAG) .
	docker push $(ECR_REPO):$(IMAGE_TAG)

# building docker image version string, example:
# hotfix123-ccccc-testing
# (CodeShip is removing "/" from branch name, so we need to do that too)
awless_deploy: VERSION=$(subst /,,$(CI_BRANCH))-$(CI_COMMIT_ID)-$(ENVIRONMENT)
awless_deploy:
	awless --no-sync --force \
		update stack  \
			name=$(STACK_NAME) \
			capabilities=CAPABILITY_IAM \
			template-file=$(STACK_TEMPLATE_FILE) \
			stack-file=$(STACK_CONFIG_FILE) \
			parameters=[ImageTag:$(VERSION)]

awless_watch:
	awless --no-sync \
		tail stack-events $(STACK_NAME) \
			--follow  \
			--frequency=6s \
			--timeout=10m \
			--cancel-on-timeout

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

parent_update:
	awless update stack \
		name=$(PARENT_STACK_NAME) \
		template-file=templates/parent.yml \
		capabilities=CAPABILITY_IAM \
		stack-file=templates/parent.config.yml

parent: parent_create
	awless tail stack-events $(PARENT_STACK_NAME) --follow

archersaurus: image
	awless create stack \
		name=$(STACK_NAME) \
		template-file=templates/archersaurus.yml \
		capabilities=CAPABILITY_IAM \
		stack-file=templates/archersaurus.config.yml \
		parameters=[ImageTag:latest,ParentStack:$(PARENT_STACK_NAME)] \
		role=$$(awless show $$(awless list roles --filter name=CFDeployRole --ids) --values-for arn)
		# rollback-triggers=$$(awless list alarms --filter name=TaskFailAlarm --ids)

# some helpers for demo
repos:
	awless list repositories

show_users_stack:
	awless show $(USERS_STACK_NAME)

show_ecs_stack:
	awless show $(STACK_NAME)

show_ecs_alarm:
	awless list alarms --filter name=TaskFailAlarm --ids

set_rollback_trigger: ROLLBACK_TRIGGER_ARN ?= $(shell awless list alarms --filter name=TaskFailAlarm --ids | head -n 1)
set_rollback_trigger:
	awless update stack \
		name=$(STACK_NAME) \
		use-previous-template=true \
		capabilities=CAPABILITY_IAM \
		stack-file=templates/archersaurus.config.yml \
		rollback-triggers='$(ROLLBACK_TRIGGER_ARN)' \
		parameters=[ImageTag:latest,ParentStack:$(PARENT_STACK_NAME)] 