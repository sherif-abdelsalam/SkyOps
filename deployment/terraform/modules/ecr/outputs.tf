
output "ecr_repos" {
  value = {
    for k, v in aws_ecr_repository.services : k => v.repository_url
  }
}