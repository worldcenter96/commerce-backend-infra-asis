# data 모듈 입력
# - 근거: 05 2절 모듈 표 data 행의 "입력" 열(서브넷 ID, SG ID). 비밀값 입력 없음(ADR-013, 05 5.1절)
# - 엔진 버전·인스턴스 클래스·스토리지·사용자 이름·스키마 이름 등 문서에 정해진 값은 변수가 아니라
#   main.tf의 locals에 둔다(terraform/README.md 2절, data.md 2·3절)

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "subnet_ids" {
  description = "서브넷 ID 맵(network 모듈 출력). 키는 04의 짧은 이름. private-db-a, private-db-b, private-cache-a를 쓴다"
  type        = map(string)

  validation {
    # data.md 2절(RDS 서브넷 그룹 private-db-a·private-db-b), 3절(Redis private-cache-a 하나), network.md 2절, ADR-014
    condition     = alltrue([for k in ["private-db-a", "private-db-b", "private-cache-a"] : contains(keys(var.subnet_ids), k)])
    error_message = "subnet_ids에 private-db-a, private-db-b, private-cache-a가 있어야 합니다(data.md 2·3절, network.md 2절)."
  }
}

variable "security_group_ids" {
  description = "SG ID 맵(security 모듈 출력). 키는 04의 짧은 이름. sg-rds, sg-redis를 쓴다"
  type        = map(string)

  validation {
    # data.md 2·3절 보안 그룹 행, security.md 1.1절
    condition     = alltrue([for k in ["sg-rds", "sg-redis"] : contains(keys(var.security_group_ids), k)])
    error_message = "security_group_ids에 sg-rds, sg-redis가 있어야 합니다(security.md 1.1절)."
  }
}
