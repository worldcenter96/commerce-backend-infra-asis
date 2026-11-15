# security 모듈
# - 책임: SG 7개, 인바운드 규칙(VPC 안은 SG 참조), 아웃바운드 전체 허용 (05 2절 모듈 표 security 행)
# - 근거: security.md v1.4 1절(1.1 목록, 1.2 규칙)·3절(P-01, P-02, P-05, 예외 목록), ADR-005, ADR-011,
#         DR-02, DR-19, DR-22, DR-23
# - 규칙 방식: SG와 규칙을 별도 리소스로 쓴다(aws_vpc_security_group_ingress_rule / egress_rule).
#   결정자 지정(2026-11-15, 3단계 구현 질문). security.md 1.2절 규칙에는 SG 사이 순환 참조가 없다
#   (nlb·bastion → alb → app → log·rds·redis 한 방향). 생기더라도 SG를 먼저 만들고 규칙을 뒤에 붙이므로 풀린다.
# - 설명(description): SG와 규칙 모두 영문(AWS가 한글을 받지 않음). 결정자 지정(2026-11-15)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). 예: commerce-prod-sg-app
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 SG에 Name만 붙인다.
# - 만들지 않는 것: IPv6 규칙(network.md 1.1절 IPv6 없음, security.md 1.2절 `::/0` 쓰지 않음), 응답용 규칙(stateful, 1.2절)

locals {
  # -------------------------------------------------------------------------
  # SG 7개 (security.md 1.1절). 키는 04의 짧은 이름이고 이름 규칙의 {resource}-{role} 자리에 들어간다.
  # 값은 SG description(영문, 1.1절 "붙는 곳"·"서브넷"). 바꾸면 SG가 다시 만들어지므로 고치지 않는다(AWS 사양).
  # -------------------------------------------------------------------------
  security_groups = {
    "sg-nlb"     = "NLB (public-nlb-a)"                          # ADR-010, ADR-011, N-03
    "sg-alb"     = "Internal ALB (private-alb-a, private-alb-b)" # ADR-003, ADR-010, ADR-011
    "sg-app"     = "App servers admin/b2b/b2c (private-app-a)"   # ADR-001, ADR-011. 3대가 같은 SG를 쓴다(1.1절)
    "sg-log"     = "Log server Loki and Grafana (private-app-a)" # ADR-006, N-05
    "sg-bastion" = "Bastion (public-a)"                          # ADR-005
    "sg-rds"     = "RDS MySQL (private-db-a, private-db-b)"      # ADR-008, ADR-011
    "sg-redis"   = "ElastiCache Redis (private-cache-a)"         # ADR-008, ADR-011
  }

  # -------------------------------------------------------------------------
  # 인바운드 규칙 12개 (security.md 1.2절 표 그대로. 표는 10행이고 sg-rds·sg-redis는 출발지가 2개라 규칙도 2개씩)
  # - source_sg: VPC 안 출발지. SG 참조로만 쓴다(P-05, DR-19)
  # - cidr:      VPC 밖 출발지만. sg-nlb 443(0.0.0.0/0)과 sg-bastion 22(운영자 /32) 두 개뿐이다(P-01, P-02, AI-06)
  # -------------------------------------------------------------------------
  ingress_rules = {
    # sg-nlb 443 ← 0.0.0.0/0: 3절 예외 목록의 유일한 항목(P-02, S-03, DR-02, DR-23). NFR-06, FR-02, FR-03, ADR-010
    "sg-nlb-443-internet" = {
      sg          = "sg-nlb"
      port        = 443
      source_sg   = null
      cidr        = "0.0.0.0/0"
      description = "HTTPS from internet (security.md P-02 exception, DR-02)"
    }

    # sg-alb 443 ← sg-nlb: ADR-003("NLB에서 오는 트래픽만"), ADR-011
    "sg-alb-443-nlb" = {
      sg          = "sg-alb"
      port        = 443
      source_sg   = "sg-nlb"
      cidr        = null
      description = "HTTPS from sg-nlb (ADR-003, ADR-011)"
    }

    # sg-app 8080 ← sg-alb: ADR-011("ALB 보안 그룹에서 오는 앱 포트만"). 8080은 Spring Boot 기본값(CON-06)
    "sg-app-8080-alb" = {
      sg          = "sg-app"
      port        = 8080
      source_sg   = "sg-alb"
      cidr        = null
      description = "App port 8080 from sg-alb (ADR-011)"
    }

    # sg-app 22 ← sg-bastion: FR-07, ADR-005, S-01, P-01
    "sg-app-22-bastion" = {
      sg          = "sg-app"
      port        = 22
      source_sg   = "sg-bastion"
      cidr        = null
      description = "SSH from sg-bastion (S-01, ADR-005)"
    }

    # sg-log 3100 ← sg-app: FR-09, ADR-006, S-02. 3100은 Loki 기본값
    "sg-log-3100-app" = {
      sg          = "sg-log"
      port        = 3100
      source_sg   = "sg-app"
      cidr        = null
      description = "Loki 3100 from sg-app (S-02, ADR-006)"
    }

    # sg-log 3000 ← sg-bastion: ADR-006(Bastion을 거친 SSH 터널), S-02. 3000은 Grafana 기본값
    "sg-log-3000-bastion" = {
      sg          = "sg-log"
      port        = 3000
      source_sg   = "sg-bastion"
      cidr        = null
      description = "Grafana 3000 from sg-bastion (S-02, ADR-006)"
    }

    # sg-log 22 ← sg-bastion: FR-07, ADR-005, S-01, P-01
    "sg-log-22-bastion" = {
      sg          = "sg-log"
      port        = 22
      source_sg   = "sg-bastion"
      cidr        = null
      description = "SSH from sg-bastion (S-01, ADR-005)"
    }

    # sg-bastion 22 ← 운영자 IP(/32): ADR-005, S-04, DR-22, P-01. VPC 밖 출발지라 CIDR로 쓴다
    "sg-bastion-22-operator" = {
      sg          = "sg-bastion"
      port        = 22
      source_sg   = null
      cidr        = var.operator_ip_cidr
      description = "SSH from operator IP (S-04, DR-22)"
    }

    # sg-rds 3306 ← sg-app, sg-bastion: ADR-011("앱 서버 3대와 Bastion에서 오는 MySQL 포트만"). FR-04
    "sg-rds-3306-app" = {
      sg          = "sg-rds"
      port        = 3306
      source_sg   = "sg-app"
      cidr        = null
      description = "MySQL from sg-app (ADR-011)"
    }
    "sg-rds-3306-bastion" = {
      sg          = "sg-rds"
      port        = 3306
      source_sg   = "sg-bastion"
      cidr        = null
      description = "MySQL from sg-bastion (ADR-011)"
    }

    # sg-redis 6379 ← sg-app, sg-bastion: ADR-011. FR-04
    # Redis 인증 토큰을 쓰지 않으므로 Redis 접근 제한은 이 두 규칙뿐이다(S-10 변경, ADR-013)
    "sg-redis-6379-app" = {
      sg          = "sg-redis"
      port        = 6379
      source_sg   = "sg-app"
      cidr        = null
      description = "Redis from sg-app (ADR-011, S-10)"
    }
    "sg-redis-6379-bastion" = {
      sg          = "sg-redis"
      port        = 6379
      source_sg   = "sg-bastion"
      cidr        = null
      description = "Redis from sg-bastion (ADR-011, S-10)"
    }
  }

  # VPC 밖 CIDR을 쓸 수 있는 규칙 (P-01, P-02, AI-06). 아래 precondition에서 확인한다
  allowed_cidr_rules = {
    "sg-nlb-443-internet"    = "0.0.0.0/0"
    "sg-bastion-22-operator" = var.operator_ip_cidr
  }
}

