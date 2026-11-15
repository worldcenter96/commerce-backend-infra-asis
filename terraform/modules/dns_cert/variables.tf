# dns_cert 모듈 입력
# - 근거: 05 2절 모듈 표 dns_cert 행의 "입력" 열(도메인 이름)
# - 값은 루트 main.tf의 locals에서 넘긴다. 문서에 정해진 값이라 루트 변수로 두지 않는다(terraform/README.md 2절).

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}

variable "domain_name" {
  description = "퍼블릭 호스팅 영역 이름(루트 도메인). 인증서는 이 도메인의 와일드카드(*.<domain_name>)로 요청한다"
  type        = string

  validation {
    # 루트 도메인만 받는다. 와일드카드(*.)는 모듈이 붙인다(security.md 2.1절, S-06)
    condition     = can(regex("^[a-z0-9-]+(\\.[a-z0-9-]+)+$", var.domain_name))
    error_message = "domain_name은 소문자 루트 도메인이어야 합니다(예: imcommerce.shop). '*.'나 끝의 '.'를 넣지 않습니다."
  }
}
