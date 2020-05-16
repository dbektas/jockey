/* ----------------------------------------------------------------------------------------------- */

resource "aws_codecommit_repository" "dev_tools" {
  repository_name = "jockey-pokemon-webassets"
  description     = "Code repository for Jockey serverless application"

  lifecycle {
    prevent_destroy = true
  }

  tags = {}
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_s3_bucket" "dev_tools_artifact" {
  bucket = "jockey-dev-tools-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {}
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_codebuild_project" "dev_tools" {
  name         = "jockeyPokemonAssets"
  description  = "Jockey Webassets AWS CodeBuild project"
  service_role = aws_iam_role.dev_tools_build.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:3.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "ARTIFACT_STORE"
      value = aws_s3_bucket.dev_tools_artifact.id
      type  = "PLAINTEXT"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2
phases:
    install:
        runtime-versions:
            nodejs: 12
    pre_build:
        commands:
            - echo Installing NPM dependencies...
            - npm install -no-color
    build:
        commands:
            - npm run build -no-color
    post_build:
        commands:
            - echo Uploading to AssetsBucket 
            - aws s3 cp --recursive ./build s3://${aws_s3_bucket.pokemons.id}/
            - aws s3 cp --cache-control="max-age=0, no-cache, no-store, must-revalidate" ./build/service-worker.js s3://${aws_s3_bucket.pokemons.id}/
            - aws s3 cp --cache-control="max-age=0, no-cache, no-store, must-revalidate" ./build/index.html s3://${aws_s3_bucket.pokemons.id}/
            - aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths /index.html /service-worker.js

artifacts:
    files:
        - '**/*'
    base-directory: build
BUILDSPEC
  }

  tags = {}
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_codepipeline" "dev_tools" {
  name     = "jockeyPokemonAssets"
  role_arn = aws_iam_role.dev_tools_pipeline.arn

  artifact_store {
    location = aws_s3_bucket.dev_tools_artifact.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]
      run_order        = 1

      configuration = {
        RepositoryName       = aws_codecommit_repository.dev_tools.repository_name
        BranchName           = "master"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.dev_tools.name
      }
    }
  }
  depends_on = [aws_codebuild_project.dev_tools]

  tags = {}
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_cloudwatch_event_rule" "dev_tools" {
  name        = "codepipeline-dev-tools-rule"
  description = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the AWS CodeCommit source repository and branch."

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.dev_tools.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "master"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "dev_tools" {
  rule     = aws_cloudwatch_event_rule.dev_tools.name
  arn      = aws_codepipeline.dev_tools.arn
  role_arn = aws_iam_role.cw_events.arn
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_iam_role" "dev_tools_build" {
  name        = "DevToolsBuildPokemon"
  description = "Creating service role in IAM for AWS CodeBuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "codebuildAssumeRole"
    }
  ]
}
EOF

  tags = {}
}

resource "aws_iam_role_policy" "dev_tools_build" {
  name   = "DevToolsBuild"
  role   = aws_iam_role.dev_tools_build.id
  policy = <<EOF
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "S3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "cloudfront:CreateInvalidation"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "dev_tools_pipeline" {
  name        = "DevToolsPipelinePokemon"
  description = "Creating service role in IAM for AWS CodePipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "codepipelineAssumeRole"
    }
  ]
}
EOF

  tags = {}
}

resource "aws_iam_role_policy" "dev_tools_pipeline" {
  name = "DevToolsPipeline"
  role = aws_iam_role.dev_tools_pipeline.id

  policy = <<EOF
{
  "Statement": [
    {
        "Action": [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": [
            "s3:PutObject",
            "s3:GetObject"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
}

/* ----------------------------------------------------------------------------------------------- */

resource "aws_iam_role" "cw_events" {
  name = "DevToolsCWEventsCodePipelineTriggerPokemon"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {}
}

resource "aws_iam_role_policy" "cw_events" {
  name   = "DevToolsCWEventsCodePipelineTrigger"
  role   = aws_iam_role.cw_events.id
  policy = <<EOF
{
  "Statement": [
    {
      "Sid": "AllowCodePipelineStart",
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

/* ----------------------------------------------------------------------------------------------- */
