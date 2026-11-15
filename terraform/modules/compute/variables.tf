# compute 모듈 입력
# - 근거: 05 2절 모듈 표 compute 행의 "입력" 열(서브넷 ID, SG ID)
# - AMI·키 페어 이름·인스턴스 유형·볼륨 등 문서에 정해진 값은 변수가 아니라 main.tf의 locals에 둔다
#   (terraform/README.md 2절, compute.md 1·2절)

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "subnet_ids" {
  description = "서브넷 ID 맵(network 모듈 출력). 키는 04의 짧은 이름. public-a, private-app-a를 쓴다"
  type        = map(string)

  validation {
    # compute.md 1절: 앱·로그 서버 private-app-a, Bastion public-a (network.md 2절, ADR-014)
    condition     = alltrue([for k in ["public-a", "private-app-a"] : contains(keys(var.subnet_ids), k)])
    error_message = "subnet_ids에 public-a와 private-app-a가 있어야 합니다(compute.md 1절, network.md 2절)."
  }
}

variable "security_group_ids" {
  description = "SG ID 맵(security 모듈 출력). 키는 04의 짧은 이름. sg-app, sg-log, sg-bastion을 쓴다"
  type        = map(string)

  validation {
    # compute.md 2절 보안 그룹 행, security.md 1.1절
    condition     = alltrue([for k in ["sg-app", "sg-log", "sg-bastion"] : contains(keys(var.security_group_ids), k)])
    error_message = "security_group_ids에 sg-app, sg-log, sg-bastion이 있어야 합니다(security.md 1.1절)."
  }
}
