# 04-design / network.md — 네트워크 상세 설계

| 항목 | 값 |
|---|---|
| 상태 | Approved |
| 버전 | 1.7 |
| 날짜 | 2026-11-15 |
| 작성자 | 박가온누리 |
| 선행 문서 | [01-requirements.md](../01-requirements.md) v1.6 (Approved), [03-architecture.md](../03-architecture.md) v1.10 (Approved), [adr/](../adr/) ADR-001~ADR-014 (Accepted. ADR-007·ADR-009·ADR-012는 대체됨) |

### 변경 이력

| 버전 | 변경 내용 | 근거 |
|---|---|---|
| 0.1 | 최초 작성 | 03 v1.2, ADR-001~ADR-011 |
| 0.2 | 5.1 서비스 사용자 경로에서 IGW 표기 삭제(사용자 지시). N-04 해결(아웃바운드 전체 허용) | 사용자 지시 (2026-11-12) |
| 0.3 | N-02 해결: S3 VPC 엔드포인트 두지 않음, 공인 엔드포인트로 접근. N-03 해결: NLB를 AZ-A 하나에만 두고 EIP 1개. public-b는 리소스 없이 남김. 2, 3, 4, 5, 6, 7절 갱신 | 결정자 지정 (2026-11-12) |
| 0.4 | 결정자가 준 구성도를 반영해 서브넷을 용도별로 나눔(퍼블릭 3개, 프라이빗 6개). VPC 대역 `10.0.0.0/16`은 유지. 2, 3, 4.2, 4.4, 5, 6, 7절 갱신 | 결정자 구성도 (2026-11-12) |
| 0.5 | N-05 해결: 로그 서버를 별도 프라이빗 서브넷(private-log-a)에 둠. N-06 해결: ElastiCache 서브넷 그룹은 서브넷 하나. 2, 3, 5, 6, 7절 갱신 | 결정자 지정 (2026-11-12) |
| 0.6 | N-07 해결: 03은 AZ 단위로 서브넷을 그리고, 용도별 세부 서브넷은 04에만 둔다. 03은 고치지 않음 | 결정자 지정 (2026-11-12) |
| 0.7 | N-01 해결: AZ-A에서 사용할 인스턴스 유형 제공을 결정자가 확인함(compute.md C-05) | 결정자 확인 (2026-11-12) |
| 0.8 | 5절 경로의 "허용 미정" 표기를 security.md S-01·S-02 해결로 바꿈 | security.md v0.6 |
| 0.9 | 설계 리뷰 결정 반영: NLB → ALB 상태 확인 HTTPS 443·경로 `/`·정상 코드 404, ALB 기본 동작 고정 응답 404, FR-13 검증을 ALB 대상 그룹 3개 조회로 바꿈(DR-05). 4.5 DNS 절 추가(DR-17). 검증 항목 3개 추가 | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.10 | 설계 리뷰 결정 반영: 선행 문서 버전 수정(DR-18), ALB 대상 그룹 상태 확인 값 표 추가(DR-26), 7절 검증 항목 이름 변경·N-07 서브넷 개수 수정(DR-27) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.11 | 01 v1.4에서 FR-12가 삭제돼 근거를 00 종료 처리(Q-04)로 바꿈(1곳). 선행 문서 버전 갱신 | 01 v1.4 FR-12 삭제 (결정자 지정, 2026-11-12) |
| 0.12 | ADR-007이 ADR-012로 대체돼(설계 리뷰 DR-15) 근거 참조를 ADR-012로 바꿈. 내용 변경 없음 | [ADR-012](../adr/ADR-012-subnet-layout.md), 결정자 지시 (2026-11-12) |
| 1.0 | 승인 | 박가온누리 승인 (2026-11-12) |
| 1.2 | 4.4절: NLB 교차 영역 로드 밸런싱을 끄고(명시), NLB(AZ-A)와 같은 AZ에 ALB 서브넷(private-alb-a)을 둔다. 4.5절: ACM DNS 검증 CNAME도 Terraform 밖에서 수동으로 만들고 지운다. Terraform은 호스팅 영역만 만든다 | 결정자 지정 (2026-11-14) |
| 1.3 | VPC 대역을 `192.168.0.0/24`로, 서브넷을 구성도의 /27 8개로 바꿈. public-b 삭제, 로그 서버를 private-app-a로 옮기고 private-log-a 삭제(N-05 변경). 예비 대역 없음. N-08 추가·해결(ElastiCache 서브넷 하나만 사용). 1.1, 2, 3, 5, 6, 7절 갱신. 선행 문서 03 v1.7 반영. 승인 | 결정자 지정 (2026-11-14), 박가온누리 승인 (2026-11-15) |
| 1.4 | ADR-012가 ADR-014로 대체돼(05 AI-08) 근거 참조를 ADR-014로 바꿈. 내용 변경 없음. 선행 문서 버전 갱신 | [ADR-014](../adr/ADR-014-subnet-layout-8.md), 결정자 지정 (2026-11-15) |
| 1.5 | 선행 문서 버전 갱신(00 v1.7·01 v1.5 NFR-07 변경, 03 v1.9). 내용 변경 없음 | 결정자 지정 (2026-11-15), 00 v1.7, 01 v1.5 |
| 1.6 | 4.5절: 도메인 등록기관을 가비아에서 Route 53 Domains(이 AWS 계정)로 바꿈(Q-37). 도메인 등록 행 추가, 네임서버 위임 행을 Route 53 Domains 네임서버 변경과 자동 생성 호스팅 영역 삭제로 바꿈. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15, Q-37), 00 v1.8, 01 v1.6, 03 v1.10 |
| 1.7 | 5.3절: NLB → ALB 대상 그룹 상태 확인의 간격·타임아웃·임계값 표 추가(AWS 기본값). 4.4·5.3절 "확인 필요" 2곳에 AWS 문서 확인 결과를 적음(동작 확인은 7단계 apply 뒤) | 결정자 지정 (2026-11-15, 05 7단계 구현 질문), [ai-log](../../ai-log/ai-decisions.md) |
| 1.1 | 4.5절: 서비스 A 레코드 3개는 Terraform 밖에서 운영자가 수동으로 만들고, 삭제할 때도 `terraform destroy` 전에 수동으로 지운다. 호스팅 영역은 그대로 Terraform으로 만들고 지운다 | 결정자 지정 (2026-11-14), [05](../05-implementation-plan.md) R-19 |

