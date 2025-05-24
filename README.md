# Get Table Item
 aws dynamodb get-item \
  --table-name ce10-laoniu-table \
  --region ap-southeast-1 \
  --key '{"ISBN": {"S": "974-0134789698"}, "Genre": {"S": "Fiction"}}'

## Result - Get Table Item:
![VPC Diagram](./docs/images/Result1-get_table_item.png)

# List the available Dynamo Tables
aws dynamodb list-tables

## Result - List the available Dynamo Tables:
![VPC Diagram](./docs/images/Result2-list%20table.png)

# Reads all items in the table
aws dynamodb scan --table-name ce10-laoniu-table

## Result - Reads all tables
![VPC Diagram](./docs/images/Result3-reads_all_tables.png)

## Challenge to test on the output the resource that I was created
![VPC Diagram](./docs/images/Result4-output%20resources.png)

# Delete DynamoDB Table
aws dynamodb delete-table --table-name ce10-laoniu-table

## Result - Delete DynamoDB Table
![VPC Diagram](./docs/images/Result5-delete_table.png)