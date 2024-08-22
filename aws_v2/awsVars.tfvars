# Adjust configuration options for your AWS deployment.

# General settings
region   = "us-east-1"    # Specify the region where you'd like to deploy.
key_name = "aws_virginia" # Specify the name of the key pair you'd like to use.
ami_id   = "ami-12345"    # VM image you'd like to use.

public_deployment = false                                   # Set to true if you want to deploy a public instance. Set to false for a private instance.
certificate_arn   = "arn:aws:iam::1234:server-certificate/" # ARN of the certificate you'd like to use for HTTPS. Only required for private deployments.

# Tags to identify deployed resources.
tags = {
  launch_date = "01/01/1970"
  # example_tag_key2 = "example_value2"
  # Add more tags as needed by following the format: tag_name = "tag_value"
}

# VM and storage settings
# These options help you determine the size and scale of your deployment.
# (You can leave them as defaults if unsure.)
vm_size  = "m5.4xlarge" # Choose your desired VM size. Default is "m5.4xlarge".
vol_size = 100          # Desired disk volume size in GB. Default is 100.

# Network settings
ssh_location  = ["1.2.3.4/32"] # List IPs you wish to whitelist for SSH access (Public Deployments Only)
http_location = ["2.3.4.5/32"] # List IPs you wish to whitelist for HTTP access


# If you'd like to use custom networking, uncomment the following block and provide the necessary information.
# If you're unsure, leave this section commented out and the deployment will use default networking settings.
# Note: public_subnet_b_id and private_subnet_id are only used for Private IP deployments.

# custom_networking = {
#     vpc_id             = "vpc-12345"
#     public_subnet_id   = "subnet-12345"
#     public_subnet_b_id = "subnet-12345"
#     private_subnet_id  = "subnet-12345"
# }
