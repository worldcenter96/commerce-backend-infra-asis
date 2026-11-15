# AWS 프로바이더
# - 근거: 05 2절(providers.tf)
# - 자격 증명은 코드에 쓰지 않는다(05 AI-04, security.md P-08).
#   운영자가 루트 계정으로 `aws login`한 뒤 실행한다(NFR-07·CON-13, 01 v1.5, 결정자 지정 2026-11-15).
#   루트 액세스 키는 만들지 않는다(security.md P-07). GitHub Actions는 별도 IAM 사용자 키를 쓴다(README 참고).

provider "aws" {
  region = "ap-northeast-2" # 서울. CON-04로 고정이라 변수로 두지 않는다. network.md 1절

  # 공통 태그: 결정자 지정(2026-11-14, 1단계 구현 질문). Project 값은 이름 규칙의 project(commerce)에 맞춤(05 2절)
  # Terraform 밖에서 만든 리소스(IAM, 서비스 A 레코드 등)와 구분하는 데 쓴다.
  # CodeDeploy 배포 그룹(Terraform 밖)이 서비스를 고르는 Service 태그는 5단계 compute 모듈에서 붙인다(compute.md 2절).
  default_tags {
    tags = {
      Project     = "commerce"
      Environment = "prod" # CON-05: prod 환경 1개
      ManagedBy   = "terraform"
    }
  }
}
