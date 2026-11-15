# network 모듈 입력
# - 근거: 05 2절 모듈 표 network 행의 "입력" 열(VPC CIDR, 서브넷 표)
# - 값은 루트 main.tf의 locals에서 넘긴다. 문서에 정해진 값이라 루트 변수로 두지 않는다(terraform/README.md 2절).

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr는 올바른 IPv4 CIDR이어야 합니다."
  }
}

variable "subnets" {
  description = "서브넷 표. 키는 04의 짧은 이름(예: public-a). tier는 public 또는 private"
  type = map(object({
    az   = string
    cidr = string
    tier = string
  }))

  validation {
    condition     = alltrue([for s in values(var.subnets) : contains(["public", "private"], s.tier)])
    error_message = "subnets의 tier는 public 또는 private여야 합니다."
  }
}

variable "nat_subnet_key" {
  description = "NAT Gateway를 둘 퍼블릭 서브넷의 키"
  type        = string

  validation {
    condition     = contains(keys(var.subnets), var.nat_subnet_key) && var.subnets[var.nat_subnet_key].tier == "public"
    error_message = "nat_subnet_key는 subnets에 있는 퍼블릭 서브넷이어야 합니다(AWS 요구사항, network.md 4.2절)."
  }
}
