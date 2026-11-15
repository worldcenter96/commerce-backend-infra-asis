# 04-design / security.md — 보안 상세 설계

| 항목 | 값 |
|---|---|
| 상태 | Approved |
| 버전 | 1.4 |
| 날짜 | 2026-11-15 |
| 작성자 | 박가온누리 |
| 선행 문서 | [01-requirements.md](../01-requirements.md) v1.5 (Approved), [03-architecture.md](../03-architecture.md) v1.9 (Approved), [adr/](../adr/) ADR-001~ADR-014 (Accepted. ADR-007·ADR-009·ADR-012는 대체됨), [network.md](network.md) v1.5 (Approved) |

### 변경 이력

| 버전 | 변경 내용 | 근거 |
|---|---|---|
| 0.1 | 최초 작성 | 03 v1.2, ADR-001~ADR-011 |
| 0.2 | S-05 해결: 모든 보안 그룹의 아웃바운드를 전체 허용으로 정함. 1.2절 아웃바운드 행을 SG마다 한 행으로 바꿈. 검증 항목 추가 | 결정자 지정 (2026-11-12) |
| 0.3 | NLB를 AZ-A 하나에만 둠(network.md N-03). S3는 VPC 엔드포인트 없이 공인 엔드포인트로 접근하되 버킷은 비공개 유지(N-02) | 결정자 지정 (2026-11-12) |
| 0.4 | 결정자 구성도에 따라 network.md v0.4의 용도별 서브넷 이름으로 1.1절 서브넷 열을 바꿈. 보안 그룹 규칙은 바뀌지 않음. 검증 항목 1개 추가 | 결정자 구성도 (2026-11-12) |
| 0.5 | 로그 서버를 별도 프라이빗 서브넷(private-log-a)으로 옮김(network.md N-05). 규칙은 바뀌지 않음 | 결정자 지정 (2026-11-12) |
| 0.6 | S-01·S-02 해결: sg-app 22 ← sg-bastion, sg-log 3100 ← sg-app, 3000 ← sg-bastion, 22 ← sg-bastion 확정. P-01 갱신, 검증 항목 추가 | 결정자 지정 (2026-11-12) |
| 0.7 | S-04 해결: Bastion SSH 허용 출발지를 `<operator-ip>/32`로 확정. P-01, 검증 항목 갱신 | 결정자 지정 (2026-11-12) |
| 0.8 | 설계 리뷰 결정 반영: NLB 인바운드 `0.0.0.0/0` 확정(DR-02, S-03), 앱 → RDS·Redis TLS 사용 안 함·Redis 인증 토큰 없음(DR-07, S-07), 저장 데이터 암호화 켬(DR-09, S-08), Secret 파일은 Terraform 범위 밖(DR-11). 검증 항목 1개 추가 | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.9 | 설계 리뷰 결정 반영: 선행 문서 버전 수정·변경 이력 정렬(DR-18), P-05 검증에 sg-log 추가(DR-19), `0.0.0.0/0` 예외 근거 수정(DR-23), TLS 표에 VPC 안 구간 3개 추가(DR-24), TLS 1.2 이상 검증 방법 변경(DR-25) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.10 | S3 아티팩트 버킷 버전 관리 켬(K-02). TLS 정책은 그대로 유지(DR-29). 검증 항목 1개 추가 | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.11 | K-03 반영: 앱 → RDS·Redis 전송 암호화 켬(DR-07 변경), Bastion → Redis는 TLS 필수. S-09(RDS TLS 강제), S-10(Redis 인증 토큰) 추가. S3 버킷은 삭제 전 수동으로 비우는 절차를 05에 넣음(K-02 관련) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.12 | 01 v1.4에서 FR-12가 삭제돼 근거를 00 종료 처리(Q-04)로 바꿈(1곳). 선행 문서 버전 갱신 | 01 v1.4 FR-12 삭제 (결정자 지정, 2026-11-12) |
| 0.13 | S-06 해결: ACM 와일드카드 `*.imcommerce.shop`. S-09 해결: RDS TLS 강제(사용자 지정 파라미터 그룹). S-10 해결: Redis 인증 토큰 사용. S-11(토큰을 Terraform에 넘기는 방법) 추가. 검증 항목 2개 추가 | 결정자 지정 (2026-11-12) |
| 0.14 | S-11 해결: Redis 인증 토큰은 RDS처럼 임시 값으로 만들고 구축 뒤 바꿈(ADR-009 예외 확대). 2.3절 자격 증명 표에 행 추가 | 결정자 지정 (2026-11-12) |
| 1.0 | 승인 | 박가온누리 승인 (2026-11-12) |
| 1.1 | 2.1절: ACM 인증서 요청은 Terraform, DNS 검증 CNAME은 Terraform 밖 수동. 2.2절: S3 아티팩트 버킷 이름 확정 | 결정자 지정 (2026-11-14) |
| 1.2 | network.md v1.3 반영: 1.1절 sg-log 서브넷을 private-app-a로 바꿈(private-log-a 삭제). 5절 검증 항목 2개(VPC CIDR `192.168.0.`, 같은 서브넷 안 SG 구분) 갱신. 보안 그룹 규칙은 바뀌지 않음. 선행 문서 버전 갱신. 승인 | network.md v1.3, 결정자 지정 (2026-11-14), 박가온누리 승인 (2026-11-15) |
| 1.3 | ADR-013(ADR-009 대체) 반영: 2.1절 Redis 구간 인증 토큰 없음, 2.3절 RDS 마스터 비밀번호는 RDS 관리형(Secrets Manager)·Redis 인증 토큰 없음, S-10 변경·S-11 해당 없음, 5절 검증 항목 1개 삭제·1개 추가·1개 수정. ADR-012 참조를 ADR-014로 바꿈. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), [ADR-013](../adr/ADR-013-secrets-managed-rds.md), [ADR-014](../adr/ADR-014-subnet-layout-8.md) |
| 1.4 | 01 v1.5 반영: 2.3절 Terraform 자격 증명을 루트 계정 `aws login`으로, GitHub Actions는 IAM 사용자 키로 나눔. 루트 액세스 키 없음·MFA(P-07)는 그대로. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), 00 v1.7, 01 v1.5 |

