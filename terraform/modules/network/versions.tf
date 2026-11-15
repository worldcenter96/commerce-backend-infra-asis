# network 모듈 버전 제약
# - 근거: 루트 versions.tf와 같은 값(결정자 지정 2026-11-14). 05 2절

terraform {
  required_version = "1.17.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}