> **읽는 법**
> - 모든 설정값에 근거를 붙였다. 근거는 요구사항 ID, ADR, 또는 **"AWS 기본값/관례"**다.
> - 03에 없는 구성 요소는 넣지 않았다. 필요해 보이는 것은 6절 "추가 결정 필요"에 적었다.
> - 보안 그룹 규칙은 [security.md](security.md)에 있다. 이 문서에서는 경로만 다룬다.
> - 03의 AZ-A(인스턴스를 모으는 AZ), AZ-B(다른 AZ) 이름을 그대로 쓰고, 실제 AZ 이름은 1.2절에서 정한다.

---

## 1. VPC와 AZ

### 1.1 VPC

| 항목 | 값 | 근거 |
|---|---|---|
| 리전 | `ap-northeast-2` | NFR-02, CON-04 |
| VPC 수 | 1 | CON-05, 03 3절 |
| VPC CIDR | `192.168.0.0/24` (주소 256개) | 결정자 지정(2026-11-14). RFC 1918 사설 대역. 다른 네트워크와 연결할 계획이 없어 겹침을 고려하지 않음(Q-S-05 거래처 연동 범위 밖) |
| DNS 확인(enableDnsSupport) | 켬 | AWS 기본값. RDS·ElastiCache 엔드포인트 이름을 VPC 안에서 해석해야 함(FR-04) |
| DNS 호스트 이름(enableDnsHostnames) | 켬 | AWS 관례. 기본값은 꺼짐이지만 VPC 엔드포인트와 RDS 이름 해석에 쓰임 |
| IPv6 | 쓰지 않음 | 03에 IPv6 구성 요소가 없음 |

### 1.2 AZ

| 03 이름 | 실제 AZ | 근거 |
|---|---|---|
| AZ-A | `ap-northeast-2a` | ADR-014(한 AZ에 모으기). AZ 선택 자체는 AWS 관례(첫 번째 AZ). 구축 전 사용할 인스턴스 유형이 이 AZ에서 제공되는지 확인한다(6절 N-01) |
| AZ-B | `ap-northeast-2c` | NFR-03, Q-06(AZ 2개). AWS 관례: 2a와 물리적으로 떨어진 AZ를 고름. 인스턴스는 두지 않음(ADR-014) |

## 2. CIDR 계획

> 결정자가 준 서브넷 표(2026-11-14)를 따랐다. VPC `192.168.0.0/24`를 /27 8개로 나눠 모두 쓴다.

