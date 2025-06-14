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

# Required for CloudTrail to write logs
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}"
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "challenge-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  # Management Events - Read
  advanced_event_selector {
    name = "ManagementEventsRead"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["true"]
    }
  }

  # Management Events - Write
  advanced_event_selector {
    name = "ManagementEventsWrite"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["false"]
    }
  }

  # S3 Data Events - Read
  advanced_event_selector {
    name = "S3Read"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field  = "resources.ARN"
      equals = ["arn:aws:s3:::challenge-docker-backups/"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["true"]
    }
  }

  # S3 Data Events - Write
  advanced_event_selector {
    name = "S3Write"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field  = "resources.ARN"
      equals = ["arn:aws:s3:::challenge-docker-backups/"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["false"]
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
