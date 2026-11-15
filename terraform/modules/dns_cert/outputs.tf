# dns_cert 모듈 출력
# - 근거: 05 2절 모듈 표 dns_cert 행의 "출력" 열(호스팅 영역 ID, 네임서버 4개, 인증서 ARN, 검증 CNAME 이름·값)

output "zone_id" {
  description = "Route 53 호스팅 영역 ID. 서비스 A 레코드·검증 CNAME을 수동으로 넣을 영역"
  value       = aws_route53_zone.public.zone_id
}

output "name_servers" {
  description = "호스팅 영역 네임서버 4개. Route 53 Domains에서 도메인 네임서버를 이 값으로 바꾼다(network.md 4.5절, Q-37)"
  value       = aws_route53_zone.public.name_servers
}

output "certificate_arn" {
  description = "ACM 와일드카드 인증서 ARN. 7단계 ALB 443 리스너가 쓴다(ADR-003)"
  value       = aws_acm_certificate.wildcard.arn
}

output "validation_records" {
  description = "ACM DNS 검증 CNAME(수동 생성용, network.md 4.5절). 와일드카드 1개라 항목은 1개"
  value = [
    for o in aws_acm_certificate.wildcard.domain_validation_options : {
      domain = o.domain_name
      name   = o.resource_record_name
      type   = o.resource_record_type
      value  = o.resource_record_value
    }
  ]
}
