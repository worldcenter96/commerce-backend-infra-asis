# data 모듈
# - 책임: RDS 서브넷 그룹·파라미터 그룹·MySQL 인스턴스, ElastiCache 서브넷 그룹·Redis 복제 그룹 (05 2절 모듈 표 data 행)
# - 근거: data.md v1.5 2·3절, ADR-008, ADR-013, ADR-014, security.md S-07~S-10, K-03, DR-09, DR-10, DR-31
# - 만들지 않는 것:
#   - Secrets Manager 시크릿: RDS 관리형 비밀번호라 RDS가 만들고 지운다. 코드에 시크릿 리소스가 없다(ADR-013).
#     자동 교체는 apply 직후 운영자가 Terraform 밖에서 끈다(data.md 2절 v1.5, 05 R-21, README 3절 9-1번)
#   - 비밀값 변수·RDS password 인자·Redis auth_token: 없다(ADR-013, S-10, 05 AI-04)
#   - Redis 사용자 지정 파라미터 그룹: 04에 없다. 기본 default.redis7을 쓴다(data.md 3절, 05 AI-02)
#   - IAM(향상된 모니터링 역할 등): 없다(05 AI-03, K-04)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). 결정자 지정(2026-11-15, 6단계 구현 질문)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name만 붙인다.

locals {
  # -------------------------------------------------------------------------
  # RDS MySQL (data.md 2절)
  # -------------------------------------------------------------------------
  rds = {
    identifier           = "${var.name_prefix}-rds-mysql"       # 05 2절 예시
    subnet_group_name    = "${var.name_prefix}-dbsubnet-mysql"  # 결정자 지정(2026-11-15, 6단계)
    parameter_group_name = "${var.name_prefix}-dbparam-mysql84" # 이름에 '.'을 쓸 수 없다(AWS 사양)
    engine_version       = "8.4.13"                             # 8.4 최신 부 버전(DR-10, 2026-11-15 서울 리전 재조회 available)
    parameter_family     = "mysql8.4"                           # data.md 2절
    instance_class       = "db.t3.micro"                        # ADR-008
    allocated_storage    = 20                                   # gp3 최소 20GB(AWS 요구사항), Q-14
    username             = "dbadmin"                            # 결정자 지정(2026-11-14)
    db_name              = "imcommerce"                         # 초기 스키마. 결정자 지정(2026-11-14)
    port                 = 3306                                 # AWS 기본값, security.md 1.2절
    availability_zone    = "ap-northeast-2a"                    # Single-AZ, AZ-A의 private-db-a(ADR-008, ADR-014, network.md 1.2절)
    subnet_keys          = ["private-db-a", "private-db-b"]     # 서브넷 그룹은 AZ 2개 필요(AWS 요구사항), network.md 2절
  }

  # -------------------------------------------------------------------------
  # ElastiCache Redis (data.md 3절)
  # -------------------------------------------------------------------------
  redis = {
    replication_group_id = "${var.name_prefix}-redis-session"     # 용도: 로그인 세션(FR-04). 결정자 지정(2026-11-15, 6단계)
    subnet_group_name    = "${var.name_prefix}-cachesubnet-redis" # 결정자 지정(2026-11-15, 6단계)
    engine_version       = "7.1"                                  # Redis OSS 7.x 최신(DR-10, 2026-11-15 서울 리전 재조회)
    parameter_group_name = "default.redis7"                       # 종류 redis7(data.md 3절), 클러스터 모드 끔(cluster-enabled=no)
    node_type            = "cache.t3.micro"                       # ADR-008
    port                 = 6379                                   # AWS 기본값, security.md 1.2절
    subnet_keys          = ["private-cache-a"]                    # 서브넷 하나(N-06, N-08, 05 R-04)
  }
}

# ---------------------------------------------------------------------------
# RDS 서브넷 그룹 (data.md 2절, network.md 2절, ADR-014)
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name        = local.rds.subnet_group_name
  description = "RDS MySQL subnet group (private-db-a, private-db-b)" # AWS가 한글 설명을 받지 않음(README 1행 SG 규칙과 같음)
  subnet_ids  = [for k in local.rds.subnet_keys : var.subnet_ids[k]]

  tags = {
    Name = local.rds.subnet_group_name
  }
}

# ---------------------------------------------------------------------------
# RDS 사용자 지정 파라미터 그룹 (data.md 2절, security.md S-09, K-03)
# - require_secure_transport=ON 말고는 기본값. 기본 파라미터 그룹은 값을 바꿀 수 없다(AWS 사양)
# ---------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  name        = local.rds.parameter_group_name
  family      = local.rds.parameter_family
  description = "MySQL 8.4 - require_secure_transport ON (S-09)"

  # TLS가 아닌 접속을 거부한다(security.md S-09, 2.1절, K-03). default.mysql8.4에는 값이 없다(2026-11-15 조회).
  # dynamic 파라미터라 재부팅 없이 적용된다(2026-11-15 조회 ApplyType=dynamic). 허용 값 0,1
  parameter {
    name         = "require_secure_transport"
    value        = "1"
    apply_method = "immediate"
  }

  tags = {
    Name = local.rds.parameter_group_name
  }
}

