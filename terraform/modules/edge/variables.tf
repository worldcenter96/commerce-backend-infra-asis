# edge 모듈 입력
# - 근거: 05 2절 모듈 표 edge 행의 "입력" 열(서브넷 ID, SG ID, 인증서 ARN, 앱 인스턴스 ID)
# - 이름·포트·TLS 정책·상태 확인 값·호스트 이름 등 문서에 정해진 값은 변수가 아니라
#   main.tf의 locals에 둔다(terraform/README.md 2절, network.md 4.4·5.3절, security.md 2.1절)
# - VPC ID는 입력으로 받지 않고 서브넷에서 읽는다(05 2절 입력 열을 바꾸지 않기 위해. main.tf data "aws_subnet")

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "subnet_ids" {
  description = "서브넷 ID 맵(network 모듈 출력). 키는 04의 짧은 이름. public-nlb-a, private-alb-a, private-alb-b를 쓴다"
  type        = map(string)

  validation {
    # network.md 2절·4.4절(NLB public-nlb-a, ALB private-alb-a·b), ADR-010, DR-12
    condition     = alltrue([for k in ["public-nlb-a", "private-alb-a", "private-alb-b"] : contains(keys(var.subnet_ids), k)])
    error_message = "subnet_ids에 public-nlb-a, private-alb-a, private-alb-b가 있어야 합니다(network.md 2·4.4절)."
  }
}

variable "security_group_ids" {
  description = "SG ID 맵(security 모듈 출력). 키는 04의 짧은 이름. sg-nlb, sg-alb를 쓴다"
  type        = map(string)

  validation {
    # security.md 1.1절(sg-nlb는 NLB, sg-alb는 ALB)
    condition     = alltrue([for k in ["sg-nlb", "sg-alb"] : contains(keys(var.security_group_ids), k)])
    error_message = "security_group_ids에 sg-nlb, sg-alb가 있어야 합니다(security.md 1.1절)."
  }
}

variable "certificate_arn" {
  description = "ACM *.imcommerce.shop 인증서 ARN(dns_cert 모듈 출력). ALB 443 리스너에 붙인다(ADR-003, security.md 2.1절). apply 전에 ISSUED여야 한다(05 R-20)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:ap-northeast-2:[0-9]{12}:certificate/", var.certificate_arn))
    error_message = "certificate_arn은 서울 리전(ap-northeast-2) ACM 인증서 ARN이어야 합니다(ALB와 같은 리전, CON-04)."
  }
}

variable "instance_ids" {
  description = "인스턴스 ID 맵(compute 모듈 출력). app-admin, app-b2b, app-b2c를 ALB 대상 그룹에 등록한다"
  type        = map(string)

  validation {
    # compute.md 1절(앱 서버 3대), FR-03(서비스별 라우팅)
    condition     = alltrue([for k in ["app-admin", "app-b2b", "app-b2c"] : contains(keys(var.instance_ids), k)])
    error_message = "instance_ids에 app-admin, app-b2b, app-b2c가 있어야 합니다(compute.md 1절)."
  }
}
