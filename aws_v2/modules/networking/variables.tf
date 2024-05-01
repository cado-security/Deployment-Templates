variable "ssh_location" {
  type = list(string)
}

variable "http_location" {
  type = list(string)
}

variable "certificate_arn" {
  type = string
}

variable "public_deployment" {
  type = bool
}

variable "private_load_balancer" {
  type = bool
}

variable "tags" {
  type = map(string)
}


variable "custom_networking" {
  description = "Custom networking configuration. Set to null to create new resources."
  type = object({
    vpc_id             = string
    public_subnet_id   = string
    private_subnet_id  = string
    public_subnet_b_id = string
  })
  default = null
}
