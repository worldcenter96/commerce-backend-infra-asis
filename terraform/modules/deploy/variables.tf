# deploy 모듈 입력
# - 근거: 05 2절 모듈 표 deploy 행의 "입력" 열("없음")
# - 버킷 이름·애플리케이션 이름·플랫폼은 문서에 정해진 값이라 변수가 아니라 main.tf locals에 둔다(terraform/README.md 2절).
#   name_prefix만 다른 모듈과 같은 방식으로 루트에서 받는다(이름 규칙 05 2절).

variable "name_prefix" {
  description = "이름 규칙의 {project}-{environment} 부분. 예: commerce-prod"
  type        = string
}
