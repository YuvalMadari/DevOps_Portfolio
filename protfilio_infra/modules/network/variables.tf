variable "tags" {

    description = "Tags nedded to create an object"
    type = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {

  description = "Map of availability zones to CIDR blocks for subnets"
  type = map(string)

}

variable "name_prefix" {
  description = "Prefix for naming VPC resources"
  type        = string
}

variable "user_name" {
  description = "user name for naming VPC resources"
  type        = string
}

