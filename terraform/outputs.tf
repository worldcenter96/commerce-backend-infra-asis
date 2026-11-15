# 출력값
# - 근거: 05 2절(outputs.tf), 2절 모듈 표의 "출력" 열
# - 각 모듈 단계에서 추가한다. 예정 항목:
#   4단계: 호스팅 영역 네임서버 4개(Route 53 Domains 네임서버 변경에 씀, Q-37), ACM 검증 CNAME 이름·값(수동 생성에 씀), network.md 4.5절 v1.6
#   5단계: Bastion 공인 IP, 인스턴스 사설 IP
#   6단계: RDS·Redis 엔드포인트
#   7단계: NLB EIP(서비스 A 레코드 수동 생성에 씀, network.md 4.5절 v1.2)
#   8단계: 아티팩트 버킷 이름, CodeDeploy 애플리케이션 이름(배포 그룹은 Terraform 밖)
# - 비밀값은 출력하지 않는다(05 AI-04, ADR-013).

# 2단계: network (05 2절 network 행 "출력": VPC ID, 서브넷 ID 맵, NAT EIP)
output "vpc_id" {
  description = "VPC ID (network.md 7절 검증의 <VPC ID>)"
  value       = module.network.vpc_id
}

output "subnet_ids" {
  description = "서브넷 ID 맵. 키는 04의 짧은 이름"
  value       = module.network.subnet_ids
}

output "nat_eip" {
  description = "NAT Gateway EIP (network.md 7절 '프라이빗 서버의 나가는 IP' 검증)"
  value       = module.network.nat_eip
}

# 3단계: security (05 2절 security 행 "출력": SG ID 맵)
output "security_group_ids" {
  description = "SG ID 맵. 키는 04의 짧은 이름(security.md 1.1절). security.md 5절 검증의 <sg-...>"
  value       = module.security.security_group_ids
}

# 4단계: dns_cert (05 2절 dns_cert 행 "출력": 호스팅 영역 ID, 네임서버 4개, 인증서 ARN, 검증 CNAME 이름·값)
output "route53_zone_id" {
  description = "imcommerce.shop 호스팅 영역 ID. 검증 CNAME·서비스 A 레코드를 수동으로 넣을 영역(network.md 4.5절)"
  value       = module.dns_cert.zone_id
}

output "route53_name_servers" {
  description = "호스팅 영역 네임서버 4개. Route 53 Domains에서 도메인 네임서버를 이 값으로 바꾼다(network.md 4.5절, Q-37)"
  value       = module.dns_cert.name_servers
}

output "acm_certificate_arn" {
  description = "ACM *.imcommerce.shop 인증서 ARN. security.md 5절 검증의 <ARN>, 7단계 ALB 리스너 입력"
  value       = module.dns_cert.certificate_arn
}

output "acm_validation_records" {
  description = "ACM DNS 검증 CNAME 이름·유형·값. 운영자가 호스팅 영역에 수동으로 만든다(network.md 4.5절, 05 R-20)"
  value       = module.dns_cert.validation_records
}

# 5단계: compute (05 2절 compute 행 "출력": Bastion 공인 IP, 인스턴스 사설 IP)
# - 인스턴스 ID는 모듈 출력(module.compute.instance_ids)으로만 두고 7단계 edge 모듈에 넘긴다
output "bastion_public_ip" {
  description = "Bastion 공인 IP(자동 할당, ADR-005). 운영자 SSH 접속 주소(security.md 5절). 중지·시작하면 바뀐다"
  value       = module.compute.bastion_public_ip
}

output "instance_private_ips" {
  description = "인스턴스 사설 IP 맵(app-admin, app-b2b, app-b2c, log, bastion). Bastion 경유 SSH, Alloy의 Loki 주소에 쓴다"
  value       = module.compute.private_ips
}

# 6단계: data (05 2절 data 행 "출력": RDS·Redis 엔드포인트). 비밀번호는 출력하지 않는다(ADR-013, AI-04)
output "rds_address" {
  description = "RDS MySQL 엔드포인트 주소(3306, TLS 필수 S-09). 마스터 비밀번호는 Secrets Manager에서 읽는다(README 3절 9번)"
  value       = module.data.rds_address
}

output "redis_primary_endpoint" {
  description = "Redis 기본 엔드포인트 주소(6379, TLS 필수 · 인증 토큰 없음, S-10). redis-cli는 --tls로 접속한다"
  value       = module.data.redis_primary_endpoint
}

# 7단계: edge (05 2절 edge 행 "출력": NLB EIP, ALB ARN, 대상 그룹 ARN)
output "nlb_eip" {
  description = "NLB EIP. 운영자가 admin·b2b·b2c.imcommerce.shop A 레코드 3개를 이 값으로 수동 생성한다(network.md 4.5절, README 3절 5번)"
  value       = module.edge.nlb_eip
}

output "alb_arn" {
  description = "ALB ARN. network.md·security.md 5절 검증의 <ALB ARN>"
  value       = module.edge.alb_arn
}

output "target_group_arns" {
  description = "대상 그룹 ARN 맵(admin, b2b, b2c, nlb-alb). network.md 7절 대상 상태 검증, 05 4절 7단계 상태 확인 값 검증"
  value       = module.edge.target_group_arns
}

# 8단계: deploy (05 2절 deploy 행 "출력": 버킷 이름, 애플리케이션 이름). 배포 그룹은 Terraform 밖(README 3절 10-1번)
output "artifact_bucket_name" {
  description = "S3 아티팩트 버킷 이름(commerce-prod-codedeploy-artifacts). GitHub Actions 업로드 대상, security.md 5절 검증의 <버킷>"
  value       = module.deploy.artifact_bucket_name
}

output "codedeploy_app_name" {
  description = "CodeDeploy 애플리케이션 이름. 배포 그룹 3개(admin/b2b/b2c)를 이 아래에 수동으로 만든다(README 3절 10-1번)"
  value       = module.deploy.codedeploy_app_name
}
