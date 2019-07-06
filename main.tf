# Configure AWS connection, secrets are in terraform.tfvars
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# Get availability zones for the region specified in var.region
data "aws_availability_zones" "all" {}

# Create autoscaling policy -> target at a 65% average CPU load
resource "aws_autoscaling_policy" "Company_News-asg-policy-1" {
  name                   = "Company_News-asg-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.Company_News-asg.name}"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 65.0
  }
}

# Create an autoscaling group
resource "aws_autoscaling_group" "Company_News-asg" {
  name = "Company_News-asg"
  launch_configuration = "${aws_launch_configuration.Company_News-lc.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 2
  max_size = 10

  load_balancers = ["${aws_elb.Company_News-elb.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "Company_News-ASG"
    propagate_at_launch = true
  }
}

# Create launch configuration
resource "aws_launch_configuration" "Company_News-lc" {
  name = "Company_News-lc"
  image_id = "ami-5652ce39"
  instance_type = "t2.nano"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.Company_News-lc-sg.id}"]

  iam_instance_profile = "${var.iam_instance_profile}"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo service httpd start
              sudo chkconfig httpd on
              aws s3 cp "${var.s3_bucket_file1}" /var/lib/webapps --path to copy the war file
              sudo service httpd start
			  aws s3 cp "${var.s3_bucket_file2}" /home/usr --path to copy the zip files
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Create the ELB
resource "aws_elb" "Company_News-elb" {
  name = "Company_News-elb"
  security_groups = ["${aws_security_group.Company_News-elb-sg.id}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = ""HTTPS:443/""
  }

  # This adds a listener for incoming HTTPS requests.
  listener {
    lb_port = 443
    lb_protocol = "https"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}

# Create security group that's applied the launch configuration
resource "aws_security_group" "Company_News-lc-sg" {
  name = "Company_News-lc-sg"

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.ssh_port}"
    to_port = "${var.ssh_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create security group that's applied to the ELB
resource "aws_security_group" "Company_News-elb-sg" {
  name = "Company_News-elb-sg"

  # Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
