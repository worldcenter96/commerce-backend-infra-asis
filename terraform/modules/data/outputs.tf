# data 모듈 출력
# - 근거: 05 2절 모듈 표 data 행의 "출력" 열(RDS·Redis 엔드포인트)
# - 비밀값은 출력하지 않는다. 마스터 비밀번호는 Secrets Manager에만 있다(ADR-013, 05 AI-04)

output "rds_address" {
  description = "RDS MySQL 엔드포인트 주소(포트 3306). Secret 파일의 DB 주소, security.md 5절 검증의 <RDS 주소>"
  value       = aws_db_instance.this.address
}

output "redis_primary_endpoint" {
  description = "Redis 기본 엔드포인트 주소(포트 6379, TLS 필수). Secret 파일의 Redis 주소, security.md 5절 검증의 <Redis 주소>"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}
