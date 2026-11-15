# compute 모듈
# - 책임: 앱 서버 3대(admin·b2b·b2c), 로그 서버, Bastion (05 2절 모듈 표 compute 행)
# - 근거: compute.md v1.4 1·2·3절, ADR-001, ADR-002, ADR-005, ADR-006, ADR-014, DR-09, C-02, K-04
# - 만들지 않는 것:
#   - 키 페어: AWS에 있는 3개를 이름으로만 지정한다(compute.md 2절, 결정자 지정 2026-11-15, 05 1.1절)
#   - IAM 인스턴스 프로파일·역할: Terraform 밖(05 AI-03, 01 FR-11, K-04, C-01, README 3절 6번).
#     밖에서 붙인 뒤 plan 차이가 없도록 iam_instance_profile을 변경 감지에서 뺀다(05 R-05)
#   - Auto Scaling 그룹·시작 템플릿: 쓰지 않는다(compute.md 3절, CON-14, Q-17)
#   - user_data: 쓰지 않는다. 서버 소프트웨어는 운영자가 수동 설치한다(05 1.1절, README 3절 8번,
#     결정자 지정 2026-11-15, 5단계 구현 질문)
#   - EIP: Bastion은 공인 IP 자동 할당이다(compute.md 2절, ADR-005)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). 인스턴스 ec2-<키>, 루트 볼륨 ebs-root-<키>.
#   결정자 지정(2026-11-15, 5단계 구현 질문)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name·Service만 붙인다.

locals {
  # -------------------------------------------------------------------------
  # 공통 값 (compute.md 2절)
  # -------------------------------------------------------------------------

  # Ubuntu 24.04 LTS 공식 AMI(x86_64) 고정. ubuntu-noble-24.04-amd64-server-20261108, 소유자 Canonical 099720109477.
  # 최신 AMI를 조회하지 않는다(새 AMI가 나오면 plan이 서버 교체로 나와 FR-11 검증이 실패한다).
  # compute.md 2절, CON-07, CON-14, 결정자 지정(2026-11-14)
  ami_id = "ami-05b829d75c9f9183e"

  # 키 페어 이름 3개. AWS(ap-northeast-2)에 이미 있는 것을 쓴다(compute.md 2절, ADR-005, 결정자 지정 2026-11-15)
  key_names = {
    app     = "commerce-prod-app-key"     # 앱 서버 3대
    log     = "commerce-prod-log-key"     # 로그 서버
    bastion = "commerce-prod-bastion-key" # Bastion
  }

  # -------------------------------------------------------------------------
  # 서버 5대 (compute.md 1절 표). 키는 이름 규칙의 {role} 자리에 들어간다.
  # - 서비스별 1대 고정, 수평 확장 없음(compute.md 3절, CON-14)
  # - service: CodeDeploy 배포 그룹(Terraform 밖 수동 생성)이 고르는 Service 태그 값. 앱 서버만(compute.md 2절, NFR-10)
  # -------------------------------------------------------------------------
  servers = {
    "app-admin" = {
      instance_type = "t3.medium"     # ADR-001, CON-14
      subnet        = "private-app-a" # compute.md 1절, network.md 2절
      sg            = "sg-app"        # compute.md 2절, security.md 1.1절
      key           = "app"
      volume_size   = 8 # AWS 기본값(Ubuntu 공식 AMI 루트 8GB), compute.md 2절
      public_ip     = false
      service       = "admin"
    }
    "app-b2b" = {
      instance_type = "t3.medium" # ADR-001, CON-14
      subnet        = "private-app-a"
      sg            = "sg-app"
      key           = "app"
      volume_size   = 8
      public_ip     = false
      service       = "b2b"
    }
    "app-b2c" = {
      instance_type = "t3.medium" # ADR-001, CON-14
      subnet        = "private-app-a"
      sg            = "sg-app"
      key           = "app"
      volume_size   = 8
      public_ip     = false
      service       = "b2c"
    }
    # 로그 서버(Loki + Grafana)
    "log" = {
      instance_type = "t3.large"      # ADR-006
      subnet        = "private-app-a" # compute.md 1절(private-log-a 삭제, network.md N-05 2026-11-14 변경)
      sg            = "sg-log"
      key           = "log"
      volume_size   = 20 # ADR-006(20GB), compute.md 2절
      public_ip     = false
      service       = null
    }
    "bastion" = {
      instance_type = "t3.medium" # ADR-005
      subnet        = "public-a"  # compute.md 1절, network.md 2절, ADR-014
      sg            = "sg-bastion"
      key           = "bastion"
      volume_size   = 8
      public_ip     = true # Bastion만 공인 IP 자동 할당(compute.md 2절, ADR-005)
      service       = null
    }
  }
}