> **읽는 법**
> - 모든 설정값에 근거를 붙였다. 근거는 요구사항 ID, ADR, 또는 **"AWS 기본값/관례"**다.
> - 출발지·목적지를 보안 그룹으로 지정할 수 있는 규칙은 모두 **SG 참조**로 적었다. CIDR은 VPC 밖(인터넷, 운영자 PC)을 가리킬 때만 쓴다.
> - ADR에서 정하지 않은 규칙은 만들어 넣지 않았다. 표에 **미정**으로 표시하고 4절 "추가 결정 필요"에 대안과 함께 적었다.
> - 03에 없는 구성 요소는 넣지 않았다.

---

## 1. 보안 그룹 규칙

### 1.1 보안 그룹 목록

| SG | 붙는 곳 | 서브넷 | 근거 |
|---|---|---|---|
| sg-nlb | NLB | public-nlb-a | ADR-010, ADR-011, network.md N-03 |
| sg-alb | ALB (내부용) | private-alb-a, private-alb-b | ADR-003, ADR-010, ADR-011 |
| sg-app | 앱 서버 3대 (admin / b2b / b2c) | private-app-a | ADR-001, ADR-011 |
| sg-log | 로그 서버 (Loki + Grafana) | ~~private-log-a~~ private-app-a (앱 서버와 같은 서브넷, network.md N-05 변경) | ADR-006 |
| sg-bastion | Bastion | public-a | ADR-005 |
| sg-rds | RDS MySQL | private-db-a (서브넷 그룹: private-db-a, private-db-b) | ADR-008, ADR-011 |
| sg-redis | ElastiCache Redis | private-cache-a (서브넷 그룹: private-cache-a) | ADR-008, ADR-011 |

- NAT Gateway에는 보안 그룹을 붙일 수 없다(AWS 사양).
- 세 앱 서버는 같은 sg-app을 쓴다. 서비스마다 허용 규칙이 같기 때문이다(ADR-011 "앱 서버 EC2 (admin / b2b / b2c)"를 한 행으로 정함).
- NLB 보안 그룹은 NLB를 만들 때만 붙일 수 있고, 나중에 붙이거나 모두 뗄 수 없다(AWS 사양). 그래서 sg-nlb는 처음부터 만든다.

### 1.2 규칙

