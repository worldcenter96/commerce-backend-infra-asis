# compute 모듈 출력
# - 근거: 05 2절 모듈 표 compute 행의 "출력" 열(인스턴스 ID·사설 IP, Bastion 공인 IP)

output "instance_ids" {
  description = "인스턴스 ID 맵. 키는 app-admin, app-b2b, app-b2c, log, bastion. 7단계 edge 모듈 입력(앱 서버 대상 등록)"
  value       = { for k, i in aws_instance.this : k => i.id }
}

output "private_ips" {
  description = "인스턴스 사설 IP 맵. 키는 instance_ids와 같다. Alloy의 Loki 주소, Bastion 경유 SSH에 쓴다"
  value       = { for k, i in aws_instance.this : k => i.private_ip }
}

output "bastion_public_ip" {
  description = "Bastion 공인 IP(자동 할당, ADR-005). 중지·시작하면 바뀐다(AWS 사양). 이 값은 마지막 apply·plan 시점 값이라 시작 뒤에는 aws ec2 describe-instances로 다시 확인한다"
  value       = aws_instance.this["bastion"].public_ip
}
