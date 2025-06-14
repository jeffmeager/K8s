# ----------------------------------------
# GuardDuty Terraform Module

resource "aws_guardduty_detector" "main" {
  enable = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# ----------------------------------------
# CloudTrail with S3 Backend

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "challenge-cloudtrail-logs"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "Challenge CloudTrail Logs"
  }
}

resource "aws_cloudtrail" "main" {
  name                          = "challenge-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  data_event_selector {
    read_write_type = "All"

    # include all S3 transactions to public bucket
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::challenge-docker-backups/"]
    }
  }

  tags = {
    Name = "Challenge CloudTrail"
  }
}

# ----------------------------------------
# Allow Fluentbit to write logs

resource "aws_iam_policy" "fluentbit_cloudwatch_logs" {
  name        = "FluentBitCloudWatchLogs"
  description = "Allow Fluent Bit to write logs to CloudWatch"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentbit_logs_attach" {
  role       = aws_iam_role.eks_node.name
  policy_arn = aws_iam_policy.fluentbit_cloudwatch_logs.arn
}