| 서브넷 | 종류 | AZ | CIDR | 사용 가능 IP | 배치 리소스 | 근거 |
|---|---|---|---|---|---|---|
| public-a | 퍼블릭 | AZ-A | `192.168.0.0/27` | 27 | Bastion, NAT Gateway | ADR-005, ADR-004, ADR-014, 결정자 지정(2026-11-14) |
| public-nlb-a | 퍼블릭 | AZ-A | `192.168.0.128/27` | 27 | NLB(EIP 1개) | ADR-010, N-03, 결정자 지정(2026-11-14) |
| private-alb-a | 프라이빗 | AZ-A | `192.168.0.64/27` | 27 | ALB 노드 | ADR-010, AWS 요구사항(ALB는 AZ 2개 이상) |
| private-alb-b | 프라이빗 | AZ-B | `192.168.0.224/27` | 27 | ALB 노드 | ADR-010, NFR-03 |
| private-app-a | 프라이빗 | AZ-A | `192.168.0.32/27` | 27 | 앱 서버 3대(admin / b2b / b2c), **로그 서버(Loki + Grafana)** | ADR-001, ADR-006, ADR-014, 결정자 지정(2026-11-14, N-05 변경) |
| private-db-a | 프라이빗 | AZ-A | `192.168.0.192/27` | 27 | RDS MySQL | ADR-008, ADR-014 |
| private-db-b | 프라이빗 | AZ-B | `192.168.0.96/27` | 27 | 없음(RDS 서브넷 그룹용) | AWS 요구사항(RDS 서브넷 그룹은 AZ 2개 필요) |
| private-cache-a | 프라이빗 | AZ-A | `192.168.0.160/27` | 27 | ElastiCache Redis | ADR-008, ADR-014 |

- **예비 대역 없음.** /27 8개가 `192.168.0.0/24`를 모두 쓴다. 서브넷을 더 만들려면 VPC에 보조 CIDR을 붙이거나 기존 서브넷을 다시 나눠야 한다(N-08).
- 서브넷마다 AWS가 IP 5개를 예약하므로 /27의 사용 가능 IP는 27개다(AWS 기본값).
- ALB는 서브넷마다 최소 /27과 남는 IP 8개가 필요하다(AWS 요구사항). private-alb-a·b는 /27이고 ALB 외 리소스를 두지 않아 이 조건을 채운다.
- private-app-a에는 서버 4대(앱 3, 로그 1)가 들어가 IP 23개가 남는다.
- **RDS 서브넷 그룹:** private-db-a와 private-db-b를 넣는다. 인스턴스는 private-db-a에만 만든다(ADR-008 Single-AZ, ADR-014).
- **ElastiCache 서브넷 그룹:** private-cache-a 하나만 넣는다(결정자 지정, N-06 해결). ElastiCache 서브넷 그룹은 서브넷 하나로도 만들 수 있다고 알고 있지만 확인하지 못했다. AZ-B 캐시 서브넷은 만들지 않는다(결정자 지정 2026-11-14, N-08 해결).
- **로그 서버:** 앱 서버와 같은 private-app-a에 둔다(결정자 지정, 2026-11-14). 앱 서버와의 접근 구분은 서브넷이 아니라 보안 그룹(sg-log)으로 한다(security.md P-05). AZ-A에 둔다(ADR-014).
- 퍼블릭 서브넷 2개는 "공인 IP 자동 할당"을 켠다. Bastion이 공인 IP를 받아야 한다(ADR-005). 프라이빗 서브넷 6개는 끈다(FR-05, NFR-06).

## 3. 라우팅 테이블

| 라우팅 테이블 | 연결 서브넷 | 대상 | 다음 홉 | 근거 |
|---|---|---|---|---|
| rt-public | public-a, public-nlb-a | `192.168.0.0/24` | local | AWS 기본값 |
| rt-public | public-a, public-nlb-a | `0.0.0.0/0` | 인터넷 게이트웨이 | ADR-011 |
| rt-private | private-alb-a, private-alb-b, private-app-a, private-db-a, private-db-b, private-cache-a | `192.168.0.0/24` | local | AWS 기본값 |
| rt-private | 위와 같음 | `0.0.0.0/0` | NAT Gateway (public-a) | ADR-011, ADR-004 |

- 프라이빗 라우팅 테이블은 하나만 둔다. NAT Gateway가 AZ-A에 하나뿐이므로 AZ-B 프라이빗 서브넷도 같은 NAT Gateway로 나간다(ADR-011, ADR-014). AZ-A에 장애가 나면 아웃바운드가 모두 끊기는 것을 받아들인다(00 3.2).
- DB·캐시 서브넷도 rt-private에 연결한다. RDS와 ElastiCache가 먼저 바깥으로 연결을 여는 일은 없지만, 라우팅 테이블을 따로 두지 않아 관리할 대상을 줄인다(CON-02, AWS 관례).
- VPC의 기본(main) 라우팅 테이블에는 서브넷을 연결하지 않는다. 모든 서브넷을 위 두 테이블 중 하나에 명시적으로 연결한다(AWS 관례: 연결 누락으로 의도치 않은 경로가 생기는 것을 막음).
- S3 게이트웨이 엔드포인트 경로는 넣지 않는다. 엔드포인트를 두지 않기로 했다(4.3절, N-02 해결).

## 4. NAT, IGW, VPC 엔드포인트

### 4.1 인터넷 게이트웨이

