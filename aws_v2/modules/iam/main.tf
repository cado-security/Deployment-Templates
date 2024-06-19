data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "role" {
  name_prefix = "myCadoResponseRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
          AWS     = aws_iam_role.instance_role.arn
        }
      },
    ]
  })

  path = "/"

  max_session_duration = 43200

  tags = merge(
    var.tags,
    {
      tag-key = "CadoResponseRole"
    }
  )
}

resource "aws_iam_role" "instance_role" {
  name_prefix = "myCadoResponseInstanceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  path = "/"

  max_session_duration = 43200

  tags = merge(
    var.tags,
    {
      tag-key = "CadoResponseInstanceRole"
    }
  )
}

resource "aws_iam_role_policy" "instance_policy" {
  name_prefix = "myCadoResponseInstanceRolePolicy"
  role        = aws_iam_role.instance_role.id
  policy = <<JSON
{
    "Statement": [
        {
            "Sid": "Required",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole",
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:ListRolePolicies",
                "iam:PassRole",
                "sts:GetCallerIdentity",
                "sts:GetSessionToken"
            ],
            "Resource": "${aws_iam_role.role.arn}"
        },
        {
            "Sid": "RequiredForStartup",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForStartup2",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:PutSecretValue",
                "secretsmanager:CreateSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:TagResource"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Name": "CadoResponse*"
                }
            }
        },
        {
            "Sid": "RequiredForCloudWatchAgent",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/var/logs/cado:*"
        }
    ]
}
JSON
}

