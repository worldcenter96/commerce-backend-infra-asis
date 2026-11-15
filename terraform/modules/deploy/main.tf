# deploy 모듈
# - 책임: S3 아티팩트 버킷(버전 관리·SSE-S3·퍼블릭 차단), CodeDeploy 애플리케이션 (05 2절 모듈 표 deploy 행)
# - 근거: security.md 2.2절·3절 P-09, ADR-002, CON-09, K-02, K-04
# - 만들지 않는 것:
#   - CodeDeploy 배포 그룹 3개: Terraform 밖 운영자 수동 생성(README 3절 10-1번, compute.md 2절 v1.1, 결정자 지정 2026-11-14)
#   - CodeDeploy 서비스 역할, 앱 서버 인스턴스 프로파일 등 IAM 전부(05 AI-03, 01 FR-11, K-04, README 3절 6·7번)
#   - 버킷 정책, 수명 주기 규칙, 복제, 액세스 로깅, 객체 소유권 설정: 04에 없다(05 AI-02).
#     객체 소유권은 AWS 기본값(새 버킷 BucketOwnerEnforced, ACL 비활성화)을 그대로 쓴다(결정자 지정 2026-11-15, 8단계 구현 질문)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). 버킷 이름은 결정자 지정(2026-11-14),
#   애플리케이션 role은 결정자 지정(2026-11-15, 8단계 구현 질문)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name만 붙인다.

locals {
  bucket_name = "${var.name_prefix}-codedeploy-artifacts" # commerce-prod-codedeploy-artifacts (security.md 2.2절, 결정자 지정 2026-11-14)
  app_name    = "${var.name_prefix}-codedeploy-app"       # commerce-prod-codedeploy-app (결정자 지정 2026-11-15)
}

# ---------------------------------------------------------------------------
# S3 아티팩트 버킷 (security.md 2.2절, CON-09, ADR-002)
# - GitHub Actions가 JAR를 올리고 CodeDeploy 에이전트가 받는다(FR-08). VPC 엔드포인트 없이 공인 엔드포인트(N-02)
# - 서울 리전(provider 기본, CON-04)
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "artifacts" {
  bucket = local.bucket_name

  # 기본값을 명시. 객체·이전 버전이 남아 있으면 destroy가 BucketNotEmpty로 실패해 비우기 누락을 알린다.
  # destroy 전에 모든 객체·이전 버전을 수동으로 비운다(security.md 2.2절, K-02, 05 R-11, README 3절 11번).
  # 결정자 지정(2026-11-15)
  force_destroy = false

  tags = {
    Name = local.bucket_name # 결정자 지정(2026-11-15)
  }
}

# 버전 관리 켬 (security.md 2.2절, K-02). 이전 아티팩트로 수동 재배포(NFR-08)
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled" # security.md 5절 검증: get-bucket-versioning Status = Enabled
  }
}

# 기본 암호화 SSE-S3 (security.md 2.2절. AWS 기본값과 같지만 04 값이라 명시한다)
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3. security.md 5절 검증: get-bucket-encryption에 AES256. KMS 키 없음
    }

    # SSE-KMS에서만 효과가 있다. KMS를 쓰지 않음을 명시(결정자 지정 2026-11-15)
    bucket_key_enabled = false
  }
}

# 퍼블릭 액세스 차단 4개 모두 켬 (security.md 2.2절, P-09, NFR-06)
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# CodeDeploy 애플리케이션 (ADR-002, CON-09, FR-08)
# - 배포 그룹 3개(admin/b2b/b2c, 앱 서버 Service 태그로 1대씩, NFR-10)는 이 애플리케이션 아래에 운영자가 수동으로 만든다
#   (README 3절 10-1번, 05 3절 9-e). 서비스 역할(README 3절 7번)이 필요한 것은 배포 그룹이라 이 리소스에는 IAM이 없다
# ---------------------------------------------------------------------------

resource "aws_codedeploy_app" "backend" {
  name             = local.app_name
  compute_platform = "Server" # EC2/온프레미스 플랫폼(ADR-002, compute.md 2절). 프로바이더 기본값이지만 명시한다

  tags = {
    Name = local.app_name # 결정자 지정(2026-11-15)
  }
}