| 항목 | 값 | 근거 |
|---|---|---|
| 사용 | 예, VPC에 1개 | ADR-011 |
| 쓰는 곳 | NLB 인바운드, NAT Gateway·Bastion의 인터넷 통신 | ADR-011, ADR-010, ADR-005 |
| 요금 | 없음 | AWS 요금 정책 (추정, 02 2.1절 기준) |

### 4.2 NAT Gateway

| 항목 | 값 | 근거 |
|---|---|---|
| 사용 | 예, 1개 | ADR-004 |
| 위치 | public-a | ADR-014(AZ-A에 모으기), AWS 요구사항(퍼블릭 NAT Gateway는 퍼블릭 서브넷에 둠) |
| 연결 방식 | 퍼블릭 | ADR-004. 인터넷 아웃바운드가 필요함(FR-05) |
| EIP | 1개. 만들 때 반드시 필요함 | AWS 요구사항. 고정 IP 요구 때문이 아님(Q-36, ADR-004) |
| 중지 | 할 수 없음. 존재하는 동안 과금 | ADR-004, NFR-13 |

### 4.3 VPC 엔드포인트

| 엔드포인트 | 사용 여부 | 근거 |
|---|---|---|
| S3 게이트웨이 엔드포인트 | **쓰지 않음** | 결정자 지정(2026-11-12, N-02). 앱 서버는 NAT Gateway를 거쳐 S3 공인 엔드포인트로 접근한다. 버킷은 비공개로 두고 IAM으로 접근을 제어한다(security.md P-09). 아티팩트 다운로드는 NAT 처리 요금(GB당 약 $0.059, 추정치)을 낸다 |
| 인터페이스 엔드포인트 (CodeDeploy, SSM 등) | 쓰지 않음 | 03에 없음. NAT Gateway로 해당 엔드포인트에 닿는다(ADR-002, ADR-004). 인터페이스 엔드포인트는 AZ마다 시간 요금이 붙는다(02 12절) |

### 4.4 로드 밸런서의 네트워크 배치

| 항목 | 값 | 근거 |
|---|---|---|
| NLB 체계 | 인터넷 연결형 | ADR-010 |
| NLB 서브넷 | public-nlb-a 하나. EIP 1개 | 결정자 지정(N-03), ADR-010, 결정자 구성도 |
| NLB 교차 영역 로드 밸런싱 | **끔(명시)** | 결정자 지정(2026-11-14). NLB가 AZ 하나에만 있다(N-03 해결). NLB(AZ-A, public-nlb-a)는 같은 AZ의 ALB 노드(private-alb-a)로만 보낸다. ALB는 AWS 요구사항으로 AZ 2개(private-alb-a·b)에 걸치지만 AZ-B 노드는 NLB 트래픽을 받지 않는다. 동작은 7단계 `apply` 직후 대상 상태로 확인한다 |
| ALB 체계 | 내부용(internal) | ADR-010 |
| ALB 서브넷 | private-alb-a, private-alb-b | ADR-010, AWS 요구사항(ALB는 AZ 2개 이상), 결정자 구성도 |
| ALB 443 리스너 기본 동작 | 고정 응답 404 | 결정자 지정(2026-11-12, 설계 리뷰 DR-05). AWS 사양(리스너 기본 동작 필수). 호스트 규칙 3개(admin / b2b / b2c)에 맞지 않는 요청을 처리한다 |
| sg-alb ← sg-nlb 참조만으로 전달·상태 확인이 되는지 | ~~구축 전 AWS 문서로 확인한다~~ AWS 문서로 확인함(2026-11-15): 대상 SG가 NLB SG를 출발지로 트래픽 포트·상태 확인 포트(둘 다 443)를 허용하면 된다. 상태 확인은 NLB SG의 아웃바운드 규칙을 따른다(sg-nlb 아웃바운드 전체 허용). 실제 동작은 7단계 `apply` 직후 대상 상태로 확인한다 | DR-05(SEC-05), AWS 사양(NLB 사용자 가이드 "security groups") |

### 4.5 DNS (Route 53)