resource "aws_iam_role_policy" "policy" {
  name_prefix = "myCadoResponseRolePolicy"
  role        = aws_iam_role.role.id
  policy = <<JSON
{
    "Statement": [
        {
            "Sid": "RequiredForEC2ImportAndCorePlatform",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume",
                "ec2:DeleteSnapshot",
                "ec2:TerminateInstances",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress",
                "secretsmanager:PutSecretValue",
                "secretsmanager:CreateSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:TagResource"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Name": "CadoResponse*"
                }
            }
        },
        {
            "Sid": "RequiredToCheckPolicy",
            "Action": [
                "iam:GetPolicy",
                "iam:GetPolicyVersion"
            ],
            "Resource": "arn:aws:iam::*:policy/*CadoResponse*",
            "Effect": "Allow"
        },
        {
            "Sid": "RequiredForCrossAccountAccess",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole",
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:ListRolePolicies",
                "iam:PassRole",
                "iam:CreateServiceLinkedRole",
                "sts:GetCallerIdentity",
                "sts:GetSessionToken"
            ],
            "Resource": "arn:aws:iam::*:role/*CadoResponse*"
        },
        {
            "Sid": "RequiredToAccessCadoS3Bucket",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::${var.s3_bucket_id}"
        },
        {
            "Sid": "RequiredForAcquireToS3",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:RestoreObject",
                "s3:PutObjectTagging",
                "s3:GetObjectTagging"
            ],
            "Resource": "arn:aws:s3:::${var.s3_bucket_id}/*"
        },
        {
            "Sid": "RequiredForS3Readiness",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${var.s3_bucket_id}/*"
        },
        {
            "Sid": "RequiredForMemoryForensics",
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand",
                "ssm:DescribeInstanceInformation"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*::document/AWS-RunShellScript",
                "arn:aws:ssm:*::document/AWS-RunPowerShellScript"
            ]
        },
        {
            "Sid": "RequiredForS3Import",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        },
        {
            "Sid": "RequiredForKmsEncryptedEc2Import",
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:CreateGrant"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForKMSKeyTypeDeterminationDuringEncryptedEc2Import",
            "Effect": "Allow",
            "Action": [
                "kms:DescribeKey",
                "kms:ListAliases"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForCrossAccountDefaultKmsEncryptedEc2Import",
            "Effect": "Allow",
            "Action": [
                "kms:CreateKey",
                "kms:CreateAlias"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForOperationsOnTemporaryKMSResourcesduringDefaultEncryptedEc2Import",
            "Effect": "Allow",
            "Action": [
                "kms:DeleteAlias",
                "kms:ReplicateKey",
                "kms:ScheduleKeyDeletion"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringLike": {
                    "kms:ResourceAliases": "alias/CadoResponse-KMS-Alias*"
                },
                "ForAnyValue:StringLike": {
                    "kms:ResourceAliases": "alias/CadoResponse-KMS-Alias*"
                }
            }
        },
        {
            "Sid": "RequiredForLambdaImport",
            "Effect": "Allow",
            "Action": [
                "lambda:GetFunction",
                "lambda:ListFunctions",
                "logs:FilterLogEvents",
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadURLForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForEcsImport",
            "Effect": "Allow",
            "Action": [
                "ecs:ListClusters",
                "ecs:DescribeClusters",
                "ecs:ListServices",
                "ecs:DescribeServices",
                "ecs:ListTasks",
                "ecs:DescribeTasks",
                "ecs:ExecuteCommand"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForEKSImport",
            "Effect": "Allow",
            "Action": [
                "eks:ListClusters",
                "eks:DescribeCluster"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForEc2ImportAndAmiImport",
            "Effect": "Allow",
            "Action": [
                "cloudtrail:LookupEvents",
                "ec2:DescribeVolumesModifications",
                "ec2:AssociateAddress",
                "ec2:AttachVolume",
                "ec2:CopyImage",
                "ec2:CopySnapshot",
                "ec2:CreateSnapshot",
                "ec2:CreateSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteTags",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeRegions",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetConsoleOutput",
                "ec2:GetConsoleScreenshot",
                "ec2:ImportImage",
                "ec2:ModifySnapshotAttribute",
                "ec2:RunInstances",
                "ec2:DescribeFlowLogs",
                "ssm:DescribeInstanceInformation",
                "ssm:GetCommandInvocation",
                "iam:GetInstanceProfile"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForEc2ImportAndAmiImport2",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Name": "CadoResponse*"
                },
                "StringEquals": {
                    "ec2:Attribute": "BlockDeviceMapping"
                }
            }
        },
        {
            "Sid": "RequiredForResponseActionIsolateEc2",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:Attribute": "GroupId"
                }
            }
        },
        {
            "Sid": "RequiredForAmiImports",
            "Effect": "Allow",
            "Action": [
                "ec2:DeregisterImage"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Name": "CadoResponse*"
                }
            }
        },
        {
            "Sid": "RequiredForHealthChecks",
            "Effect": "Allow",
            "Action": [
                "servicequotas:GetServiceQuota",
                "cloudwatch:GetMetricData",
                "iam:GetRolePolicy",
                "cloudtrail:ListTrails",
                "cloudtrail:GetTrailStatus",
                "iam:SimulatePrincipalPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForNativeUpdatesWithALB",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForGuardDutyMonitoring",
            "Effect": "Allow",
            "Action": [
                "guardduty:ListIPSets",
                "guardduty:ListThreatIntelSets",
                "guardduty:ListDetectors",
                "guardduty:ListOrganizationAdminAccounts",
                "guardduty:ListFindings",
                "guardduty:ListFilters",
                "guardduty:ListPublishingDestinations",
                "guardduty:ListInvitations",
                "guardduty:ListMembers",
                "guardduty:GetFindings"
            ],
            "Resource": "*"
        },
        {
            "Sid": "RequiredForAutomatedErrorReporting",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::cadologsupload/*"
        },
        {
            "Sid": "RequiredForFirstTimeKMSDefaultencryptedImportCanBeDeletedAfter",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::*:role/aws-service-role/mrk.kms.amazonaws.com/AWSServiceRoleForKeyManagementServiceMultiRegionKeys",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": "mrk.kms.amazonaws.com"
                }
            }
        },
        {
            "Sid": "RequiredForAWSOrganizationsDiscoverAccounts",
            "Effect": "Allow",
            "Action": [
                "organizations:ListAccounts"
            ],
            "Resource": "*"
        }
    ]
}
JSON
}

output "role_name" {
  value = aws_iam_role.role.name
}

output "instance_role_name" {
  value = aws_iam_role.instance_role.name
}