# Archesaurus demo

## Steps

1. Provision

    1. Create the `templates/parent.config.yml`, by making copy of `parent.example.config.yml` and setting the existing `VpcID`, `SubnetId` (at least two subntes) `awless list subnets`

    1. Create "users" stack, which will create AWS user and credentials for Travis CI

            make users

    1. Create "parent" stack, which will create ALB, ECS Cluster and ASG, etc

            make parent

    1. Build Docker image and create "app" stack, which will create ECS Service, Target Group, ALB Listener, etc

            make archersaurus

    1. Set the rollback trigger for "app" stack _(this command is not aviliable in the latest (0.1.9) awless yet and require custom build from [my fork](https://github.com/trane9991/awless))_

            make set_rollback_trigger

    1. Deploy [ecs-drain-lambda](https://github.com/getsocial-rnd/ecs-drain-lambda) for instance drain automation

1. ECS AMI Update process

    1. Get lastet ECS AMI Id. [Example](https://gist.github.com/Trane9991/b638d37b0425b47b967046f2c408ccf8)

    1. Update the AMI IDs map in the `templates/parent.yml`

    1. Update parent stack

            make parent_update

    1. Watch the ECS instance being drained in the UI on the ECS page and in the CloudWatch logs of deployed `ecs-drain-lambda`

1. Deploying the app with TravisCI

    1. Fork this repository and [configure TravisCI build](https://docs.travis-ci.com/user/getting-started/)

    1. Get the name of created ECR repository

            make repos

        and copy ECR repo url from output

    1. Get AWS User credentials from create "users" stack

            make show_users_stack

        and copy the credentials from output

    1. Configure Travis CI, by setting [secret env variables](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings) for the project

        - AWS_REGION

        - AWS_ACCESS_KEY_ID

        - AWS_SECRET_ACCESS_KEY

        - ECR_REPO

    1. Push some changes and see that Travis Picked up the build, see the build progress

1. Verifying rollback logic

    1. In the `templates/archersaurus.yml` uncomment the `# Command: ["crash"]` line and push changes