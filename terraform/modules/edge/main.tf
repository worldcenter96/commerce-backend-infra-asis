# edge 모듈
# - 책임: ALB(내부용)·대상 그룹 3개·HTTPS 리스너·호스트 규칙·기본 동작 404,
#         NLB(public-nlb-a)·EIP·ALB 대상 그룹·TCP 443 리스너 (05 2절 모듈 표 edge 행)
# - 근거: network.md v1.7 4.4·5.1·5.3절, security.md 2.1절, ADR-003, ADR-010, DR-05, DR-12, DR-26, DR-29, 05 R-03, R-06
# - 경로: 인터넷 → NLB TCP 443(TLS 그대로 전달) → ALB HTTPS 443(TLS 종료) → 앱 서버 HTTP 8080 (network.md 5.1절)
# - 만들지 않는 것:
#   - HTTP 80 리스너·리디렉션: 없다(security.md P-03, 05 AI-07, network.md 5.1절)
#   - 인터넷 연결형 ALB: ALB는 내부용이다(security.md P-06, ADR-010, 05 AI-07)
#   - 서비스 A 레코드 3개(aws_route53_record): Terraform 밖 작업이다. apply 뒤 운영자가 NLB EIP로 수동 생성
#     (network.md 4.5절, 결정자 지정 2026-11-14, README 3절 5번)
#   - 액세스 로그 버킷 등 04에 없는 리소스(05 AI-02), IAM(05 AI-03)
#   - SG·SG 규칙: 3단계 security 모듈에 있다(sg-nlb 443 ← 0.0.0.0/0, sg-alb 443 ← sg-nlb, sg-app 8080 ← sg-alb)
# - apply 조건: ALB HTTPS 리스너는 인증서가 ISSUED여야 만들어진다(05 R-20). 2026-11-15 현재 PENDING_VALIDATION이라
#   코드·plan만 먼저 하고 apply는 README 3절 4·4-b·4-a·4-1 작업과 ISSUED 확인 뒤에 한다(결정자 지정 2026-11-15, ai-log)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). 결정자 지정(2026-11-15, 7단계 구현 질문).
#   ALB·NLB·대상 그룹 이름은 32자 제한(AWS 사양). 가장 긴 이름은 26자(commerce-prod-alb-internal, -tg-app-admin)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name만 붙인다.

locals {
  # -------------------------------------------------------------------------
  # 이름 (결정자 지정 2026-11-15, 7단계)
  # -------------------------------------------------------------------------
  names = {
    alb                = "${var.name_prefix}-alb-internal"       # 26자
    nlb                = "${var.name_prefix}-nlb-public"         # 24자
    eip                = "${var.name_prefix}-eip-nlb"            # Name 태그만
    tg_nlb_alb         = "${var.name_prefix}-tg-nlb-alb"         # 24자
    listener_alb_https = "${var.name_prefix}-listener-alb-https" # Name 태그만
    listener_nlb_tcp   = "${var.name_prefix}-listener-nlb-tcp"   # Name 태그만
  }

  # -------------------------------------------------------------------------
  # 서비스 3개: 호스트 규칙·ALB 대상 그룹·앱 서버 (FR-03, ADR-003, network.md 4.5절 서비스 레코드)
  # -------------------------------------------------------------------------
  services = {
    admin = {
      host      = "admin.imcommerce.shop"           # network.md 4.5절, FR-03
      priority  = 10                                # 결정자 지정(2026-11-15, 7단계)
      instance  = "app-admin"                       # compute 모듈 instance_ids 키
      tg_name   = "${var.name_prefix}-tg-app-admin" # 26자
      rule_name = "${var.name_prefix}-rule-admin"   # Name 태그만
    }
    b2b = {
      host      = "b2b.imcommerce.shop"
      priority  = 20
      instance  = "app-b2b"
      tg_name   = "${var.name_prefix}-tg-app-b2b" # 24자
      rule_name = "${var.name_prefix}-rule-b2b"
    }
    b2c = {
      host      = "b2c.imcommerce.shop"
      priority  = 30
      instance  = "app-b2c"
      tg_name   = "${var.name_prefix}-tg-app-b2c" # 24자
      rule_name = "${var.name_prefix}-rule-b2c"
    }
  }

  # -------------------------------------------------------------------------
  # ALB (network.md 4.4절, security.md 2.1절, ADR-003, ADR-010)
  # -------------------------------------------------------------------------
  alb = {
    subnet_keys                = ["private-alb-a", "private-alb-b"]    # ALB는 AZ 2개 이상(AWS 요구사항), network.md 4.4절
    https_port                 = 443                                   # FR-02, security.md 1.2절
    ssl_policy                 = "ELBSecurityPolicy-TLS13-1-2-2021-06" # security.md 2.1절, DR-29, 05 R-06. 비우면 ELBSecurityPolicy-2016-08(TLS 1.0~1.2)
    idle_timeout               = 60                                    # AWS 기본값. 결정자 지정(2026-11-15, 7단계)
    enable_deletion_protection = false                                 # AWS 기본값. 결정자 지정(2026-11-15, 7단계)
    drop_invalid_header_fields = false                                 # AWS 기본값. 결정자 지정(2026-11-15, 7단계)
  }

  # ALB 대상 그룹(admin / b2b / b2c) 상태 확인 값: network.md 5.3절 표 그대로(DR-26)
  app_target = {
    port                 = 8080       # Spring Boot 기본값(CON-06), ADR-011. ALB → 앱 서버는 HTTP(security.md 2.1절)
    protocol             = "HTTP"     # ADR-011
    health_check_path    = "/healthz" # FR-13
    health_check_matcher = "200"      # FR-13
    interval             = 30         # AWS 기본값
    timeout              = 5          # AWS 기본값
    healthy_threshold    = 5          # AWS 기본값
    unhealthy_threshold  = 2          # AWS 기본값
    deregistration_delay = 300        # AWS 기본값
  }

  # -------------------------------------------------------------------------
  # NLB (network.md 4.4절, ADR-010, N-03)
  # -------------------------------------------------------------------------
  nlb = {
    subnet_key                       = "public-nlb-a" # N-03, DR-12. AZ 하나(AZ-A)
    listener_port                    = 443            # TCP 443. TLS를 종료하지 않는다(security.md 2.1절, ADR-010)
    enable_cross_zone_load_balancing = false          # 끔(명시). 결정자 지정(2026-11-14), network.md 4.4절, 05 R-03
    enable_deletion_protection       = false          # AWS 기본값. 결정자 지정(2026-11-15, 7단계)
  }

  # NLB → ALB 대상 그룹 상태 확인 값: network.md v1.7 5.3절 표 그대로(DR-05, 결정자 지정 2026-11-15)
  # 대상 종류 alb는 상태 확인이 HTTP/HTTPS만 된다(AWS 사양). Host 헤더가 NLB 노드 IP라 ALB 기본 동작 404가 응답한다
  nlb_target = {
    port                 = 443   # ALB 리스너 포트와 같아야 한다(AWS 사양)
    health_check_path    = "/"   # DR-05
    health_check_matcher = "404" # DR-05. NLB 성공 코드 범위 200~599(AWS 사양)
    interval             = 30    # AWS 기본값
    timeout              = 10    # AWS 기본값(NLB HTTPS)
    healthy_threshold    = 5     # AWS 기본값
    unhealthy_threshold  = 2     # AWS 기본값
  }
}

