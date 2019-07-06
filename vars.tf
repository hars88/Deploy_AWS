variable access_key {}
variable secret_key {}
variable region {}
variable key_name {}
variable s3_bucket_file1 {}
variable s3_bucket_file2 {}
variable iam_instance_profile {}
variable ssl_certificate_id {}

variable "server_port" {
  description = "The port the server will use for HTTPS requests"
  default = 443
}

variable "ssh_port" {
  default = 22
}

variable "count" {
  description = "Number of EC2 instances"
  default = 1
}
