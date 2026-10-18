@echo off
setlocal
terraform init
terraform validate
terraform apply -auto-approve