| SG | 방향 | 포트 | 출발지/목적지 | 근거 |
|---|---|---|---|---|
| sg-nlb | 인바운드 | TCP 443 | `0.0.0.0/0` | NFR-06, ADR-010, 결정자 지정(2026-11-12, 설계 리뷰 DR-02). 서비스 사용자가 인터넷 어디서나 접속(FR-02, FR-03). IPv6(`::/0`)는 쓰지 않는다 |
| sg-alb | 인바운드 | TCP 443 | sg-nlb | ADR-003("NLB에서 오는 트래픽만"), ADR-011 |
| sg-app | 인바운드 | TCP 8080 | sg-alb | ADR-011("ALB 보안 그룹에서 오는 앱 포트만"). 8080은 Spring Boot 기본값(CON-06) |
| sg-app | 인바운드 | TCP 22 | sg-bastion | FR-07, ADR-005, 결정자 지정(2026-11-12)(S-01) |
| sg-log | 인바운드 | TCP 3100 | sg-app | FR-09, ADR-006, 결정자 지정(2026-11-12)(S-02). 3100은 Loki 기본값 |
| sg-log | 인바운드 | TCP 3000 | sg-bastion | ADR-006(Bastion을 거친 SSH 터널), 결정자 지정(2026-11-12)(S-02). 3000은 Grafana 기본값 |
| sg-log | 인바운드 | TCP 22 | sg-bastion | FR-07, ADR-005, 결정자 지정(2026-11-12)(S-01) |
| sg-bastion | 인바운드 | TCP 22 | `<operator-ip>/32` | ADR-005(운영자 IP는 고정, 출발지 제한), 결정자 지정(2026-11-12, S-04). VPC 밖 출발지라 CIDR로 쓴다 |
| sg-rds | 인바운드 | TCP 3306 | sg-app, sg-bastion | ADR-011("앱 서버 3대와 Bastion에서 오는 MySQL 포트만"). 3306은 MySQL 기본값 |
| sg-redis | 인바운드 | TCP 6379 | sg-app, sg-bastion | ADR-011. 6379는 Redis 기본값 |
| sg-nlb | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-alb | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-app | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-log | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-bastion | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-rds | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |
| sg-redis | 아웃바운드 | 전체 | `0.0.0.0/0` | 결정자 지정(2026-11-12). AWS 기본값과 같음 |

- **아웃바운드 규칙에 대해:** 모든 보안 그룹의 아웃바운드는 **전체 포트, 전체 목적지를 허용한다**(결정자 지정, 2026-11-12, S-05 해결). AWS 기본값과 같다. 그래서 앱 서버 → RDS·Redis·Loki, ALB → 앱 서버, Bastion → 서버·DB 같은 연결은 **받는 쪽 인바운드 규칙만으로** 제어된다. 필요한 경로 목록은 [network.md](network.md) 5절에 있다.
- 보안 그룹은 상태를 기억한다(stateful). 허용한 연결의 응답 트래픽은 따로 허용하지 않아도 된다(AWS 사양). 그래서 응답용 규칙은 적지 않았다.

## 2. TLS 정책과 암호화 대상

### 2.1 TLS

| 구간 | TLS | 값 | 근거 |
|---|---|---|---|
| 사용자 → NLB | 종료하지 않음(TCP 그대로 전달) | NLB 리스너 TCP 443 | ADR-010 |
| NLB → ALB | 사용자와 ALB 사이 TLS가 그대로 지나감 | - | ADR-010 |
| ALB 리스너 | **TLS 종료** | HTTPS 443, ACM 인증서 | FR-02, ADR-003 |
| ALB 보안 정책 | TLS 1.2 이상, TLS 1.3 지원 | `ELBSecurityPolicy-TLS13-1-2-2021-06` | AWS 관례(콘솔에서 새 HTTPS 리스너의 권장 기본 정책). Terraform에서 정책을 비우면 더 오래된 기본 정책이 적용되므로 반드시 명시한다(확인 필요) |
| ACM 인증서 범위 | 와일드카드 1개 | `*.imcommerce.shop` | FR-02, CON-10, 결정자 지정(2026-11-12)(S-06). 서비스 도메인 3개를 모두 포함한다. 루트 도메인 `imcommerce.shop`은 포함하지 않는다(서비스 도메인이 아니므로 필요 없음) |
| ACM 검증 방식 | DNS 검증 | Route 53 레코드. 인증서 요청은 Terraform, 검증 CNAME은 Terraform 밖에서 운영자가 수동으로 만든다(network.md 4.5절) | ADR-003, CON-10. 자동 갱신 조건(FR-02). 결정자 지정(2026-11-14) |
| ALB → 앱 서버 | **암호화하지 않음** (HTTP 8080) | - | ADR-011("ALB가 TLS를 복호화하므로 ALB → 앱 서버 구간은 앱 포트(HTTP)"). VPC 안 구간이다 |
| 앱 서버 → RDS MySQL | ~~**암호화하지 않음**~~ **TLS 사용** | RDS 기본 인증서 | ~~결정자 지정(2026-11-12, 설계 리뷰 DR-07), S-07 (B).~~ 결정자 지정(2026-11-12, 설계 리뷰 K-03, DR-07 변경), S-07 (A). DB 쪽에서도 TLS를 강제한다. 사용자 지정 파라미터 그룹에 `require_secure_transport=ON`(결정자 지정(2026-11-12), S-09). TLS가 아닌 접속은 거부된다 |
| 앱 서버 → ElastiCache Redis | ~~**암호화하지 않음. 인증 토큰도 쓰지 않음**~~ **전송 중 암호화 사용** | ElastiCache 전송 중 암호화 | 결정자 지정(2026-11-12, 설계 리뷰 K-03, DR-07 변경), S-07 (A). ~~인증 토큰을 쓴다. 값은 Secret 파일에 둔다(결정자 지정(2026-11-12), S-10, ADR-009)~~ 인증 토큰은 쓰지 않는다. 접근은 sg-redis로만 제한한다(결정자 지정(2026-11-15), S-10 변경, ADR-013) |
| 운영자 → Bastion → 서버 | SSH | SSH 키 인증 | ADR-005 |
| 앱 서버(Alloy) → 로그 서버(Loki) | **암호화하지 않음** (HTTP 3100) | - | VPC 안 구간, SG로만 제어(sg-log ← sg-app). 설계 리뷰 DR-24 |
| Bastion → 로그 서버(Grafana) | 운영자 PC → Bastion 구간은 SSH 터널로 암호화. Bastion → 로그 서버 구간은 **암호화하지 않음** (HTTP 3000) | - | ADR-006, VPC 안 구간, SG로만 제어(sg-log ← sg-bastion). DR-24 |
| Bastion → RDS MySQL·ElastiCache Redis | ~~**암호화하지 않음**~~ Redis는 **TLS 필수**(전송 중 암호화를 켜면 클라이언트도 TLS로 접속해야 함). MySQL은 TLS 사용 | - | 결정자 지정(2026-11-12, 설계 리뷰 K-03, DR-07 변경), DR-24. FR-04 검증 명령의 `redis-cli`에 `--tls` 옵션이 필요하다 |

