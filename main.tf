provider "aws" {
  region = "us-east-1"  # N. Virginia region
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id  # Use the default Amazon Linux 2 AMI
  instance_type = "t2.micro"      # Instance type is t2.micro

  # User data script to install Docker and run a container
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker
    sudo service docker start
    sudo systemctl enable docker
    # Pull and run the Docker container on port 8080
    sudo docker run -d -p 8080:8080 task-caller:latest
  EOF

  tags = {
    Name = "Terraform-EC2-Docker"
  }

  # Security group to allow HTTP traffic
  vpc_security_group_ids = [aws_security_group.docker_sg.id]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]  # Official AMIs owned by Amazon

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Amazon Linux 2 AMI
  }
}

resource "aws_security_group" "docker_sg" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

