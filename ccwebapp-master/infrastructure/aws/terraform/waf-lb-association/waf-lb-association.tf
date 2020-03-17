variable "lb"{
    type=string
    default="us-east-1"
}
variable "acl"{
    type=string
    default="us-east-1"
}

resource "aws_wafregional_web_acl_association" "foo" {
  resource_arn = var.lb
  web_acl_id   = var.acl
}