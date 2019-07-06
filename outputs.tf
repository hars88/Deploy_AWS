# Display ELB IP address

output "elb_dns_name" {
  value = "${aws_elb.Company_News-elb.dns_name}"
}
