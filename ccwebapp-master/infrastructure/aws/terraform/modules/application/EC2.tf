variable "SUBNET"{
    type=string
    default="us-east-1"
}
variable "SUBNET1"{
    type=string
    default="us-east-1"
}
variable "SUBNET2"{
    type=string
    default="us-east-1"
}
variable "AMI"{
    type=string
    default="us-east-1"
}
variable "Domain"{
    type=string
    default="us-east-1"
}
variable "Zone_id"{
  type=string
  default="us-east-1"
}
variable "KeyName"{
    type=string
    default="us-east-1"
}
variable "CodedeployS3Bucket"{
  type=string
  default="us-east-1"
}
variable "ImageS3Bucket"{
  type=string
  default="us-east-1"
}
variable "AWS_ACCESS_KEY_ID"{
    type=string
    default="us-east-1"
}
variable "AWS_SECRET_ACCESS_KEY"{
    type=string
    default="us-east-1"
}
variable "Account_id"{
    type=string
    default="us-east-1"
}
variable "LambdaBucket"{
  type=string
  default="us-east-1"
}
variable "Identifier"{
  type=string
  default="us-east-1"
}
provider "aws" {
    region =var.Vpc_Region
}
# resource "aws_instance" "TerraformInstance" {
#   ami           = "${var.AMI}"
#   instance_type = "t2.micro"
#   subnet_id =var.SUBNET
#   key_name= "${var.KeyName}"
#   iam_instance_profile="CodeDeployEC2ServiceRole"
#   vpc_security_group_ids=["${aws_security_group.application.id}"]
#   tags = {
#     Name = "Terraform_instance"
#   }
#   depends_on = [aws_db_instance.DB2]
#   user_data = <<-EOF
#             #!/bin/bash -ex
#             exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
#             echo BEGIN
#             date '+Y-%m-%d %H:%M:%S'
#             echo END
#             sudo yum update -y
#             sudo yum install ruby -y
#             sudo yum install wget -y
#             cd /home/centos
#             wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
#             chmod +x ./install
#             sudo service codedeploy-agent status
#             sudo service codedeploy-agent start
#             sudo service codedeploy-agent status
#             echo host=${aws_db_instance.DB2.address} >> .env
#             echo bucket=${var.ImageS3Bucket} >> .env
#             echo secret=${var.AWS_SECRET_ACCESS_KEY} >> .env
#             echo access=${var.AWS_ACCESS_KEY_ID} >> .env
#             chmod 777 .env
#             mkdir webapp
#             chmod 777 .env
#  EOF          
           
# }

/////////// LAUNCH CONFIG //////////////////////////////////////////////////////////////////////////////////////

resource "aws_launch_configuration" "AutoScale_terraform" {
  name          = "AutoScale_terraform"
  key_name      = "${var.KeyName}"
  image_id      = "${var.AMI}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile="CodeDeployEC2ServiceRole"
  #depends_on = [aws_db_instance.DB2]
  security_groups = ["${aws_security_group.application.id}"]
 user_data = <<-EOF
            #!/bin/bash -ex
            exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
            echo BEGIN
            date '+Y-%m-%d %H:%M:%S'
            echo END
            sudo yum update -y
            sudo yum install ruby -y
            sudo yum install wget -y
            cd /home/centos
            wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
            chmod +x ./install
            sudo service codedeploy-agent status
            sudo service codedeploy-agent start
            sudo service codedeploy-agent status
            echo host=${aws_db_instance.DB2.address} >> .env
            echo bucket=${var.ImageS3Bucket} >> .env
            echo secret=${var.AWS_SECRET_ACCESS_KEY} >> .env
            echo access=${var.AWS_ACCESS_KEY_ID} >> .env
            echo domain=${var.Domain} >> .env
            chmod 777 .env
            mkdir webapp
            chmod 777 .env
 EOF
  
   # name_prefix   = "AutoScale_terraform"
    lifecycle {
    create_before_destroy = true
  }
  ebs_block_device{
     device_name="/dev/sdf"
     volume_size=20
     volume_type="gp2"
     delete_on_termination="true"  
    }
 
  # vpc_security_group_ids=["${aws_security_group.application.id}"]

}
# //////////////////////////////AUTO SCALING GROUP/////////////////////////////////////////////////////////////////////////////

resource "aws_autoscaling_group" "AutoScalingGroup" {
  default_cooldown                  = 60
  name                      = "AutoScalingGroup"
  max_size                  = 5
  min_size                  = 3
  desired_capacity          = 3
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.AutoScale_terraform.id}"
  target_group_arns         =[ "${aws_lb_target_group.lb_target_gp.arn}"]
  vpc_zone_identifier       = ["${var.SUBNET}"]
  depends_on                = [aws_launch_configuration.AutoScale_terraform]
  # lifecycle {
  #   create_before_destroy = true
  # }
  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }
}

