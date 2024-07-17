# terraform {
#   backend "s3" {
#     bucket         = "stackbuckstateisaac-aut"
#     key            = "terraform_clixx_k8s.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "statelock-tf"
#   }
# }