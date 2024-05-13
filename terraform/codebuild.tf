resource "aws_ecr_repository" "segmentation_repository" {
  name                 = "segmentation-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_codebuild_project" "segmentation" {
  name          = "SegmentationProject"
  description   = ""
  build_timeout = 10
  service_role  = "arn:aws:iam::811201412989:role/service-role/codebuild-docker-service-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "811201412989"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "segmentation-images"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "CI/CD"
      stream_name = "Docker"
    }
  }

  source {
    buildspec       = file("buildspec/segmentation_buildspec.yml")
    type            = "GITHUB"
    location        = "https://github.com/vasyl-sw14/smart-fit"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

resource "aws_codebuild_project" "squats_inference" {
  name          = "SquatsInferenceProject"
  description   = ""
  build_timeout = 10
  service_role  = "arn:aws:iam::811201412989:role/service-role/codebuild-docker-service-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "811201412989"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "squats-inference-images"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "CI/CD"
      stream_name = "Docker"
    }
  }

  source {
    buildspec       = file("buildspec/squats_inference_buildspec.yml")
    type            = "GITHUB"
    location        = "https://github.com/vasyl-sw14/smart-fit"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

resource "aws_codebuild_project" "overhead_press_inference" {
  name          = "OverheadPressInferenceProject"
  description   = ""
  build_timeout = 10
  service_role  = "arn:aws:iam::811201412989:role/service-role/codebuild-docker-service-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "811201412989"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "overhead-press-inference-images"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "CI/CD"
      stream_name = "Docker"
    }
  }

  source {
    buildspec       = file("buildspec/overhead_press_inference_buildspec.yml")
    type            = "GITHUB"
    location        = "https://github.com/vasyl-sw14/smart-fit"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

resource "aws_ecr_repository" "estimation_repository" {
  name                 = "estimation-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_codebuild_project" "estimation_project" {
  name          = "EstimationProject"
  description   = ""
  build_timeout = 10
  service_role  = "arn:aws:iam::811201412989:role/service-role/codebuild-docker-service-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "811201412989"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "estimation-images"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "CI/CD"
      stream_name = "Docker"
    }
  }

  source {
    buildspec       = file("buildspec/estimation_buildspec.yml")
    type            = "GITHUB"
    location        = "https://github.com/vasyl-sw14/smart-fit"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
}
