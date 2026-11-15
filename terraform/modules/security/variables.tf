# security 모듈 입력
# - 근거: 05 2절 모듈 표 security 행의 "입력" 열(VPC ID, 운영자 IP(/32))
# - name_prefix는 이름 규칙 때문에 network 모듈과 같은 방식으로 받는다(05 2절)
# - SG 목록과 규칙은 security.md 1절에 값이 정해져 있어 변수가 아니라 main.tf locals에 둔다(terraform/README.md 2절)

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "vpc_id" {
  description = "SG를 만들 VPC ID. network 모듈 출력"
  type        = string
}

variable "operator_ip_cidr" {
  description = "Bastion SSH 22를 허용할 운영자 공인 IP(/32). sg-bastion 인바운드에만 쓴다"
  type        = string

  validation {
    # security.md P-01, 05 AI-06: 22번은 /32 운영자 IP 말고 열지 않는다
    condition     = can(cidrhost(var.operator_ip_cidr, 0)) && endswith(var.operator_ip_cidr, "/32")
    error_message = "operator_ip_cidr는 /32 CIDR이어야 합니다(security.md P-01)."
  }
}
