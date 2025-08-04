variable "tags" {

  description = "Tags nedded to create an object"
  type        = map(string)
}

variable "name_prefix" {
  
  description = "to change between workspaces"
  type = string
}

variable "user_name" {
  
  description = "to change username"
  type = string
}

variable "subnets" {
  description = "Map of availability zones to CIDR blocks for subnets"
  type = map(string)

}

variable "vpc_cidr_block" { 

  description = "cidr_block for vpc"
  type = string
}