# 대상 그룹의 VPC. 05 2절 입력 열(서브넷 ID)에서 읽는다
data "aws_subnet" "alb_a" {
  id = var.subnet_ids["private-alb-a"]
}

# ---------------------------------------------------------------------------
# ALB (내부용) — ADR-003, ADR-010, network.md 4.4절, security.md P-04·P-06
# ---------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = local.names.alb
  load_balancer_type = "application"
  internal           = true   # 내부용(ADR-010, security.md P-06, 05 AI-07)
  ip_address_type    = "ipv4" # IPv6 쓰지 않음(network.md 1.1절)

  subnets         = [for k in local.alb.subnet_keys : var.subnet_ids[k]] # private-alb-a, private-alb-b
  security_groups = [var.security_group_ids["sg-alb"]]                   # security.md 1.1절. 443 ← sg-nlb만(ADR-003)

  idle_timeout               = local.alb.idle_timeout
  enable_deletion_protection = local.alb.enable_deletion_protection
  drop_invalid_header_fields = local.alb.drop_invalid_header_fields

  # access_logs 블록 없음: 액세스 로그 버킷은 04에 없다(05 AI-02)

  tags = {
    Name = local.names.alb
  }
}

# ALB 대상 그룹 3개(admin / b2b / b2c) — FR-03, FR-13, DR-05, DR-26, network.md 5.3절
resource "aws_lb_target_group" "app" {
  for_each = local.services

  name        = each.value.tg_name
  target_type = "instance"
  vpc_id      = data.aws_subnet.alb_a.vpc_id
  port        = local.app_target.port
  protocol    = local.app_target.protocol

  deregistration_delay = local.app_target.deregistration_delay

  health_check {
    enabled             = true
    protocol            = local.app_target.protocol
    port                = "traffic-port" # 8080
    path                = local.app_target.health_check_path
    matcher             = local.app_target.health_check_matcher
    interval            = local.app_target.interval
    timeout             = local.app_target.timeout
    healthy_threshold   = local.app_target.healthy_threshold
    unhealthy_threshold = local.app_target.unhealthy_threshold
  }

  tags = {
    Name = each.value.tg_name
  }
}

# 앱 서버 대상 등록: 서비스마다 1대(compute.md 1절). 결정자 지정(2026-11-15, 7단계: Terraform attachment)
resource "aws_lb_target_group_attachment" "app" {
  for_each = local.services

  target_group_arn = aws_lb_target_group.app[each.key].arn
  target_id        = var.instance_ids[each.value.instance]
  port             = local.app_target.port
}

