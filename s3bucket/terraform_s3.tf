provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_s3_bucket" "aws-pan-s3" {
  bucket = "aws-pan-s3"
  acl    = "private"
}

resource "aws_s3_bucket_object" "folders" {
  count  = "${length(var.s3_folders)}"
  bucket = "${aws_s3_bucket.aws-pan-s3.id}"
  acl    = "private"
  key    = "${var.s3_folders[count.index]}/"
  source = "empty.txt"
}
