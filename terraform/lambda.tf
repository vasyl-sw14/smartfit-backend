data "aws_ecr_repository" "lambda_repository" {
  name = "lambda-images"
}

resource "aws_sqs_queue" "video_processing" {
  name                       = "inference-queue"
  max_message_size           = 2048
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 900
  # fifo_queue                  = true
  # content_based_deduplication = true
}

resource "aws_sqs_queue" "video_estimation" {
  name                       = "estimation-queue"
  max_message_size           = 2048
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 900
  # fifo_queue                  = true
  # content_based_deduplication = true
}

data "aws_ecr_repository" "squats_inference_repository" {
  name = "squats-inference-images"
}

resource "aws_lambda_function" "squats_inference" {
  function_name = "SquatsInference"
  timeout       = 900
  image_uri     = "${data.aws_ecr_repository.squats_inference_repository.repository_url}:latest"
  package_type  = "Image"
  memory_size   = 3008
  ephemeral_storage {
    size = 512
  }

  role = "arn:aws:iam::811201412989:role/service-role/VideoProcessing-role-ykidmgdx"
}

data "aws_ecr_repository" "overhead_press_inference_repository" {
  name = "squats-inference-images"
}

resource "aws_lambda_function" "overhead_press_inference" {
  function_name = "OverheadPressInference"
  timeout       = 900
  image_uri     = "${data.aws_ecr_repository.overhead_press_inference_repository.repository_url}:latest"
  package_type  = "Image"
  memory_size   = 3008
  ephemeral_storage {
    size = 512
  }

  role = "arn:aws:iam::811201412989:role/service-role/VideoProcessing-role-ykidmgdx"
}

resource "aws_lambda_function_event_invoke_config" "sqs_estimation" {
  function_name = aws_lambda_function.squats_inference.function_name

  destination_config {
    on_failure {
      destination = aws_sqs_queue.video_estimation.arn
    }

    on_success {
      destination = aws_sqs_queue.video_estimation.arn
    }
  }
}

data "aws_ecr_repository" "segmentation_repository" {
  name = "segmentation-images"
}

resource "aws_lambda_function" "video_segmentation" {
  function_name = "VideoSegmentation"
  timeout       = 900
  image_uri     = "${data.aws_ecr_repository.segmentation_repository.repository_url}:latest"
  package_type  = "Image"
  memory_size   = 3008
  ephemeral_storage {
    size = 1024
  }

  role = "arn:aws:iam::811201412989:role/service-role/VideoProcessing-role-ykidmgdx"
}

data "aws_ecr_repository" "estimation_repository" {
  name = "estimation-images"
}

resource "aws_lambda_function" "estimation_function" {
  function_name = "EstimationFunction"
  timeout       = 900
  image_uri     = "${data.aws_ecr_repository.segmentation_repository.repository_url}:latest"
  package_type  = "Image"
  memory_size   = 3008
  ephemeral_storage {
    size = 1024
  }

  role = "arn:aws:iam::811201412989:role/service-role/VideoProcessing-role-ykidmgdx"
}

resource "aws_lambda_function_event_invoke_config" "sqs" {
  function_name = aws_lambda_function.video_segmentation.function_name

  destination_config {
    on_failure {
      destination = aws_sqs_queue.video_processing.arn
    }

    on_success {
      destination = aws_sqs_queue.video_processing.arn
    }
  }
}

data "aws_s3_bucket" "bucket" {
  bucket = "smartfit-input-bucket160809-dev"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_segmentation.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.video_segmentation.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.video_processing.arn
  function_name    = aws_lambda_function.squats_inference.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger_estimation" {
  event_source_arn = aws_sqs_queue.video_estimation.arn
  function_name    = aws_lambda_function.estimation_function.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger_overhead_press" {
  event_source_arn = aws_sqs_queue.video_processing.arn
  function_name    = aws_lambda_function.overhead_press_inference.arn

  filter_criteria {
    filter {
      pattern = jsonencode({
        body = {
          type : ["overhead_press"]
        }
      })
    }
  }
}