| 항목 | 값 | 근거 |
|---|---|---|
| 도메인 등록 | `imcommerce.shop`을 Route 53 Domains에서 이 AWS 계정으로 등록한다. Terraform 밖에서 운영자가 수동으로 한다 | CON-10, 결정자 지정(2026-11-15, Q-37) |
| 호스팅 영역 | `imcommerce.shop` 퍼블릭 호스팅 영역을 Terraform으로 새로 만든다 | CON-10, 결정자 지정(2026-11-12, DR-17), Q-37에서 유지 |
| 서비스 레코드 | `admin.imcommerce.shop`, `b2b.imcommerce.shop`, `b2c.imcommerce.shop` → NLB의 공인 IP(EIP)를 응답 | FR-02, FR-03, FR-06, DR-17 |
| 레코드 형식 | A 레코드, 값은 NLB EIP | DR-17("NLB public ip를 응답"). EIP는 바뀌지 않으므로 값을 고정할 수 있다(FR-06) |
| 레코드 생성 방식 | Terraform 밖에서 운영자가 수동으로 만든다(Route 53). 값은 `terraform output`의 NLB EIP다. State에 없으므로 EIP가 바뀌면 운영자가 값을 다시 넣는다 | 결정자 지정(2026-11-14) |
| ACM 검증 레코드 | ACM이 알려 준 DNS 검증 CNAME 1개(`*.imcommerce.shop`)를 Terraform 밖에서 운영자가 수동으로 만든다. 값은 `terraform output`(인증서의 검증 옵션)에서 얻는다. 인증서 자동 갱신(FR-02)에도 쓰이므로 테스트 기간 동안 지우지 않는다. Terraform 코드에는 Route 53 레코드가 하나도 없다 | 결정자 지정(2026-11-14), security.md 2.1절 |
| 네임서버 위임 | 호스팅 영역을 만들 때마다 새 네임서버 4개가 정해진다. ~~가비아에 이 네임서버를 등록해야 한다~~ 운영자가 Route 53 Domains에서 도메인의 네임서버를 Terraform 호스팅 영역의 네임서버 4개(`terraform output`)로 바꾼다 | CON-10, A-05, Q-37, AWS 사양(일반 지식) |
| 자동 생성 호스팅 영역 | Route 53 Domains로 도메인을 등록하면 AWS가 같은 이름의 호스팅 영역을 하나 자동으로 만든다(AWS 사양, 일반 지식. 이미 같은 이름의 영역이 있어도 새로 만드는지는 확인 필요). 이 영역은 쓰지 않는다. 네임서버를 바꾼 뒤 운영자가 수동으로 지운다(NS·SOA만 있으므로 지울 수 있다) | Q-37, 결정자 지정(2026-11-15) |
| 삭제 | 서비스 A 레코드 3개와 ACM 검증 CNAME을 먼저 수동으로 지운 뒤, 호스팅 영역을 `terraform destroy`로 지운다. 레코드가 남아 있으면 호스팅 영역이 지워지지 않는다(AWS 사양, 일반 지식) | Q-04, 결정자 지정(2026-11-14) |
| 요금 | 호스팅 영역 월 약 $0.50(추정치, 02 2.1절). 자동 생성 영역을 지우지 않으면 같은 요금이 하나 더 든다. Route 53 Domains 도메인 등록·갱신 요금은 이 문서에서 산정하지 않았다 | NFR-13, Q-37 |

- 호스팅 영역을 다시 만들면 네임서버가 바뀌므로 ~~가비아 위임을~~ Route 53 Domains의 네임서버 변경을 다시 해야 한다. 위임이 퍼지기 전에는 도메인 해석과 ACM DNS 검증이 끝나지 않는다(A-05).

## 5. 트래픽 흐름별 경로

> 포트 번호의 근거와 허용 규칙은 [security.md](security.md) 1절에 있다.

### 5.1 인바운드

| 흐름 | 경로 | 포트 | 근거 |
|---|---|---|---|
| 서비스 사용자, 협력사 → 서비스 | 인터넷 → NLB(public-nlb-a, EIP) → ALB(private-alb-a/b) → 앱 서버(private-app-a) | NLB TCP 443 → ALB HTTPS 443 → 앱 서버 HTTP 8080 | FR-02, FR-03, FR-06, ADR-010, ADR-003, ADR-011 |
| 운영자 → 서버 | 인터넷 → IGW → Bastion(public-a) → 앱 서버·로그 서버(private-app-a) | SSH 22 | FR-07, ADR-005, security.md S-01(해결) |
| 운영자 → MySQL·Redis | 인터넷 → IGW → Bastion → RDS(private-db-a)·ElastiCache(private-cache-a) | SSH 22, 그다음 3306·6379 | FR-04, NFR-14, ADR-005, ADR-011 |
| 운영자 → Grafana 화면 | 인터넷 → IGW → Bastion(SSH 터널) → 로그 서버(private-app-a) | SSH 22, 그다음 3000 | ADR-006, security.md S-02(해결) |

- HTTP 80 인바운드 경로는 없다. NLB와 ALB 모두 80 리스너를 두지 않는다(NFR-06, Q-27).

### 5.2 아웃바운드

| 흐름 | 경로 | 포트 | 근거 |
|---|---|---|---|
| 앱 서버 → S3 (아티팩트 다운로드) | 앱 서버 → rt-private → NAT Gateway → IGW → S3 | HTTPS 443 | FR-05, FR-08, ADR-004, N-02(VPC 엔드포인트 없음) |
| 앱 서버 → CodeDeploy 엔드포인트 | 앱 서버 → NAT Gateway → IGW → CodeDeploy | HTTPS 443 | FR-05, ADR-002 |
| 앱·로그 서버 → 일반 인터넷 (패키지 설치 등) | 서버 → NAT Gateway → IGW → 인터넷 | HTTPS 443, HTTP 80 (아웃바운드 전체 허용, security.md S-05) | FR-05, Q-34 |
| Bastion → 인터넷 | Bastion → rt-public → IGW | HTTPS 443 | ADR-011 |

