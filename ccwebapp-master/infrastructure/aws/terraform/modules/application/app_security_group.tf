variable "Vpc_Name"{
    type=string
    default="VPC"
}
variable "cidr_block"{
    type=string
    default="10.0.2.0/16"
}
variable "Vpc_Region"{
    type=string
    default="us-east-1"
}
variable "Vpc_id"{
    type=string
    default="us-east-1"
}


resource "aws_security_group" "application" {
  name        = "application"
  description = "Allow TLS inbound traffic"
  vpc_id=var.Vpc_id
  tags={
         Name= "application"
  }
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
    #security_groups=["${aws_security_group.lb_security.id}"]
  } 

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    #cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
    security_groups=["${aws_security_group.lb_security.id}"]
   
  } 
  # ingress {
  #   # TLS (change to whatever ports you need)
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   # Please restrict your ingress to only necessary IPs and ports.
  #   # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
  #   cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
   
  # } 
  
  
   egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    
  }

}
