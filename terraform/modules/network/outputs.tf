# network 모듈 출력
# - 근거: 05 2절 모듈 표 network 행의 "출력" 열(VPC ID, 서브넷 ID 맵, NAT EIP)

output "vpc_id" {
  description = "VPC ID. 3단계 security 모듈 입력"
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "서브넷 ID 맵. 키는 04의 짧은 이름(public-a, private-app-a 등)"
  value       = { for k, s in aws_subnet.this : k => s.id }
}

output "nat_eip" {
  description = "NAT Gateway 공인 IP. 프라이빗 서버가 나가는 IP(network.md 7절 검증에 씀)"
  value       = aws_eip.nat.public_ip
}
