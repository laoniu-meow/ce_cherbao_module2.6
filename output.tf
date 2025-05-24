# ce_cherbao_module2.6/output.tf

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = var.public_subnet_cidr
}

# Output my DynamoDB
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.book_inventory.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.book_inventory.arn
}

output "dynamodb_table_stream_arn" {
  description = "Stream ARN (if enabled)"
  value       = aws_dynamodb_table.book_inventory.stream_arn
}

# Output the role and policies
output "iam_role_name" {
  description = "IAM Role for EC2"
  value       = aws_iam_role.dynamodb_read_role.name
}

output "iam_policy_name" {
  description = "IAM Policy for DynamoDB Read"
  value       = aws_iam_policy.dynamodb_read.name
}

output "iam_instance_profile" {
  description = "IAM Instance Profile"
  value       = aws_iam_instance_profile.dynamodb_read_profile.name
}

output "iam_policy_document" {
  description = "IAM policy JSON"
  value       = aws_iam_policy.dynamodb_read.policy
}