### 5.3 VPC 내부

| 흐름 | 경로 | 포트 | 근거 |
|---|---|---|---|
| ALB → 앱 서버 (요청 전달) | private-alb-a/b → private-app-a | HTTP 8080 | FR-03, ADR-011 |
| ALB → 앱 서버 (상태 확인) | private-alb-a/b → private-app-a, 경로 `/healthz`, 정상 코드 200 | HTTP 8080 | FR-13, ADR-010 |

**ALB 대상 그룹(admin / b2b / b2c) 상태 확인 값** (설계 리뷰 DR-26)

| 항목 | 값 | 근거 |
|---|---|---|
| 경로 | `/healthz` | FR-13 |
| 프로토콜·포트 | HTTP 8080 | ADR-011, CON-06 |
| 정상 코드 | 200 | FR-13 |
| 간격 | 30초 | AWS 기본값 |
| 타임아웃 | 5초 | AWS 기본값 |
| 정상 임계값 | 5회 | AWS 기본값 |
| 비정상 임계값 | 2회 | AWS 기본값 |
| 등록 해제 지연 | 300초 | AWS 기본값 |

- 기본값이면 앱이 뜬 뒤 정상으로 판정되기까지 최대 약 2.5분(30초 × 5)이 걸린다. NFR-04·NFR-11 검증은 그 뒤에 한다.

| NLB → ALB (전달) | public-nlb-a → private-alb-a/b | TCP 443 | ADR-010, N-03 |
| NLB → ALB (상태 확인) | public-nlb-a → private-alb-a/b, HTTPS 443, 경로 `/`, 정상 코드 404 | HTTPS 443 | 결정자 지정(2026-11-12, 설계 리뷰 DR-05). 대상 종류가 ALB이면 상태 확인은 HTTP/HTTPS만 된다(AWS 사양, ~~확인 필요~~ 2026-11-15 AWS 문서로 확인. 성공 코드 범위 200~599). 상태 확인 요청에는 서비스 Host 헤더가 없어 ALB 기본 동작(고정 응답 404)이 응답한다 |
| 앱 서버 → RDS MySQL | private-app-a → private-db-a | TCP 3306 | FR-04, ADR-008, ADR-011 |
| 앱 서버 → ElastiCache Redis | private-app-a → private-cache-a | TCP 6379 | FR-04, ADR-008, ADR-011 |
| 앱 서버(Alloy) → 로그 서버(Loki) | private-app-a 안(같은 서브넷) | TCP 3100 | FR-09, ADR-006, security.md S-02(해결) |

**NLB → ALB 대상 그룹 상태 확인 값** (결정자 지정 2026-11-15, 05 7단계)

| 항목 | 값 | 근거 |
|---|---|---|
| 프로토콜·포트 | HTTPS 443 | DR-05 |
| 경로 | `/` | DR-05 |
| 정상 코드 | 404 | DR-05(ALB 기본 동작 고정 응답 404) |
| 간격 | 30초 | AWS 기본값 |
| 타임아웃 | 10초 | AWS 기본값(NLB HTTPS 상태 확인) |
| 정상 임계값 | 5회 | AWS 기본값 |
| 비정상 임계값 | 2회 | AWS 기본값 |

- 대상 종류가 `alb`인 대상 그룹은 속성(등록 해제 지연 등)을 바꿀 수 없고 항상 기본값이다(AWS 사양). 그래서 표에 넣지 않는다.

- 포트 값 근거: 443은 HTTPS 표준 포트(FR-02), 8080은 Spring Boot 기본값(CON-06, AWS 기본값/관례), 3306은 MySQL 기본값, 6379는 Redis 기본값, 3100은 Loki 기본값, 3000은 Grafana 기본값, 22는 SSH 기본값이다.

## 6. 추가 결정 필요

