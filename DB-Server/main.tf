
# Creating DB instance

resource "aws_db_instance" "sample-db" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "sample-DB"
  username             = "KCK"
  password             = random_string.password.result
  port                 = 3306
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  /*
  if you need to add existing VPC security group to the DB,
  use Vars option and provide the details in variables file
  */
  vpc_security_group_ids = var.vpc_security_group_ids["K8 group"]

  #auto scaling max storage limit
  max_allocated_storage = 25
  allocated_storage     = 5
  deletion_protection   = true

  #maintenance and backup
  maintenance_window    = "Sun:09:00-Sun:09:30"
  backup_window         = "08:00-08:30"
  backup_retention_period = 30

  timeouts {
  create = "40m"
  delete = "60m"
  update = "80m"
}
}

# Auto generating DB instance password
resource "random_string" "password" {
  length  = 10
  special = false
} 

# Creating new DB VPC 

resource "aws_vpc" "sample-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "db-vpc"
  }
}

# Creating subnets for newly created VPC

resource "aws_subnet" "sample-subnet1" {
  vpc_id     = aws_vpc.sample-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "db-subnet2"
  }
}

resource "aws_subnet" "sample-subnet2" {
  vpc_id     = aws_vpc.sample-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "db-subnet2"
  }
}

# Creating db subnets group

resource "aws_db_subnet_group" "sample-db-subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.sample-subnet1.id, aws_subnet.sample-subnet2.id]
  tags = {
    Name = "DB-subnet-group"
  }
}

# Creating new SNS topic

resource "aws_sns_topic" "notify" {
  name = "db-events"
  display_name = "Notifications"
}

# Creating new SQS
resource "aws_sqs_queue" "queue" {
  name = "db-queue"
}

# Creating a db event subscription

resource "aws_db_event_subscription" "db-info" {
  name      = "db-events"
  source_ids = ["${aws_db_instance.sample-db.id}"]
  sns_topic = aws_sns_topic.notify.arn
  event_categories = [
    "low storage",
  ]
}

# Creating an alarm

resource "aws_cloudwatch_metric_alarm" "db-alarm" {
    alarm_name = "DB Alert"
    alarm_description = "Alarm for space"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = 3
    period = 300
    threshold = 3000
    statistic = "Average"
    datapoints_to_alarm = 3
    treat_missing_data = "missing"
    namespace = "AWS/RDS"
    metric_name = "FreeLocalStorage"
    dimensions = {DBInstanceIdentifier = aws_db_instance.sample-db.id}
    alarm_actions = [aws_sns_topic.notify.arn]
}

# creating a sns topic subscription

resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}