variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "us-west-2"
}

variable "s3_folders" {
  type        = "list"
  description = "The list of S3 folders to create"
  default     = ["config", "license", "software", "content"]
}