| ID | 항목 | 왜 필요한가 | 관련 요구사항 |
|---|---|---|---|
| N-01 | **해결(2026-11-12)**: 1.2절대로 확정. 인스턴스 유형 제공 확인 완료(compute.md C-05) | 1.2절은 관례로 정했다. 앱 서버, 로그 서버, Bastion, RDS, ElastiCache에 쓸 인스턴스 유형이 그 AZ에서 제공되는지 구축 전에 확인해야 한다 | NFR-02, NFR-03 |
| N-02 | **해결(2026-11-12)**: 쓰지 않음. 4.3절 | 03 X-02와 같다. 두면 rt-private에 S3 경로가 추가되고 NAT 처리 요금이 줄어든다 | FR-05, FR-08, NFR-12 |
| N-03 | **해결(2026-11-12)**: NLB를 AZ-A 하나에만 둠. 4.4절 | 기본값(끔)이면 각 NLB 노드는 같은 AZ의 ALB 노드로만 보낸다. 지금 구성에서 문제가 되는지 04에서 정하지 않았다 | FR-06, NFR-04 |
| N-04 | **해결(2026-11-12)** | 보안 그룹 아웃바운드를 전체 허용으로 정해(security.md S-05) HTTP 80 아웃바운드도 열려 있다 | FR-05, CON-07 |
| N-05 | **변경(2026-11-14)**: 앱 서버와 같은 private-app-a. private-log-a 삭제 | 구성도에는 로그 서버(Loki + Grafana, ADR-006)가 없다. ADR-006이 유효하므로 앱 서버와 같은 private-app-a에 두었다. 구성도에서 뺀 것이 의도라면 ADR-006과 FR-09를 고쳐야 한다 | FR-09, ADR-006 |
| N-06 | **해결(2026-11-12)**: 서브넷 하나로 둔다. 가능 여부는 구축 때 확인 | 구성도에는 캐시 서브넷이 하나뿐이다. 예비 대역이 없어졌다. 서브넷 하나만 쓴다(N-08 해결) | FR-04, ADR-008 |
| N-07 | **해결(2026-11-12)**: 03은 AZ 단위로 서브넷을 그리고(AZ-A 퍼블릭·프라이빗, AZ-B 프라이빗. 03 v1.7에서 퍼블릭 서브넷 B 삭제), 용도별 세부 서브넷은 이 문서에만 둔다. 03은 고치지 않는다 | 03 3절 다이어그램은 AZ마다 프라이빗 서브넷이 하나다. 이 문서는 구성도에 따라 용도별 프라이빗 서브넷 6개(v1.3)로 나눴다. 03(Approved)은 고치지 않았다 | NFR-03 |
| N-08 | **해결(2026-11-14)**: 서브넷은 private-cache-a 하나만 쓴다. AZ-B 캐시 서브넷은 두지 않으며 A·B 모두 채택하지 않음(결정자 지정) | `192.168.0.0/24`를 /27 8개가 모두 써서 예비 대역이 없다. 대안: **A.** VPC에 보조 CIDR(예: `192.168.1.0/24`)을 붙이고 그 안에 /27을 만든다. 기존 서브넷은 그대로 두지만 VPC 대역이 둘이 되고 라우팅 local 경로가 하나 늘어난다. **B.** 비어 있는 private-db-b(`192.168.0.96/27`)를 /28 둘(`.96/28` db-b, `.112/28` cache-b)로 나눈다. VPC 대역은 하나로 유지하지만 private-db-b를 다시 만들어야 하고 /28은 사용 가능 IP가 11개다. 설계 리뷰는 서브넷 하나로도 된다고 봤다(design-review-tech-feasibility.md, 일반 지식) | FR-04, ADR-008, NFR-03 |

## 7. 검증 항목

