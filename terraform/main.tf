# 모듈 호출
# - 근거: 05 2절(main.tf), 3절 구현 순서
# - 각 모듈은 아래 단계에서 modules/ 아래에 만들고 여기서 호출한다.
#   2단계 network (완료) / 3단계 security (완료) / 4단계 dns_cert (apply 완료, 수동 작업 대기) / 5단계 compute (apply 완료) /
#   6단계 data (apply 완료) / 7단계 edge (1차 apply 완료, 리스너·규칙·NLB 등록은 인증서 ISSUED 뒤) / 8단계 deploy (apply 완료)
# - IAM 리소스는 넣지 않는다(05 AI-03, 01 FR-11, K-04).

locals {
  # 이름 규칙 {project}-{environment}-{resource}-{role}의 앞부분(05 2절, 결정자 지정 2026-11-14)
  name_prefix = "commerce-prod"

  # 문서에 정해진 값이라 변수가 아니라 locals로 둔다(terraform/README.md 2절)
  network = {
    vpc_cidr = "192.168.0.0/24" # network.md 1.1절(결정자 지정 2026-11-14)

    # network.md 2절 표. AZ-A = ap-northeast-2a, AZ-B = ap-northeast-2c (1.2절)
    subnets = {
      "public-a"        = { az = "ap-northeast-2a", cidr = "192.168.0.0/27", tier = "public" }    # Bastion, NAT Gateway (ADR-004, ADR-005)
      "public-nlb-a"    = { az = "ap-northeast-2a", cidr = "192.168.0.128/27", tier = "public" }  # NLB (ADR-010, N-03)
      "private-alb-a"   = { az = "ap-northeast-2a", cidr = "192.168.0.64/27", tier = "private" }  # ALB 노드 (ADR-010)
      "private-alb-b"   = { az = "ap-northeast-2c", cidr = "192.168.0.224/27", tier = "private" } # ALB 노드 (ADR-010, NFR-03)
      "private-app-a"   = { az = "ap-northeast-2a", cidr = "192.168.0.32/27", tier = "private" }  # 앱 서버 3대, 로그 서버 (ADR-001, ADR-006, N-05)
      "private-db-a"    = { az = "ap-northeast-2a", cidr = "192.168.0.192/27", tier = "private" } # RDS MySQL (ADR-008)
      "private-db-b"    = { az = "ap-northeast-2c", cidr = "192.168.0.96/27", tier = "private" }  # RDS 서브넷 그룹용, 리소스 없음 (ADR-014)
      "private-cache-a" = { az = "ap-northeast-2a", cidr = "192.168.0.160/27", tier = "private" } # ElastiCache Redis (ADR-008, N-06, N-08)
    }

    nat_subnet_key = "public-a" # network.md 4.2절, ADR-014
  }

  # 4단계 dns_cert: 도메인(00 3.4, CON-10). Route 53 Domains에서 이 계정으로 등록(Q-37, Terraform 밖)
  domain_name = "imcommerce.shop"
}

# 2단계: network (05 3절, network.md 1~4.2절, ADR-004, ADR-011, ADR-014, DR-15)
module "network" {
  source = "./modules/network"

  name_prefix    = local.name_prefix
  vpc_cidr       = local.network.vpc_cidr
  subnets        = local.network.subnets
  nat_subnet_key = local.network.nat_subnet_key
}

# 3단계: security (05 3절, security.md 1절·3절, ADR-005, ADR-011, DR-02, DR-19, DR-22, DR-23)
# - SG 7개와 규칙은 모듈 안 locals에 있다(security.md 1.1·1.2절 값 그대로)
module "security" {
  source = "./modules/security"

  name_prefix      = local.name_prefix
  vpc_id           = module.network.vpc_id # 05 2절 security 행 입력
  operator_ip_cidr = var.operator_ip_cidr  # sg-bastion 22 출발지(/32). S-04, DR-22, P-01
}

# 4단계: dns_cert (05 3절, network.md 4.5절, security.md 2.1절, ADR-003, DR-17, S-06)
# - 호스팅 영역 1개와 ACM 인증서 요청 1개만 만든다. Route 53 레코드·검증 대기 리소스는 없다(결정자 지정 2026-11-14)
module "dns_cert" {
  source = "./modules/dns_cert"

  name_prefix = local.name_prefix
  domain_name = local.domain_name # 05 2절 dns_cert 행 입력
}

# 5단계: compute (05 3절, compute.md 1~3절, ADR-001, ADR-002, ADR-005, ADR-006, DR-09, C-02, K-04)
# - 서버 5대·AMI·키 페어 이름·인스턴스 유형·볼륨은 모듈 안 locals에 있다(compute.md 1·2절 값 그대로)
# - IAM 인스턴스 프로파일·키 페어는 만들지 않는다(05 AI-03, K-04, compute.md 2절)
module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.subnet_ids          # 05 2절 compute 행 입력. public-a, private-app-a
  security_group_ids = module.security.security_group_ids # security.md 1.1절. sg-app, sg-log, sg-bastion
}

# 6단계: data (05 3절, data.md 2·3절, ADR-008, ADR-013, S-09, S-10, K-03, DR-09, DR-10, DR-31)
# - 엔진 버전·클래스·스토리지·사용자 이름·스키마 이름은 모듈 안 locals에 있다(data.md 2·3절 값 그대로)
# - 비밀값 입력 없음: RDS 관리형 비밀번호, Redis 인증 토큰 없음(ADR-013, 05 5.1절)
module "data" {
  source = "./modules/data"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.subnet_ids          # 05 2절 data 행 입력. private-db-a·b, private-cache-a
  security_group_ids = module.security.security_group_ids # security.md 1.1절. sg-rds, sg-redis
}

# 7단계: edge (05 3절, network.md 4.4·5.3절, security.md 2.1절, ADR-003, ADR-010, DR-05, DR-12, DR-26, DR-29)
# - 이름·TLS 정책·상태 확인 값·호스트 이름·교차 영역 끔은 모듈 안 locals에 있다(문서 값 그대로)
# - 서비스 A 레코드 3개는 만들지 않는다. apply 뒤 운영자가 NLB EIP로 수동 생성(README 3절 5번, network.md 4.5절)
# - apply 전에 인증서가 ISSUED여야 한다(05 R-20, 결정자 지정 2026-11-15: 코드·plan 먼저)
module "edge" {
  source = "./modules/edge"

  name_prefix        = local.name_prefix
  subnet_ids         = module.network.subnet_ids          # 05 2절 edge 행 입력. public-nlb-a, private-alb-a·b
  security_group_ids = module.security.security_group_ids # security.md 1.1절. sg-nlb, sg-alb
  certificate_arn    = module.dns_cert.certificate_arn    # *.imcommerce.shop (S-06, ADR-003)
  instance_ids       = module.compute.instance_ids        # app-admin, app-b2b, app-b2c (compute.md 1절)
}

# 8단계: deploy (05 3절, security.md 2.2절, ADR-002, CON-09, K-02, K-04)
# - S3 아티팩트 버킷(commerce-prod-codedeploy-artifacts)과 CodeDeploy 애플리케이션만 만든다. 이름은 모듈 안 locals
# - 배포 그룹 3개·서비스 역할·인스턴스 프로파일은 Terraform 밖(README 3절 6·7·10-1번, 05 AI-03)
# - 05 2절 deploy 행 입력 "없음": 이름 규칙 앞부분만 넘긴다
module "deploy" {
  source = "./modules/deploy"

  name_prefix = local.name_prefix
}