# ---------------------------------------------------------------------------
# EC2 인스턴스 5대 (compute.md 1·2절, ADR-001, ADR-005, ADR-006)
# - 구매 옵션 온디맨드(ADR-001): instance_market_options 블록을 두지 않는다
# ---------------------------------------------------------------------------

resource "aws_instance" "this" {
  for_each = local.servers

  ami           = local.ami_id
  instance_type = each.value.instance_type
  key_name      = local.key_names[each.value.key]

  subnet_id              = var.subnet_ids[each.value.subnet]
  vpc_security_group_ids = [var.security_group_ids[each.value.sg]]

  # 앱·로그 서버 없음, Bastion만 자동 할당(compute.md 2절, network.md 2절, security.md P-04, ADR-005).
  # 사설 IP는 AWS 자동 할당(private_ip 없음). 결정자 지정(2026-11-15, 5단계 구현 질문)
  associate_public_ip_address = each.value.public_ip

  # CPU 크레딧 Standard. AWS 기본값(Unlimited)과 다르므로 명시한다(compute.md 2절, C-02, NFR-12, CON-02)
  credit_specification {
    cpu_credits = "standard"
  }

  # 아래 값은 AWS 기본값을 명시한 것이다. 결정자 지정(2026-11-15, 5단계 구현 질문)
  monitoring                           = false  # 상세 모니터링 끔. 메트릭은 범위 밖(01 2.2, Q-21), 비용(NFR-12)
  disable_api_termination              = false  # 종료 보호 끔. 테스트 뒤 destroy(Q-04)
  disable_api_stop                     = false  # 중지 보호 끔. 매일 중지(CON-03, compute.md 3절)
  instance_initiated_shutdown_behavior = "stop" # OS 종료 시 중지(종료 아님)

  # IMDSv2 필수. AMI의 ImdsSupport=v2.0 기본과 같은 값을 명시한다(결정자 지정 2026-11-15, 5단계 구현 질문)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # AMI ImdsSupport=v2.0의 기본값
  }

  root_block_device {
    volume_type           = "gp3"                  # compute.md 2절(AWS 관례). IOPS·처리량은 gp3 기본값
    volume_size           = each.value.volume_size # compute.md 2절
    encrypted             = true                   # AWS 관리형 키(aws/ebs, kms_key_id 없음). security.md S-08, DR-09
    delete_on_termination = true                   # compute.md 2절(AWS 기본값), Q-04

    tags = {
      Name = "${var.name_prefix}-ebs-root-${each.key}" # 결정자 지정(2026-11-15, 5단계 구현 질문)
    }
  }

  tags = merge(
    { Name = "${var.name_prefix}-ec2-${each.key}" }, # 05 2절, 결정자 지정(2026-11-15). 예: commerce-prod-ec2-app-admin
    # Service 태그는 앱 서버만. CodeDeploy 배포 그룹이 서비스별 1대를 고른다(compute.md 2절, NFR-10, ADR-002)
    each.value.service == null ? {} : { Service = each.value.service }
  )

  lifecycle {
    # 05 R-05: IAM 인스턴스 프로파일은 Terraform 밖에서 앱 서버에 붙인다(README 3절 6번, K-04).
    # 붙인 뒤 plan에 차이가 생기지 않도록 변경 감지에서 뺀다(FR-11 plan -detailed-exitcode 0). 9-a 뒤 plan으로 확인
    ignore_changes = [iam_instance_profile]
  }
}