# ---------------------------------------------------------------------------
# 보안 그룹 7개 (security.md 1.1절)
# - aws_security_group은 인라인 규칙 없이 만들면 AWS 기본 아웃바운드(전체 허용)를 지운다(Terraform 프로바이더 동작).
#   그래서 아웃바운드 전체 허용은 아래 egress 리소스로 명시한다(S-05)
# ---------------------------------------------------------------------------

resource "aws_security_group" "this" {
  for_each = local.security_groups

  name        = "${var.name_prefix}-${each.key}" # 05 2절 예: commerce-prod-sg-app
  description = each.value                       # 결정자 지정(2026-11-15). 바꾸면 SG가 다시 만들어진다
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-${each.key}"
  }
}

# ---------------------------------------------------------------------------
# 인바운드 규칙 12개 (security.md 1.2절)
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.this[each.value.sg].id
  description       = each.value.description
  ip_protocol       = "tcp" # 1.2절 인바운드는 모두 TCP
  from_port         = each.value.port
  to_port           = each.value.port

  # VPC 안은 SG 참조(P-05), VPC 밖만 CIDR(P-01, P-02)
  referenced_security_group_id = each.value.source_sg == null ? null : aws_security_group.this[each.value.source_sg].id
  cidr_ipv4                    = each.value.cidr

  lifecycle {
    precondition {
      # 출발지는 SG 참조와 CIDR 중 정확히 하나
      condition     = (each.value.source_sg == null) != (each.value.cidr == null)
      error_message = "인바운드 규칙 ${each.key}: source_sg와 cidr 중 하나만 지정해야 합니다(security.md 1.2절)."
    }
    precondition {
      # CIDR 규칙은 sg-nlb 443 ← 0.0.0.0/0, sg-bastion 22 ← 운영자 /32 두 개뿐(P-01, P-02, P-05, 05 AI-06)
      condition     = each.value.cidr == null || lookup(local.allowed_cidr_rules, each.key, "") == each.value.cidr
      error_message = "인바운드 규칙 ${each.key}: CIDR 출발지는 security.md 3절 예외 목록(sg-nlb 443)과 sg-bastion 22(운영자 /32)에만 쓸 수 있습니다(P-01, P-02, P-05)."
    }
  }
}

# ---------------------------------------------------------------------------
# 아웃바운드: 모든 SG 전체 허용 (security.md 1.2절, S-05, 결정자 지정 2026-11-12. AWS 기본값과 같음)
# - IPv4만. VPC에 IPv6가 없다(network.md 1.1절)
# - 아웃바운드의 0.0.0.0/0은 3절 예외 목록 대상이 아니다(3절)
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = aws_security_group.this

  security_group_id = each.value.id
  description       = "All outbound (security.md S-05)"
  ip_protocol       = "-1" # 전체 프로토콜·포트. -1이면 from_port·to_port를 쓰지 않는다(프로바이더 사양)
  cidr_ipv4         = "0.0.0.0/0"
}
