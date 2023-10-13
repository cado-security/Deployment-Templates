# Adjust configuration options for your GCP deployment.

# General settings
unique_name      = "unique-deployment-name"              # Unique name for deployed resources.
credentials_file = "local/path/to/your/credentials.json" # Specify the local path to your GCP credentials file.
project_id       = "your-gcp-project-id"                 # Provide the ID of your GCP project.
region           = "us-central1"                         # Specify the region where you'd like to deploy.
image            = "cado-response-image-link"            # VM image link you'd like to use.

# Tags to identify deployed resources.
tags = {
  name = "cadoresponse"
  # example_tag_key2 = "example_value2"
  # Add more tags as needed by following the format: tag_name = "tag_value"
}

# VM and storage settings
# These options help you determine the size and scale of your deployment.
# (You can leave them as defaults if unsure.)
vm_size  = "n2d-standard-8" # Choose your desired VM size. Default is "n2d-standard-8".
vol_size = 100              # Desired disk volume size in GB. Default is 100.

# Network settings
allowed_ips = ["1.2.3.4/32", "2.3.4.5/32"] # List IPs you wish to whitelist.