| 설계 항목 | 검증 방법 (명령어/도구) | 관련 요구사항 |
|---|---|---|
| VPC CIDR이 `192.168.0.0/24`이다 | `aws ec2 describe-vpcs --vpc-ids <VPC ID> --query 'Vpcs[].CidrBlock'` 결과가 `192.168.0.0/24` | NFR-02 |
| 서브넷 8개의 AZ와 CIDR이 2절과 같다 | `aws ec2 describe-subnets --filters Name=vpc-id,Values=<VPC ID> --query 'Subnets[].[Tags[?Key==\`Name\`]\|[0].Value,AvailabilityZone,CidrBlock]' --output table` | NFR-03 |
| RDS 서브넷 그룹이 AZ 2개, ElastiCache 서브넷 그룹이 private-cache-a다 | `aws rds describe-db-subnet-groups --db-subnet-group-name <이름> --query 'DBSubnetGroups[].Subnets[].SubnetAvailabilityZone.Name'` 결과가 `ap-northeast-2a`, `ap-northeast-2c`. `aws elasticache describe-cache-subnet-groups --cache-subnet-group-name <이름> --query 'CacheSubnetGroups[].Subnets[].SubnetIdentifier'` 결과가 `<private-cache-a>` | FR-04, ADR-008 |
| 서브넷이 AZ 2개에 걸친다 | 위 결과의 AZ 고유 값이 `ap-northeast-2a`, `ap-northeast-2c` 두 개 | NFR-03 |
| 프라이빗 서브넷은 공인 IP를 자동 할당하지 않는다 | `aws ec2 describe-subnets --subnet-ids <private-alb-a> <private-alb-b> <private-app-a> <private-db-a> <private-db-b> <private-cache-a> --query 'Subnets[].MapPublicIpOnLaunch'` 결과가 모두 `false` | NFR-06, FR-05 |
| 인터넷 게이트웨이가 VPC에 붙어 있다 | `aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=<VPC ID> --query 'InternetGateways[].Attachments[].State'` 결과가 `available` | FR-05, FR-06 |
| rt-public의 기본 경로가 IGW다 | `aws ec2 describe-route-tables --route-table-ids <rt-public> --query 'RouteTables[].Routes[?DestinationCidrBlock==\`0.0.0.0/0\`].GatewayId'` 결과가 `igw-`로 시작 | ADR-011 |
| rt-private의 기본 경로가 NAT Gateway다 | 같은 명령을 `<rt-private>`에 실행해 `NatGatewayId`가 `nat-`로 시작 | FR-05, ADR-011 |
| 모든 서브넷이 명시적으로 연결돼 있다 | `aws ec2 describe-route-tables --filters Name=vpc-id,Values=<VPC ID> --query 'RouteTables[].Associations[].SubnetId'` 결과에 서브넷 8개가 모두 있다 | ADR-011 |
| NAT Gateway가 public-a에 있다 | `aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<VPC ID> --query 'NatGateways[].[SubnetId,State,ConnectivityType]'` 결과가 `<public-a>`, `available`, `public` | FR-05, ADR-004 |
| 프라이빗 서버가 인터넷으로 나간다 | 앱 서버에서 `curl -sI https://s3.ap-northeast-2.amazonaws.com`의 응답 코드가 있다 | FR-05 |
| 프라이빗 서버의 나가는 IP가 NAT Gateway EIP다 | 앱 서버에서 `curl -s https://checkip.amazonaws.com` 결과가 NAT Gateway의 EIP와 같다 | FR-05, ADR-004 |
| NLB가 public-nlb-a에만 있고 EIP 1개를 가진다 | `aws elbv2 describe-load-balancers --names <NLB 이름> --query 'LoadBalancers[].AvailabilityZones[].[ZoneName,SubnetId,LoadBalancerAddresses[].AllocationId]'` 결과가 `ap-northeast-2a`, `<public-nlb-a>`, `eipalloc-` 1개 | FR-06, ADR-010, N-03 |
| 서비스별 대상 그룹 상태가 구분된다 | `aws elbv2 describe-target-health --target-group-arn <admin 대상 그룹 ARN>`을 b2b, b2c 대상 그룹에도 실행해 3개 모두 `healthy`. 서비스 하나를 멈추면 그 대상 그룹만 `unhealthy` | FR-13, DR-05 |
| ALB 기본 동작이 고정 응답 404다 | `aws elbv2 describe-listeners --load-balancer-arn <ALB ARN> --query 'Listeners[].DefaultActions[].[Type,FixedResponseConfig.StatusCode]'` 결과가 `fixed-response`, `404` | DR-05 |
| Route 53 호스팅 영역과 서비스 레코드가 있다 | `dig NS imcommerce.shop +short` 결과가 호스팅 영역의 네임서버 4개와 같다. 도메인 3개 각각 `dig <도메인> A +short` 결과가 NLB EIP | FR-02, FR-06, DR-17 |
| NLB를 거쳐 ALB로 요청이 간다 | 도메인 3개 각각 `curl -sS https://<도메인>/healthz -o /dev/null -w '%{http_code}'` 결과가 `200`. `aws elbv2 describe-target-health --target-group-arn <NLB 대상 그룹 ARN>` 결과가 `healthy` | FR-06, FR-13, N-03 |
| S3 VPC 엔드포인트가 없다 | `aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<VPC ID> --query 'VpcEndpoints'` 결과가 `[]` | N-02 |
| 서비스 도메인이 NLB의 EIP로 해석된다 | 도메인 3개 각각 `dig <도메인> +short` 결과가 NLB EIP 1개와 같다. 중지·시작 뒤에도 같다 | FR-06 |
| ALB가 내부용이고 프라이빗 서브넷에 있다 | `aws elbv2 describe-load-balancers --names <ALB 이름> --query 'LoadBalancers[].[Scheme,AvailabilityZones[].SubnetId]'` 결과가 `internal`, `<private-alb-a>`, `<private-alb-b>` | NFR-06, ADR-010 |
| 프라이빗 리소스에 공인 IP가 없다 | `aws ec2 describe-instances --filters Name=subnet-id,Values=<private-app-a> --query 'Reservations[].Instances[].PublicIpAddress'` 결과가 비어 있다 | NFR-06 |
| 모든 리소스가 서울 리전에 있다 | `terraform state list`의 리소스마다 `terraform state show`로 리전·AZ가 `ap-northeast-2`로 시작 | NFR-02 |
