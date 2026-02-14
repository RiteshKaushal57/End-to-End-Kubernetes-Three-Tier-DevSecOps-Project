terraform {
  backend "s3" {
    bucket = "devsecops-terraform-s3-bucket-ritesh"
    key = "dev/eks/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "my-terraform-dynamodb-table"
    encrypt = true
  }
}