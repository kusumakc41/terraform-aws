/* code block to create new ec2 instance,vpc,subnet
extend further to connect to it and install docker and additional tools.

data "aws_ami" "ubuntu" {
most_recent = true
filter {
name = "name"
values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
}
owners = ["011770055987"]
virtualization_type = "hvm"
}

resource "aws_instance" "prometheus-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = var.vpc_security_group_ids["K8 group"]
  tags = {
    Name = "TF_node"
  }
  subnet_id = "${aws_subnet.sample_subnet.id}"
}

resource "aws_vpc" "sample-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "db-vpc"
  }
}

# Creating subnets for newly created VPC

resource "aws_subnet" "sample-subnet" {
  vpc_id     = aws_vpc.sample-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "db-subnet"
  }
}
*/

# Using existing ec2 instance which already has all the required software installed 

data "aws_instance" "instance_id" {
  instance_id = var.ec2_instance
}

resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-0d058fe428540cd89"
  instance_type = "t2.micro"
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("/home/ubuntu/.ssh/ec2.pem")
    host     = aws_instance.prometheus_grafana.public_ip
  }

/*Install docker images of prometheus, grafana and node-exporter.
  Additionally can include commands to install docker if instance doesn't have the required tools
*/
  provisioner "remote-exec" {
    inline = [
      "docker run -d -p 9090:9090 --name=prometheus prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus",
      "sudo docker run -d -p 3000:3000 --name=grafana grafana/grafana",
      "docker run -d -p 9100:9100 -v /:/hostfs --net=host --path.rootfs=/hostfs prom/node-exporter"
    ]
  }
}
