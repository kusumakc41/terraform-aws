variable "vpc_security_group_ids" {
  type = map(list(string))
  default = {
    "K8 group" = ["sg-06b7ac25d38b73a68"]
  }
}

variable "ec2_instance" {
  default = "i-04fe83f3a80dbc3d6"
}

variable "availability_zone" {
  default = "ap-southeast-1a"
}