### 2.2 저장 데이터 암호화

| 대상 | 암호화 | 근거 |
|---|---|---|
| S3 아티팩트 버킷 (`commerce-prod-codedeploy-artifacts`, 결정자 지정(2026-11-14)) | 켬. SSE-S3 | AWS 기본값(2023년부터 모든 새 객체에 SSE-S3 적용) |
| S3 퍼블릭 액세스 차단 | 4개 설정 모두 켬 | AWS 기본값(새 버킷). NFR-06 |
| S3 버전 관리 | 켬 | 결정자 지정(2026-11-12, 설계 리뷰 K-02). 이전 아티팩트를 남겨 수동 재배포(NFR-08)에 쓴다. 버전이 남은 버킷은 `terraform destroy`로 지워지지 않으므로, **삭제 전에 모든 객체와 이전 버전을 수동으로 비우는 절차를 05에 넣는다**(결정자 지정, Q-04) |
| RDS 스토리지 | 켬. AWS 관리형 키 | 결정자 지정(2026-11-12, 설계 리뷰 DR-09), S-08 (A). 만들 때만 정할 수 있다(AWS 사양) |
| ElastiCache 저장 데이터 | 켬. AWS 관리형 키 | 결정자 지정(2026-11-12, 설계 리뷰 DR-09), S-08 (A). 만들 때만 정할 수 있다(AWS 사양) |
| EBS 볼륨 (앱·로그 서버, Bastion) | 켬. AWS 관리형 키 | 결정자 지정(2026-11-12, 설계 리뷰 DR-09), S-08 (A). 계정 기본값은 꺼짐이므로 명시한다(AWS 기본값과 다름) |
| Terraform State (운영자 PC) | 암호화하지 않음 | CON-11, Q-31(운영자 개인 PC에 둠). 보호 수단은 정하지 않았다 |
| Secret 파일 (앱 서버 안) | 평문 | ADR-013(파일 권한으로 제한). 넣는 방법은 Terraform 범위 밖에서 정한다(결정자 지정(2026-11-12, 설계 리뷰 DR-11)) |

### 2.3 자격 증명

| 항목 | 값 | 근거 |
|---|---|---|
| Terraform·GitHub Actions 자격 증명 | ~~별도 IAM 사용자의 액세스 키 1개를 함께 씀~~ GitHub Actions는 별도 IAM 사용자의 액세스 키. Terraform은 운영자 PC에서 루트 계정으로 `aws login`(임시 자격 증명, 루트 액세스 키 없음) | NFR-07, CON-13 (01 v1.5), 결정자 지정(2026-11-15) |
| 루트 계정 | 액세스 키 없음, MFA 켬 | NFR-07, Q-28 |
| 코드의 액세스 키 | 넣지 않는다. 필요한 위치에 주석만 남기고 실행 직전에 넣는다 | FR-11 (R-02 결정) |
| RDS 마스터 비밀번호 | ~~임시 비밀번호로 만들고 구축 뒤 운영자가 바꾼다. 변수로 넘기며 코드에 쓰지 않는다~~ RDS 관리형 비밀번호(`manage_master_user_password = true`). RDS가 만들어 Secrets Manager 시크릿에 둔다. Terraform 코드·변수·State에 없다. 운영자가 Secrets Manager에서 읽어 Secret 파일에 넣는다 | ADR-013, 결정자 지정(2026-11-15) |
| Redis 인증 토큰 | ~~임시 토큰으로 만들고 구축 뒤 운영자가 바꾼다. 변수로 넘기며 코드에 쓰지 않는다. 바꾼 값은 Secret 파일에 둔다~~ 쓰지 않는다 | ADR-013, 결정자 지정(2026-11-15, S-10 변경) |

