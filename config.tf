locals {
    config = jsondecode(file("${path.module}/${var.config_file}"))

    github_repositories = [for application in local.config.applications : application if application.github_repository.create]

    environments = flatten([for application in local.config.applications : [
        for environment in application.environments : {
        name               = "${var.prefix}-${application.name}-${environment.name}"
        application_name   = "${var.prefix}-${application.name}"
        environment        = environment
        create_github_repo = application.github_repository.create
        vcs_integrated     = environment.vcs_integrated
        }
        ]
    ])

    gitub_team_access = flatten([for repo in local.github_repositories : [
        for team in repo.github_repository.team_access : {
            team_name = team.team_name
            permission = team.permission
            repo_name = "${var.prefix}-${repo.name}"
        }]
    ])
    github_environments   = [for environment in local.environments : environment if environment.create_github_repo]
    github_users          = distinct(flatten([for environment in local.github_environments : environment.environment.github_environment.reviewers_users]))
    github_teams          = distinct(concat(flatten([for environment in local.github_environments : environment.environment.github_environment.reviewers_teams]), flatten([for repo in local.github_repositories : repo.github_repository.team_access[*].team_name])))
    azure_resource_groups = [for environment in local.environments : environment if environment.environment.azure_resource_group.create]
}