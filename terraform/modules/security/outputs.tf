# security 모듈 출력
# - 근거: 05 2절 모듈 표 security 행의 "출력" 열(SG ID 맵)

output "security_group_ids" {
  description = "SG ID 맵. 키는 04의 짧은 이름(sg-nlb, sg-alb, sg-app, sg-log, sg-bastion, sg-rds, sg-redis). 5~7단계 모듈 입력"
  value       = { for k, sg in aws_security_group.this : k => sg.id }
}