## 3. 명시적 금지 사항

| ID | 금지 사항 | 근거 |
|---|---|---|
| P-01 | **SSH 22를 `0.0.0.0/0`에 열지 않는다.** 22번 포트 인바운드는 sg-bastion의 `<operator-ip>/32`(운영자 공인 IP)만 허용한다. 프라이빗 서버(sg-app, sg-log)의 22번은 sg-bastion만 출발지로 둔다(S-01) | NFR-06, ADR-005 |
| P-02 | **`0.0.0.0/0` 인바운드는 아래 예외 목록 말고는 두지 않는다** | NFR-06 |
| P-03 | HTTP 80 인바운드 리스너와 규칙을 두지 않는다. HTTPS로 넘기는 리디렉션도 두지 않는다 | NFR-06, Q-27 |
| P-04 | 프라이빗 서브넷 리소스(앱 서버, 로그 서버, ALB, RDS, ElastiCache)에 공인 IP를 주지 않는다. RDS의 "퍼블릭 액세스 가능"은 끈다 | FR-05, NFR-06, ADR-010 |
| P-05 | VPC 안을 가리키는 규칙에 CIDR을 쓰지 않는다. SG 참조로만 쓴다 | 사용자 지시, AWS 관례(서버를 다시 만들어 IP가 바뀌어도 규칙이 유지됨) |
| P-06 | ALB를 인터넷 연결형으로 만들지 않는다 | ADR-010 |
| P-07 | 루트 계정의 액세스 키를 만들지 않는다 | NFR-07, Q-28 |
| P-08 | 액세스 키와 비밀번호를 Terraform 코드와 Git 저장소에 쓰지 않는다 | FR-11, ADR-013 |
| P-09 | S3 아티팩트 버킷을 공개하지 않는다(퍼블릭 액세스 차단을 끄지 않는다) | NFR-06 |

### `0.0.0.0/0` 인바운드 예외 목록

| SG | 포트 | 이유 | 근거 | 상태 |
|---|---|---|---|---|
| sg-nlb | TCP 443 | 서비스 사용자(admin / b2b / b2c)가 인터넷 어디서나 접속한다 | NFR-06, FR-02, FR-03, 01 6.1(00 3.3 admin 외부 공개 허용, Q-S-04) | 확정 (S-03, DR-02) |

- 이 목록 말고는 `0.0.0.0/0` 인바운드가 없어야 한다. 아웃바운드의 `0.0.0.0/0`(1.2절)은 이 목록에 들어가지 않는다.

## 4. 추가 결정 필요

