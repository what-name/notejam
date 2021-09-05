variable "repository_id" { type = string }
variable "branch_name" { type = string }

resource "aws_iam_role" "pipeline_role" {
  name = "${var.project}-${terraform.workspace}-pipelines-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role" "cw_role" {
  name = "${var.project}-${terraform.workspace}-cw-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "${var.project}-${terraform.workspace}-pipelines-policy"
  role = aws_iam_role.pipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*",
        "codestar-connections:UseConnection",
        "codedeploy:*",
        "codebuild:*",
        "codebuild:*",
        "cloudwatch:*",
        "autoscaling:*",
        "ecs:*",
        "ec2:*",
        "logs:*",
        "ecr:*",
        "ssm:GetParameter"
      ],
      "Resource": [
        "*"
      ]
    },
    {
        "Action": [
            "iam:PassRole"
        ],
        "Resource": "*",
        "Effect": "Allow",
        "Condition": {
            "StringEqualsIfExists": {
                "iam:PassedToService": [
                    "ec2.amazonaws.com",
                    "ecs-tasks.amazonaws.com"
                ]
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cw_policy" {
  name = "${var.project}-${terraform.workspace}-cw-policy"
  role = aws_iam_role.cw_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project}-${terraform.workspace}-artifacts"
  acl    = "private"

  server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "AES256"
        }
      }
  }
}

# CodePipeline
resource "aws_codepipeline" "notejam" {
  name     = "${var.project}-${terraform.workspace}-codepipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["AppSource"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github-connection.arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = []

      configuration = {
        # get only codebuild project name
        ProjectName = element(split("/", aws_codebuild_project.test.id), 1)
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = ["AppBuild"]

      configuration = {
        # get only codebuild project name
        ProjectName = element(split("/", aws_codebuild_project.build.id), 1)
      }
    }
  }

  stage {
    name = "Migrations"

    action {
      name             = "Migrations"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = []

      configuration = {
        # get only codebuild project name
        ProjectName = element(split("/", aws_codebuild_project.migrate.id), 1)
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "DeployWorker"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["AppBuild"]
      output_artifacts = []

      configuration   = {
        ClusterName   = aws_ecs_cluster.cluster.id
        ServiceName   = aws_ecs_service.worker.name
        FileName      = "image-definitions.json"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github-connection" {
  name          = "github-connection"
  provider_type = "GitHub"
}
