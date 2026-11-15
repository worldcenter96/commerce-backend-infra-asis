# Terraform·AWS 프로바이더 버전 고정
# - 근거: 05 2절(versions.tf), CON-11(Terraform, Local State)
# - 버전: 결정자 지정(2026-11-14). 처음에는 부 버전 범위(~> 1.17, ~> 6.73)였으나
#   결정자 지시로 정확한 버전으로 고정한다. .terraform.lock.hcl도 같은 버전이다.

terraform {
  required_version = "1.17.2" # 정확한 버전. 결정자 지정(2026-11-14)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0" # 정확한 버전. 결정자 지정(2026-11-14)
    }
  }

  # backend 블록 없음: Local State를 쓴다(CON-11, Q-31).
  # State 파일은 운영자 PC에만 두고 Git에 넣지 않는다(05 AI-05, .gitignore).
}