| ID | 항목 | 대안 | 왜 필요한가 | 관련 요구사항 |
|---|---|---|---|---|
| S-01 | ~~앱 서버·로그 서버가 Bastion에서 오는 SSH를 받는 규칙~~ **해결(2026-11-12)**: (A) sg-app·sg-log 22 ← sg-bastion | (A) sg-app·sg-log 인바운드 22를 sg-bastion에서 허용 (B) 서버 SSH는 막고 DB·캐시 접속만 Bastion에서 함 | ADR-011 표에 없다. 없으면 운영자가 서버에 접속할 수 없어 **FR-07을 충족하지 못한다** | FR-07 |
| S-02 | ~~로그 서버의 인바운드 규칙~~ **해결(2026-11-12)**: (A) 3100 ← sg-app, 3000 ← sg-bastion | (A) 3100은 sg-app에서, 3000은 sg-bastion에서 허용 (B) Grafana는 로그 서버 안에서만 열고, SSH 터널(22)로만 접근 | ADR-011 표에 없다. 없으면 로그가 모이지 않아 **FR-09를 충족하지 못한다** | FR-09, NFR-09 |
| S-03 | ~~NLB 인바운드 출발지 범위~~ **해결(2026-11-12)**: (A) `0.0.0.0/0` (DR-02) | (A) `0.0.0.0/0` (B) 협력사 IP만 | (B)를 고르면 서비스 사용자가 접속할 수 없다(FR-02, FR-03). 결정이 없으면 예외 목록을 확정할 수 없다 | NFR-06, FR-02, FR-03 |
| S-04 | ~~Bastion에 허용할 운영자 공인 IP 값~~ **해결(2026-11-12)**: `<operator-ip>/32` | - | ADR-005는 IP가 고정이라고만 적었다(03 X-03). 값이 없으면 sg-bastion을 만들 수 없다 | NFR-06, FR-07 |
| S-05 | ~~아웃바운드 기본 규칙~~ **해결(2026-11-12)**: 전체 허용 | ~~(A) AWS 기본값(전체 허용) 유지 (B) 1.2절의 최소 경로만 남김~~ (A)와 같음 | 결정자가 "아웃바운드 포트는 전체 열어둔다"로 정했다. 1.2절에 반영 | NFR-06, FR-05 |
| S-06 | ~~ACM 인증서 이름 범위~~ **해결(2026-11-12)**: (B) `*.imcommerce.shop` 와일드카드 1개 | (A) 서비스 도메인 3개를 이름으로 넣음 (B) `*.imcommerce.shop` 와일드카드 1개 | 둘 다 FR-02를 충족한다. (B)는 다른 서브도메인에도 쓸 수 있어 범위가 넓다 | FR-02 |
| S-07 | ~~앱 서버 → RDS·Redis 구간 TLS~~ **해결(2026-11-12)**: ~~(B) 켜지 않음. Redis 인증 토큰도 쓰지 않음 (DR-07)~~ (A) 전송 암호화 켬 (K-03에서 DR-07을 바꿈) | (A) 둘 다 TLS 켬 (B) 켜지 않음(VPC 안 구간) | ElastiCache 전송 중 암호화는 만들 때만 켤 수 있다(AWS 사양). ADR-009 후속 조치(Redis 인증 토큰)와 함께 정해야 한다 | FR-04 |
| S-09 | ~~RDS에서 TLS를 강제할지~~ **해결(2026-11-12)**: (A) 사용자 지정 파라미터 그룹에 `require_secure_transport=ON` | (A) 사용자 지정 파라미터 그룹에 `require_secure_transport=ON` (B) 강제하지 않음(앱이 TLS로 접속) | (A)면 data.md의 파라미터 그룹 "기본"을 바꿔야 한다. K-03은 "전송 암호화를 켠다"까지만 정했다 | FR-04 |
| S-10 | ~~Redis 인증 토큰을 쓸지~~ ~~**해결(2026-11-12)**: (A) 쓴다(값은 Secret 파일, ADR-009)~~ **변경(2026-11-15)**: (B) 쓰지 않는다. 전송 중 암호화는 유지(ADR-013) | (A) 쓴다(값은 Secret 파일, ADR-009) (B) 쓰지 않는다 | 전송 중 암호화를 켜서 쓸 수 있게 됐다(K-03). 만들 때 정해야 한다(AWS 사양, 확인 필요) | FR-04 |
| S-11 | ~~Redis 인증 토큰을 Terraform에 넘기는 방법~~ ~~**해결(2026-11-12)**: (A) 임시 토큰으로 만들고 구축 뒤 바꾼다(ADR-009 예외를 Redis로 넓힘)~~ **해당 없음(2026-11-15)**: 토큰을 쓰지 않는다(S-10 변경, ADR-013) | (A) RDS처럼 임시 토큰으로 만들고 구축 뒤 바꾼다(ADR-009 예외를 Redis로 넓힘) (B) 처음부터 실제 토큰을 변수로 넘긴다(State에 평문으로 남음) | 인증 토큰은 ElastiCache를 만들 때 지정해야 한다(AWS 사양, 확인 필요). ADR-009는 "비밀값은 Terraform 구축 단계에서 넣지 않는다"고 정했고 예외는 RDS 임시 비밀번호뿐이다 | FR-04, ADR-009 |
| S-08 | ~~저장 데이터 암호화 (RDS, ElastiCache, EBS)~~ **해결(2026-11-12)**: (A) AWS 관리형 키로 모두 켬 (DR-09) | (A) AWS 관리형 키로 모두 켬 (B) 켜지 않음 | 모두 만들 때 정해야 한다. 관리형 키는 추가 요금이 없다(추정치) | NFR-14, CON-02 |

## 5. 검증 항목

