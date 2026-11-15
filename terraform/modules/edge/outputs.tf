# edge 모듈 출력
# - 근거: 05 2절 모듈 표 edge 행의 "출력" 열(NLB EIP, ALB ARN, 대상 그룹 ARN)

output "nlb_eip" {
  description = "NLB 공인 IP(EIP). 서비스 A 레코드 3개(admin·b2b·b2c.imcommerce.shop)의 값(network.md 4.5절, README 3절 5번)"
  value       = aws_eip.nlb.public_ip
}

output "alb_arn" {
  description = "ALB ARN. network.md·security.md 5절 검증의 <ALB ARN>"
  value       = aws_lb.alb.arn
}

output "target_group_arns" {
  description = "대상 그룹 ARN 맵. admin, b2b, b2c는 ALB 대상 그룹(FR-13 검증), nlb-alb는 NLB → ALB 대상 그룹"
  value = merge(
    { for k, tg in aws_lb_target_group.app : k => tg.arn },
    { "nlb-alb" = aws_lb_target_group.nlb_alb.arn }
  )
}
