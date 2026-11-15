# deploy 모듈 출력
# - 근거: 05 2절 모듈 표 deploy 행의 "출력" 열(버킷 이름, 애플리케이션 이름). 배포 그룹은 Terraform 밖이라 출력이 없다

output "artifact_bucket_name" {
  description = "S3 아티팩트 버킷 이름. GitHub Actions 업로드 대상(10단계), security.md 5절 검증의 <버킷>"
  value       = aws_s3_bucket.artifacts.bucket
}

output "codedeploy_app_name" {
  description = "CodeDeploy 애플리케이션 이름. 배포 그룹 3개를 이 아래에 수동으로 만든다(README 3절 10-1번)"
  value       = aws_codedeploy_app.backend.name
}