# ---------------------------------------------------------------------------
# RDS MySQL 인스턴스 (data.md 2절, ADR-008, ADR-013)
# ---------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier     = local.rds.identifier
  engine         = "mysql"
  engine_version = local.rds.engine_version # 고정. 부 버전 자동 업그레이드 끔(아래)
  instance_class = local.rds.instance_class

  # 배포: Single-AZ, AZ-A(ADR-008, ADR-014)
  multi_az             = false
  availability_zone    = local.rds.availability_zone
  db_subnet_group_name = aws_db_subnet_group.this.name

  # 스토리지: gp3 20GB, 자동 확장 끔(max_allocated_storage 0)(data.md 2절, CON-02, Q-14)
  storage_type          = "gp3"
  allocated_storage     = local.rds.allocated_storage
  max_allocated_storage = 0

  # 저장 암호화 켬, AWS 관리형 키(aws/rds, kms_key_id 없음)(security.md S-08, DR-09)
  storage_encrypted = true

  # 접속
  port                   = local.rds.port
  publicly_accessible    = false                              # security.md P-04, NFR-06
  vpc_security_group_ids = [var.security_group_ids["sg-rds"]] # security.md 1.1절
  parameter_group_name   = aws_db_parameter_group.this.name   # TLS 강제(S-09)

  # 계정·스키마
  username = local.rds.username
  db_name  = local.rds.db_name

  # 마스터 비밀번호: RDS 관리형(Secrets Manager). password 인자 없음 → 코드·변수·State에 비밀번호 없음
  # (ADR-013, data.md 2절, security.md 2.3절, 05 AI-04). 시크릿 KMS 키는 Secrets Manager 기본 키(지정 안 함)
  manage_master_user_password = true

  # 백업·삭제: 자동 백업 끔(API 기본값 1일과 다름), 최종 스냅샷 없음, 삭제 방지 끔(data.md 2절, Q-04, Q-09, NFR-14)
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  # 유지 관리: 부 버전 자동 업그레이드 끔(AWS 기본값 켬과 다름, DR-31). 유지 관리 창은 AWS가 정함(지정 안 함, data.md 2절)
  auto_minor_version_upgrade = false

  # 변경을 바로 적용한다. 대기 중 변경으로 plan 차이가 남지 않게 함(FR-11). 결정자 지정(2026-11-15, 6단계)
  apply_immediately = true

  tags = {
    Name = local.rds.identifier
  }
}

# ---------------------------------------------------------------------------
# ElastiCache 서브넷 그룹 (data.md 3절, network.md 2절 N-06·N-08, 05 R-04)
# - private-cache-a 하나. AZ-B 캐시 서브넷은 없다(예비 대역 없음)
# ---------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "this" {
  name        = local.redis.subnet_group_name
  description = "Redis subnet group (private-cache-a)"
  subnet_ids  = [for k in local.redis.subnet_keys : var.subnet_ids[k]]

  tags = {
    Name = local.redis.subnet_group_name
  }
}

# ---------------------------------------------------------------------------
# ElastiCache Redis 복제 그룹 (data.md 3절, ADR-008, ADR-013, K-03)
# - 전송 중 암호화 때문에 복제 그룹 리소스로 만든다. 노드 1개(결정자 지정 2026-11-14, 05 R-04)
# ---------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.redis.replication_group_id
  description          = "Redis OSS 7.1 login session store (FR-04)"

  engine               = "redis"
  engine_version       = local.redis.engine_version
  parameter_group_name = local.redis.parameter_group_name
  node_type            = local.redis.node_type
  port                 = local.redis.port

  # 노드 1개, 복제본 없음, 클러스터 모드 끔(data.md 3절, ADR-008, 00 3.2). 자동 장애 조치·Multi-AZ는 노드 1개라 끔
  num_cache_clusters         = 1
  cluster_mode               = "disabled"
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_ids["sg-redis"]] # security.md 1.1절

  # 암호화: 저장 켬(AWS 관리형 키, kms_key_id 없음)(S-08, DR-09), 전송 중 켬·TLS만 허용(S-07, K-03).
  # transit_encryption_mode required: 결정자 지정(2026-11-15, 6단계). security.md 2.1절 Bastion → Redis TLS 필수
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  # 인증 토큰 없음(auth_token 인자 없음). 접근은 sg-redis로만 제한(S-10 변경, ADR-013)

  # 스냅샷 끔(0일), 최종 스냅샷 없음(final_snapshot_identifier 없음)(data.md 3절, Q-09, Q-15, Q-04)
  snapshot_retention_limit = 0

  # 부 버전 자동 업그레이드 끔(DR-31). 유지 관리 창은 AWS가 정함(지정 안 함)
  auto_minor_version_upgrade = false

  # 변경을 바로 적용한다(FR-11). 결정자 지정(2026-11-15, 6단계)
  apply_immediately = true

  tags = {
    Name = local.redis.replication_group_id
  }
}
