variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}
variable "tags" {
  type    = map(string)
  default = {}
}