| 설계 항목 | 검증 방법 (명령어/도구) | 관련 요구사항 |
|---|---|---|
| 진입점에 열린 포트가 443 하나다 | 외부 PC에서 NLB EIP에 `nmap -Pn -p- <NLB EIP>`를 실행하면 열린 포트가 `443/tcp` 하나다 | NFR-06 |
| HTTP 80을 받지 않는다 | 도메인 3개 각각 `curl -m 5 -s -o /dev/null -w '%{http_code}' http://<도메인>/` 결과가 `000` | NFR-06, Q-27 |
| `0.0.0.0/0` 인바운드가 예외 목록에만 있다 | `aws ec2 describe-security-groups --filters Name=vpc-id,Values=<VPC ID> Name=ip-permission.cidr,Values=0.0.0.0/0 --query 'SecurityGroups[].GroupName'` 결과가 `sg-nlb`뿐이다 | NFR-06, P-02 |
| SSH 22가 인터넷 전체에 열려 있지 않다 | `aws ec2 describe-security-groups --filters Name=vpc-id,Values=<VPC ID> Name=ip-permission.from-port,Values=22 Name=ip-permission.cidr,Values=0.0.0.0/0 --query 'SecurityGroups[].GroupName'` 결과가 비어 있다 | NFR-06, P-01 |
| 모든 SG의 아웃바운드가 전체 허용이다 | `aws ec2 describe-security-groups --filters Name=vpc-id,Values=<VPC ID> --query 'SecurityGroups[].[GroupName,IpPermissionsEgress[].[IpProtocol,IpRanges[].CidrIp]]'` 결과가 SG마다 `-1`, `0.0.0.0/0` | S-05 |
| VPC 안 규칙이 SG 참조로 돼 있다 | `aws ec2 describe-security-groups --group-ids <sg-alb> <sg-app> <sg-log> <sg-rds> <sg-redis> --query 'SecurityGroups[].IpPermissions[].[FromPort,UserIdGroupPairs[].GroupId,IpRanges[].CidrIp]'` 결과에 ~~`10.0.`~~ `192.168.0.` CIDR이 없다 | P-05 |
| Bastion SSH는 운영자 IP에서만 받는다 | `aws ec2 describe-security-groups --group-ids <sg-bastion> --query 'SecurityGroups[].IpPermissions[?FromPort==\`22\`].IpRanges[].CidrIp'` 결과가 `<operator-ip>/32`뿐이다. 운영자 PC에서 `ssh <Bastion 공인 IP>` 성공, 다른 회선(예: 휴대폰 테더링)에서는 연결 시간 초과 | NFR-06, FR-07, S-04 |
| 서버 SSH는 Bastion에서만 받는다 | `<sg-app>`, `<sg-log>`의 22번 규칙 출발지가 `<sg-bastion>`뿐이다. Bastion에서 `ssh <앱 서버 사설 IP>` 성공, 외부 PC에서 같은 IP로는 경로가 없다 | FR-07, P-01, S-01 |
| 로그 서버는 앱 서버의 3100, Bastion의 3000만 받는다 | `<sg-log>`의 3100 출발지가 `<sg-app>`, 3000 출발지가 `<sg-bastion>`이다. 앱 서버에서 `nc -zv -w 3 <로그 서버> 3100` 성공. 운영자 PC에서 `ssh -L 3000:<로그 서버>:3000 <Bastion>` 뒤 `curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/login` 결과가 `200` | FR-09, ADR-006, S-02 |
| ALB는 NLB에서만 받는다 | `aws ec2 describe-security-groups --group-ids <sg-alb> --query 'SecurityGroups[].IpPermissions[].UserIdGroupPairs[].GroupId'` 결과가 `<sg-nlb>`뿐이다 | NFR-06, ADR-003 |
| ~~계층별 서브넷이 나뉘어도~~ 같은 서브넷 안에서도 SG 참조로만 통신한다 | 앱 서버(private-app-a, sg-app)에서 `nc -zv -w 3 <RDS 주소> 3306` 성공, 같은 서브넷의 로그 서버(~~private-log-a~~ private-app-a, sg-log)에서 같은 명령 실패. 허용은 서브넷이 아니라 SG로 갈린다 | P-05, ADR-011 |
| 앱 서버는 ALB에서만 8080을 받는다 | `<sg-app>`에 같은 명령을 실행해 8080 규칙의 출발지가 `<sg-alb>`뿐이다 | NFR-06, ADR-011 |
| MySQL·Redis는 앱 서버와 Bastion에서만 받는다 | `<sg-rds>`, `<sg-redis>`의 출발지가 `<sg-app>`, `<sg-bastion>` 두 개뿐이다. 로그 서버에서 `nc -zv -w 3 <RDS 주소> 3306`이 실패한다 | FR-04, ADR-011 |
| Bastion에서 MySQL·Redis에 접속된다 | Bastion에서 `mysql -h <RDS 주소> -u <사용자> -p -e 'SELECT 1'` 성공, `redis-cli -h <Redis 주소> --tls PING` 결과 `PONG`(인증 토큰 없음, S-10 변경). MySQL 비밀번호는 Secrets Manager에서 읽는다(ADR-013) | FR-04, NFR-14 |
| 인터넷에서 서버·DB에 직접 닿지 않는다 | 외부 PC에서 `nc -zv -w 3 <NLB EIP> 22`, `nc -zv -w 3 <NLB EIP> 3306`이 실패한다. 서버·RDS·ElastiCache에 공인 IP가 없다(network.md 7절) | NFR-06 |
| RDS가 공개되지 않는다 | `aws rds describe-db-instances --db-instance-identifier <ID> --query 'DBInstances[].PubliclyAccessible'` 결과가 `false` | NFR-06, P-04 |
| ALB TLS 정책이 2.1절과 같다 | `aws elbv2 describe-listeners --load-balancer-arn <ALB ARN> --query 'Listeners[].[Port,Protocol,SslPolicy]'` 결과가 `443`, `HTTPS`, `ELBSecurityPolicy-TLS13-1-2-2021-06`. 80 리스너가 없다 | FR-02, NFR-06 |
| TLS 1.2 이상만 받는다 | `nmap --script ssl-enum-ciphers -p 443 <도메인>` 결과에 `TLSv1.2`, `TLSv1.3`만 있고 `TLSv1.0`, `TLSv1.1`이 없다. `openssl s_client -connect <도메인>:443 -servername <도메인> -tls1_2 </dev/null`이 성공한다. ~~`-tls1_1` 실패로 판정~~(OpenSSL 3.x는 클라이언트가 TLS 1.1을 기본으로 쓰지 않아 거짓 통과 가능, DR-25) | FR-02, DR-25 |
| 인증서가 유효하다 | 도메인 3개 각각 브라우저나 `curl -sS https://<도메인>/signup -o /dev/null -w '%{http_code}'`로 인증서 오류 없이 접속된다 | FR-02 |
| ACM 인증서가 DNS 검증으로 발급됐다 | `aws acm describe-certificate --certificate-arn <ARN> --query 'Certificate.[DomainName,Status,DomainValidationOptions[].ValidationMethod]'` 결과가 `*.imcommerce.shop`, `ISSUED`, `DNS` | FR-02, S-06 |
| RDS가 TLS가 아닌 접속을 거부한다 | Bastion에서 `mysql -h <RDS 주소> -u <사용자> -p --ssl-mode=DISABLED -e 'SELECT 1'`이 실패하고, `--ssl-mode=REQUIRED`는 성공한다. `SHOW VARIABLES LIKE 'require_secure_transport'` 결과가 `ON` | FR-04, S-09 |
| ~~Redis가 인증 토큰 없이는 응답하지 않는다~~ **삭제(2026-11-15)** | ~~Bastion에서 `redis-cli -h <Redis 주소> --tls PING` 결과가 `NOAUTH` 오류, `-a <인증 토큰>`을 주면 `PONG`~~ 인증 토큰을 쓰지 않는다(S-10 변경, ADR-013) | FR-04, S-10 |
| RDS 마스터 비밀번호가 Secrets Manager에서 관리된다 | `aws rds describe-db-instances --db-instance-identifier <ID> --query 'DBInstances[].MasterUserSecret.[SecretArn,SecretStatus]'` 결과에 시크릿 ARN과 `active`가 있다. Terraform 코드에 RDS `password` 인자가 없다 | ADR-013, P-08 |
| S3 버킷 공개가 막혀 있다 | `aws s3api get-public-access-block --bucket <버킷>` 결과의 4개 값이 모두 `true` | NFR-06, P-09 |
| RDS·ElastiCache·EBS 저장 암호화가 켜져 있다 | `aws rds describe-db-instances --query 'DBInstances[].StorageEncrypted'`, `aws elasticache describe-replication-groups --query 'ReplicationGroups[].AtRestEncryptionEnabled'`(또는 클러스터 조회), `aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=<ID> --query 'Volumes[].Encrypted'` 결과가 모두 `true` | S-08, DR-09 |
| S3 버전 관리가 켜져 있다 | `aws s3api get-bucket-versioning --bucket <버킷>` 결과의 `Status`가 `Enabled` | NFR-08, K-02 |
| S3 기본 암호화가 켜져 있다 | `aws s3api get-bucket-encryption --bucket <버킷>` 결과에 `AES256` | 2.2절 |
| 루트 계정에 액세스 키가 없고 MFA가 켜져 있다 | `aws iam get-account-summary --query 'SummaryMap.[AccountAccessKeysPresent,AccountMFAEnabled]'` 결과가 `[0, 1]` | NFR-07 |
| 코드와 저장소에 비밀값이 없다 | 저장소에서 `git grep -nE 'AKIA[0-9A-Z]{16}'`와 `git grep -n 'password'` 결과에 실제 값이 없다 | FR-11, P-08 |