# ALB HTTPS 443 리스너 — FR-02, ADR-003, security.md 2.1절, DR-05, DR-29
# - 인증서가 ISSUED가 아니면 만들어지지 않는다(05 R-20)
# - HTTP 80 리스너는 두지 않는다(security.md P-03, 05 AI-07)
resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.alb.https_port
  protocol          = "HTTPS"
  ssl_policy        = local.alb.ssl_policy # 반드시 명시(05 R-06)
  certificate_arn   = var.certificate_arn  # *.imcommerce.shop(S-06)

  # 기본 동작: 고정 응답 404(DR-05, network.md 4.4절). 호스트 규칙에 맞지 않는 요청과 NLB 상태 확인 요청이 여기로 온다
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }

  tags = {
    Name = local.names.listener_alb_https
  }
}

# 호스트 기반 규칙 3개 — FR-03, ADR-003. 우선순위 10·20·30(결정자 지정 2026-11-15, 7단계)
resource "aws_lb_listener_rule" "host" {
  for_each = local.services

  listener_arn = aws_lb_listener.alb_https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.host]
    }
  }

  tags = {
    Name = each.value.rule_name
  }
}

# ---------------------------------------------------------------------------
# NLB (인터넷 연결형) + EIP — ADR-010, network.md 4.4절, N-03, DR-12, FR-06
# ---------------------------------------------------------------------------

# NLB EIP 1개. 서비스 A 레코드 3개의 값(network.md 4.5절, FR-06). 바뀌면 운영자가 A 레코드를 다시 넣는다(05 R-19)
resource "aws_eip" "nlb" {
  domain = "vpc"

  tags = {
    Name = local.names.eip
  }
}

resource "aws_lb" "nlb" {
  name               = local.names.nlb
  load_balancer_type = "network"
  internal           = false  # 인터넷 연결형(ADR-010, network.md 4.4절)
  ip_address_type    = "ipv4" # IPv6 쓰지 않음(network.md 1.1절, security.md 1.2절)

  # SG는 NLB를 만들 때만 붙일 수 있다(security.md 1.1절, AWS 사양). 443 ← 0.0.0.0/0(DR-02, P-02 예외)
  security_groups = [var.security_group_ids["sg-nlb"]]

  # public-nlb-a 하나 + EIP 1개(N-03, DR-12). EIP는 subnet_mapping으로만 붙일 수 있다(AWS 사양)
  subnet_mapping {
    subnet_id     = var.subnet_ids[local.nlb.subnet_key]
    allocation_id = aws_eip.nlb.id
  }

  enable_cross_zone_load_balancing = local.nlb.enable_cross_zone_load_balancing # 끔(명시). 05 R-03
  enable_deletion_protection       = local.nlb.enable_deletion_protection

  # access_logs 블록 없음(05 AI-02)

  tags = {
    Name = local.names.nlb
  }
}

# NLB → ALB 대상 그룹 — ADR-010, DR-05, network.md 5.3절
# - 대상 종류 alb는 프로토콜 TCP만, 포트는 ALB 리스너 포트(443)와 같아야 한다(AWS 사양)
# - 대상 그룹 속성(등록 해제 지연 등)은 바꿀 수 없어 쓰지 않는다(AWS 사양)
resource "aws_lb_target_group" "nlb_alb" {
  name        = local.names.tg_nlb_alb
  target_type = "alb"
  vpc_id      = data.aws_subnet.alb_a.vpc_id
  port        = local.nlb_target.port
  protocol    = "TCP"

  health_check {
    enabled             = true
    protocol            = "HTTPS"        # 대상 종류 alb는 HTTP/HTTPS만(AWS 사양). DR-05
    port                = "traffic-port" # 443
    path                = local.nlb_target.health_check_path
    matcher             = local.nlb_target.health_check_matcher
    interval            = local.nlb_target.interval
    timeout             = local.nlb_target.timeout
    healthy_threshold   = local.nlb_target.healthy_threshold
    unhealthy_threshold = local.nlb_target.unhealthy_threshold
  }

  tags = {
    Name = local.names.tg_nlb_alb
  }
}

# ALB를 NLB 대상으로 등록. ALB에 같은 포트(443) 리스너가 있어야 등록된다(AWS 사양) → 리스너 뒤에 만든다
resource "aws_lb_target_group_attachment" "nlb_alb" {
  target_group_arn = aws_lb_target_group.nlb_alb.arn
  target_id        = aws_lb.alb.arn
  port             = local.nlb_target.port

  depends_on = [aws_lb_listener.alb_https]
}

# NLB TCP 443 리스너 — TLS를 종료하지 않고 ALB로 그대로 보낸다(security.md 2.1절, ADR-010)
# - 80 리스너는 두지 않는다(network.md 5.1절, security.md P-03)
resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = local.nlb.listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_alb.arn
  }

  tags = {
    Name = local.names.listener_nlb_tcp
  }
}
