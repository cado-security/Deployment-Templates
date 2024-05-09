variable "region" {
  description = "The zone where the VM will be deployed"
  type        = string
}

variable "unique_name" {
  type = string
}

variable "allowed_ips" {
  type = list(string)
}

variable "inbound_ports" {
  description = "The list of ports to open"
  type        = list(string)
}

variable "local_ports" {
  description = "The list of ports to open to speak on the local subnet"
  type        = list(string)
}

variable "custom_networking" {
  description = "Custom networking configuration. Set to null to create new resources."
  type = object({
    vpc_name           = string
    public_subnet_name = string
  })
  default = null
}
