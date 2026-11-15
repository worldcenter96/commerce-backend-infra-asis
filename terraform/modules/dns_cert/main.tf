# dns_cert 모듈
# - 책임: Route 53 퍼블릭 호스팅 영역, ACM 와일드카드 인증서 요청(DNS 검증 방식) (05 2절 모듈 표 dns_cert 행)
# - 근거: network.md v1.6 4.5절, security.md 2.1절, ADR-003, DR-17, S-06
# - 만들지 않는 것(결정자 지정 2026-11-14, network.md 4.5절, 05 1.1절):
#   - aws_route53_record: 서비스 A 레코드 3개(7단계 뒤 수동), ACM 검증 CNAME(4단계 수동). 05 R-19, R-20
#   - aws_acm_certificate_validation: 검증 CNAME을 수동으로 넣으므로 apply는 ISSUED를 기다리지 않는다
#   - 도메인 등록(Route 53 Domains)과 네임서버 변경, 등록 때 자동 생성되는 호스팅 영역 삭제: Terraform 밖(Q-37, 05 1.1절)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). role은 결정자 지정(2026-11-15, 4단계 구현 질문)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name만 붙인다.

# ---------------------------------------------------------------------------
# Route 53 퍼블릭 호스팅 영역 (network.md 4.5절, DR-17, CON-10)
# - 테스트 기간 중 다시 만들지 않는다. 다시 만들면 네임서버 4개가 바뀌어 Route 53 Domains의
#   네임서버 변경을 다시 해야 한다(network.md 4.5절, 05 R-07)
# ---------------------------------------------------------------------------

resource "aws_route53_zone" "public" {
  name = var.domain_name # imcommerce.shop (00 3.4, CON-10). vpc 블록이 없으므로 퍼블릭 영역

  # 기본값을 명시. 수동 레코드(서비스 A 3개, 검증 CNAME)가 남아 있으면 destroy가 실패해 삭제 절차 누락을 알린다.
  # network.md 4.5절 "삭제", 05 R-19, 결정자 지정(2026-11-15)
  force_destroy = false

  tags = {
    Name = "${var.name_prefix}-route53-main" # 결정자 지정(2026-11-15)
  }
}

# ---------------------------------------------------------------------------
# ACM 와일드카드 인증서 (security.md 2.1절, ADR-003, S-06, FR-02)
# - 서울 리전(provider 기본). 7단계 ALB 443 리스너가 쓴다(ADR-003)
# - 검증 CNAME은 루트 output acm_validation_records 값으로 운영자가 위 호스팅 영역에 수동 등록한다(network.md 4.5절)
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "wildcard" {
  domain_name = "*.${var.domain_name}" # *.imcommerce.shop 1개(S-06 (B)). 서비스 도메인 3개를 모두 덮는다
  # subject_alternative_names 없음: 루트 도메인 imcommerce.shop은 넣지 않는다(security.md 2.1절)

  validation_method = "DNS"      # security.md 2.1절, ADR-003. 자동 갱신 조건(FR-02)
  key_algorithm     = "RSA_2048" # ACM 기본값을 명시. 결정자 지정(2026-11-15)

  # lifecycle create_before_destroy는 넣지 않는다(결정자 지정 2026-11-15)

  tags = {
    Name = "${var.name_prefix}-cert-wildcard" # 결정자 지정(2026-11-15)
  }
}