/////////////////////////////////LOAD BALANCER//////////////////////////////////////////////////////////////////////////////////////////

resource "aws_lb" "LoadBalancer" {
  name               = "LoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_security.id}"]
  subnets            = ["${var.SUBNET}","${var.SUBNET1}"]
  enable_deletion_protection = false
  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #   prefix  = "test-lb"
  #   enabled = true
  # } 
}

resource "aws_lb_target_group" "lb_target_gp" {
  name     = "lbtargetgp"
  port     = "3000"
  protocol = "HTTP"
  vpc_id   = "${var.Vpc_id}"
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.LoadBalancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:${var.Account_id}:certificate/${var.Identifier}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_target_gp.arn}"
  }
}
resource "aws_route53_record" "www" {
  #zone_id = "Z1J1UOIKQEIU66"
  zone_id = "${var.Zone_id}"
  name    = "${var.Domain}"
  type    = "A"
  depends_on =[aws_lb.LoadBalancer]
  alias {
    name                   = "${aws_lb.LoadBalancer.dns_name}"
    zone_id                = "${aws_lb.LoadBalancer.zone_id}"
    evaluate_target_health = true
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
# resource "aws_eip" "ip" {
#   instance = "${aws_launch_configuration.as_conf.id}"
#   vpc      = true
# }
resource "aws_db_subnet_group" "SUBNETGROUP" {
  name       = "subnetsgroup"
  subnet_ids = ["${var.SUBNET}","${var.SUBNET1}"]

  tags = {
    Name = "SUBNETGROUP"
  }
}
resource "aws_db_instance" "DB2" {
  allocated_storage    = 20
  storage_type         = "gp2"
  db_subnet_group_name = "${aws_db_subnet_group.SUBNETGROUP.name}"
  engine               = "postgres"
  vpc_security_group_ids =["${aws_security_group.database.id}"]
  #engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "csye6225"
  #depends_on           =[aws_instance.TerraformInstance]
  skip_final_snapshot  ="true"
  publicly_accessible  = "true"
  username             = "dbuser"
  identifier           ="csye6225-fall2019"
  password             = "foobarbaz"
  
}
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "MIHIR_chi_bucket" {
  
  bucket = "${var.ImageS3Bucket}"
  force_destroy = true
  acl    = "private"
 
  lifecycle_rule {
    id      = "archive"
    enabled = true
    prefix = "archive/"
   

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.mykey.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
   cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["DELETE", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
resource "aws_s3_bucket" "CodeD" {
  
  bucket = "${var.CodedeployS3Bucket}"
  force_destroy = true
  acl    = "private"
 
  lifecycle_rule {
    id      = "archive"
    enabled = true
    prefix = "archive/"
   

    expiration {
      days = 60
    }
  }  
  
   cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["DELETE", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
//Lambda S3 bucket
resource "aws_s3_bucket" "labmda"{
  bucket = "${var.LambdaBucket}"
  force_destroy = true
  acl ="private"
  lifecycle_rule{
    id      = "archive"
    enabled = true
    prefix = "archive/"
   

    expiration {
      days = 60
    }
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["DELETE", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
//Lambda S3 ends
resource "aws_dynamodb_table" "csye6225" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
resource "aws_codedeploy_app" "example" {
  # compute_platform = "EC2/On-premises"
  name             = "csye6225-webapp"
}
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = "${aws_codedeploy_app.example.name}"
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn     = "arn:aws:iam::${var.Account_id}:role/CodeDeployServiceRole"
  deployment_config_name="CodeDeployDefault.AllAtOnce"
  autoscaling_groups    =["AutoScalingGroup"]

  # ec2_tag_set {
  #   ec2_tag_filter {
  #     key   = "Name"
  #     type  = "KEY_AND_VALUE"
  #     value = "Terraform_instance"
  #   }

  # }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}

//Lamdba start



resource "aws_lambda_function" "create_Lambda" {
  filename      = "./index.zip"
  function_name = "EmailServices"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "index.emailService"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #source_code_hash = "${filebase64sha256("lambda_function_payload.zip")}"

  runtime = "nodejs8.10"

  environment {
    variables = {
      DomainName = "dev.meetveera.me"
    }
  }
}
resource "aws_lambda_permission" "allow_sns" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.create_Lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.SNS.arn}"
  depends_on = [aws_sns_topic.SNS]
}


resource "aws_sns_topic" "SNS" {
  name = "EmailTopic"
  depends_on = [aws_lambda_function.create_Lambda]
}
resource "aws_sns_topic_subscription" "example" {
  #depends_on = ["aws_lambda_function.example"]
  topic_arn = "${aws_sns_topic.SNS.arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.create_Lambda.arn}"
}
