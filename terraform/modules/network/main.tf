# network 모듈
# - 책임: VPC, 서브넷 8개, IGW, NAT Gateway + EIP, rt-public·rt-private와 서브넷 연결 (05 2절 모듈 표 network 행)
# - 근거: network.md v1.4 1~4.2절, ADR-004, ADR-011, ADR-014
# - 만들지 않는 것: S3 게이트웨이 엔드포인트, 인터페이스 엔드포인트(network.md 4.3절, N-02, 05 1.2절), IPv6(1.1절)
# - 이름: {project}-{environment}-{resource}-{role} (05 2절). VPC·IGW·NAT·EIP의 role은 결정자 지정(2026-11-15)
# - 공통 태그(Project, Environment, ManagedBy)는 루트 provider default_tags가 붙인다. 여기서는 Name만 붙인다.

locals {
  public_subnets  = { for k, s in var.subnets : k => s if s.tier == "public" }
  private_subnets = { for k, s in var.subnets : k => s if s.tier == "private" }
}

# ---------------------------------------------------------------------------
# VPC (network.md 1.1절)
# ---------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr # 192.168.0.0/24, network.md 1.1절(결정자 지정 2026-11-14)
  enable_dns_support   = true         # network.md 1.1절. AWS 기본값. RDS·ElastiCache 엔드포인트 이름 해석(FR-04)
  enable_dns_hostnames = true         # network.md 1.1절. AWS 관례(기본값은 꺼짐)
  # IPv6: 쓰지 않음(network.md 1.1절). assign_generated_ipv6_cidr_block 기본값 false 유지

  tags = {
    Name = "${var.name_prefix}-vpc-main"
  }
}

# ---------------------------------------------------------------------------
# 서브넷 8개 (network.md 2절, ADR-014)
# - 퍼블릭 2개: 공인 IP 자동 할당 켬(Bastion, ADR-005)
# - 프라이빗 6개: 끔(FR-05, NFR-06)
# - AZ-B 서브넷(private-alb-b, private-db-b)에는 이 모듈에서 리소스를 두지 않는다(ADR-014)
# ---------------------------------------------------------------------------

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az               # network.md 1.2절(AZ-A = 2a, AZ-B = 2c)
  cidr_block              = each.value.cidr             # network.md 2절 표
  map_public_ip_on_launch = each.value.tier == "public" # network.md 2절

  tags = {
    Name = "${var.name_prefix}-subnet-${each.key}" # 05 2절 예: commerce-prod-subnet-public-a
  }
}

# ---------------------------------------------------------------------------
# 인터넷 게이트웨이 (network.md 4.1절, ADR-011)
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw-main"
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway + EIP (network.md 4.2절, ADR-004, ADR-014)
# - 1개, public-a, 퍼블릭 연결 방식
# - EIP는 퍼블릭 NAT Gateway를 만들 때 필요해서 둔다(AWS 요구사항). 고정 IP 요구 때문이 아님(Q-36)
# ---------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-eip-nat-${var.nat_subnet_key}"
  }

  depends_on = [aws_internet_gateway.this] # IGW가 먼저 있어야 한다(Terraform aws_eip 문서 권장, 일반 지식)
}

resource "aws_nat_gateway" "this" {
  connectivity_type = "public"                               # network.md 4.2절, ADR-004
  subnet_id         = aws_subnet.this[var.nat_subnet_key].id # public-a, network.md 4.2절, ADR-014
  allocation_id     = aws_eip.nat.id

  tags = {
    Name = "${var.name_prefix}-nat-${var.nat_subnet_key}"
  }

  depends_on = [aws_internet_gateway.this] # 퍼블릭 NAT Gateway는 IGW가 있어야 동작한다(Terraform aws_nat_gateway 문서 권장, 일반 지식)
}

# ---------------------------------------------------------------------------
# 라우팅 테이블 (network.md 3절, ADR-011)
# - local 경로(VPC CIDR)는 AWS가 자동으로 만든다(AWS 기본값)
# - VPC 기본(main) 라우팅 테이블에는 서브넷을 연결하지 않는다. 모든 서브넷을 아래 둘 중 하나에 명시적으로 연결
# - S3 게이트웨이 엔드포인트 경로 없음(N-02)
# ---------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0" # network.md 3절, ADR-011
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-rt-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # 하나만 둔다. AZ-B 프라이빗 서브넷도 AZ-A의 NAT Gateway로 나간다(network.md 3절, ADR-011, ADR-014)
  route {
    cidr_block     = "0.0.0.0/0" # network.md 3절, ADR-004
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-rt-private"
  }
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets # public-a, public-nlb-a (network.md 3절)

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets # private-alb-a/b, private-app-a, private-db-a/b, private-cache-a (network.md 3절)

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private.id
}
