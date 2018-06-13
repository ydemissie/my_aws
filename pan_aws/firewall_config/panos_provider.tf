provider "panos" {
  hostname = "${var.fw_ip}"
  api_key = "${var.api_key}"
#  username = "${var.username}"
#  password = "${var.password}"
}