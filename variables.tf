variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "amis" {
  type = "map"
  default = {
      "us-west-2" = "ami-db710fa3"
      "us-east-1" = "ami-b374d5a5"
  }
}



