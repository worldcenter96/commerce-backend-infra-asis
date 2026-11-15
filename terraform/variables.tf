# 루트 입력 변수
# - 근거: 05 2절(variables.tf, 모듈 표의 "입력" 열)
# - 범위: 결정자 지정(2026-11-14, 1단계 구현 질문). 코드 밖에서 받아야 하는 값만 변수로 둔다.
#   문서에 값이 정해진 항목(VPC CIDR, 서브넷 표, 도메인, 키 페어 이름)은 변수가 아니라 해당 단계에서 locals로 둔다.
# - 비밀값 변수는 없다(결정자 지정 2026-11-15, ADR-013, 05 5.1절).
#   RDS 마스터 비밀번호는 RDS 관리형 비밀번호(Secrets Manager), Redis 인증 토큰은 쓰지 않는다.
#   비밀값 변수를 새로 만들어야 하면 sensitive로 받고 기본값을 두지 않는다(05 AI-04).

# ---------------------------------------------------------------------------
# 운영자 접근 (3단계 security)
# ---------------------------------------------------------------------------

variable "operator_ip_cidr" {
  description = "Bastion SSH 22를 허용할 운영자 공인 IP(/32). sg-bastion 인바운드에만 쓴다"
  type        = string
  # 기본값 없음. 실제 값은 terraform.tfvars에 넣는다(Git 제외, 05 AI-05).
  # 값은 security.md 1.2절·S-04(결정자 지정 2026-11-12), ADR-005, DR-22. 공개 저장소에 IP를 남기지 않으려고 기본값을 뺐다(결정자 지정 2026-11-16)

  validation {
    # security.md P-01, 05 AI-06: 22번은 /32 운영자 IP 말고 열지 않는다
    condition     = can(cidrhost(var.operator_ip_cidr, 0)) && endswith(var.operator_ip_cidr, "/32")
    error_message = "operator_ip_cidr는 /32 CIDR이어야 합니다(security.md P-01)."
  }
}

# 지운 변수 (결정자 지정 2026-11-15, ai-log)
# - ssh_public_key: AWS에 이미 있는 키 페어 3개를 이름으로 지정한다(compute.md 2절). 5단계 compute에서 locals로 둔다.
# - rds_temp_master_password: RDS 관리형 비밀번호를 쓴다(ADR-013, data.md 2절).
# - redis_temp_auth_token: Redis 인증 토큰을 쓰지 않는다(ADR-013, security.md S-10).
