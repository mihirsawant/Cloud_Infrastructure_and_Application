
variable "APP"{
    type=string
    default="us-east-1"
}
resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow TLS inbound traffic"
  vpc_id=var.Vpc_id
  
  tags={
         Name= "database"
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
     security_groups =["${aws_security_group.application.id}"]
  }
  
}



