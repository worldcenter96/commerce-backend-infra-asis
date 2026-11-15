# 05. Implementation Plan — 의류 커머스(admin/b2b/b2c) 백엔드 AWS 인프라

| 항목 | 값 |
|---|---|
| 상태 | Approved |
| 버전 | 1.6 |
| 날짜 | 2026-11-15 |
| 작성자 | 박가온누리 |
| 선행 문서 | [01-requirements.md](01-requirements.md) v1.6 (Approved), [03-architecture.md](03-architecture.md) v1.10 (Approved), [04-design/](04-design/) network v1.6 · security v1.4 · compute v1.4 · data v1.4 (Approved), [adr/](adr/) ADR-001~ADR-006, ADR-008, ADR-010, ADR-011, ADR-013, ADR-014 (Accepted. ADR-007·ADR-009·ADR-012는 대체됨이라 참조하지 않음), [reviews/design-review-summary.md](reviews/design-review-summary.md) (결정 기록 완료) |

### 변경 이력

| 버전 | 변경 내용 | 근거 |
|---|---|---|
| 0.1 | 최초 작성 | 위 선행 문서 |
| 0.2 | 1.1절 DNS·인증서 항목을 호스팅 영역과 ACM(인증서·DNS 검증 레코드)으로 한정. 서비스 A 레코드 3개는 Terraform 밖에서 운영자가 수동으로 만들도록 바꾸고 2·3·4·6·7·8·9절에 반영 | 결정자 지정 (2026-11-14) |
| 1.0 | 승인. 1절 구현 범위 확정 | 박가온누리 승인 (2026-11-14) |
| 1.2 | 모듈 작성 전 결정 반영: 이름 규칙(2절), ACM 검증 CNAME 수동(1.1·2·3·4·6절), AMI 고정·Service 태그(2절), CodeDeploy 배포 그룹 수동(1.1·2·3·4절), RDS 8.4.13·사용자 이름·스키마, Redis 7.1 복제 그룹, 버킷 이름, NLB 교차 영역 끔, Git은 마지막에 한 번 push(읽는 법, 9절 ①), R-02~R-04·R-19 갱신, R-20 추가 | 결정자 지정 (2026-11-14), [ai-log](../ai-log/ai-decisions.md) |
| 1.1 | network.md v1.1(A 레코드 수동 생성·삭제 순서) 반영: 선행 문서 버전 갱신, 9절 ⑨ 해소 표시, 1.1절·8절 근거 참조 정리. 계획 내용 변경 없음 | 결정자 지시 (2026-11-14) |
| 1.3 | network.md v1.3(VPC `192.168.0.0/24`, 서브넷 8개, public-b·private-log-a 삭제, ElastiCache 서브넷 하나만 사용) 반영: 1.1·1.2절 범위, 2절 network 모듈, 4절 2단계 검증, 6절 R-04 대응, 8절 DR-15, 9절 ⑦ 갱신. 선행 문서 버전 갱신. 승인 | 결정자 지정 (2026-11-14), 박가온누리 승인 (2026-11-15) |
| 1.4 | ADR-013(ADR-009 대체)·ADR-014(ADR-012 대체) 반영: 1.1절 컴퓨팅(키 페어 만들지 않음)·비밀값, 2절 compute·data 모듈 입력, 3절 0·9단계, 4절 5·6·9단계 검증, 5.1절 비밀값, 6절 R-04·R-05·R-18 갱신·R-21 추가, 8절 DR-07→K-03, 9절 ③ 갱신. ADR 참조를 바꿈. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), [ADR-013](adr/ADR-013-secrets-managed-rds.md), [ADR-014](adr/ADR-014-subnet-layout-8.md) |
| 1.5 | 00 v1.7·01 v1.5 반영(NFR-07·CON-13 변경): Terraform은 루트 계정 `aws login`으로 실행, GitHub Actions만 IAM 사용자 키. 3절 0단계, 6절 R-21 갱신·R-22 추가. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), 00 v1.7, 01 v1.5 |
| 1.6 | 00 v1.8·01 v1.6·network.md v1.6 반영(Q-37, 가비아 → Route 53 Domains): 1.1절 도메인 등록 행 추가, 3절 4·11단계, 6절 R-07. 선행 문서 버전 갱신. dns_cert 모듈 범위(2절)는 그대로 | 결정자 지정 (2026-11-15, 05 4단계 구현 질문), 00 v1.8, 01 v1.6 |

> **읽는 법**
> - **참조 우선순위:** 내용이 서로 다르면 위가 우선한다. ① design-review-summary.md의 채택·수정 결정 ② 채택(Accepted) ADR ③ 04-design ④ 03, 01. 우선순위 때문에 다른 문서 내용을 따르지 않은 곳은 9절에 모았다.
> - 04와 ADR에 없는 리소스는 넣지 않았다.
> - 단계는 작업·검증 단위로만 나눈다. Git 저장소 push는 프로젝트를 마친 뒤 한 번에 한다(결정자 지정(2026-11-14), 9절 ①).
> - 1절 구현 범위는 결정자가 승인으로 확정했다(2026-11-14).
> - 리뷰 ID는 design-review-summary.md의 `DR-xx`, `K-xx`다. 04의 결정 항목은 `S-xx`(security), `C-xx`(compute), `N-xx`(network), `D-xx`(data)다.
> - Terraform 코드는 이 문서가 승인된 뒤에 쓴다(CLAUDE.md).

---

## 1. 구현 범위 (확정)

### 1.1 이번에 구현

| 항목 | 내용 | 구현 방식 | 설계 문서 |
|---|---|---|---|
| 네트워크 | VPC(`192.168.0.0/24`), 서브넷 8개, IGW, NAT Gateway + EIP, 라우팅 테이블 2개 | Terraform | [network.md](04-design/network.md) 1~4절, ADR-004, ADR-011, ADR-014 |
| 보안 그룹 | SG 7개와 규칙 | Terraform | [security.md](04-design/security.md) 1절, ADR-011 |
| DNS·인증서 | Route 53 호스팅 영역, ACM 와일드카드 인증서(`*.imcommerce.shop`, DNS 검증 방식) 요청 | Terraform | network.md 4.5절, security.md 2.1절, ADR-003, DR-17, S-06 |
| 진입점 | NLB + EIP(AZ-A), 내부용 ALB, 대상 그룹 3개, 리스너·규칙 | Terraform | network.md 4.4·5.3절, ADR-003, ADR-010, DR-05, DR-26 |
| DNS 레코드 | ACM DNS 검증 CNAME 1개, `admin`·`b2b`·`b2c.imcommerce.shop` A 레코드 3개(값은 NLB EIP) | **Terraform 밖**, 운영자 수동 생성(Route 53) | network.md 4.5절(v1.2), security.md 2.1절, DR-17, 결정자 지정(2026-11-14), R-19, R-20 |
| 도메인 등록·네임서버 | Route 53 Domains에서 `imcommerce.shop` 등록, 도메인 네임서버를 Terraform 호스팅 영역 것으로 변경, 등록 때 자동으로 생긴 호스팅 영역 삭제 | **Terraform 밖**, 운영자 수동 | network.md 4.5절(v1.6), CON-10, A-05, Q-37 |
| 컴퓨팅 | 앱 서버 3대, 로그 서버, Bastion. 키 페어는 AWS에 있는 3개를 이름으로 지정한다(만들지 않음) | Terraform | [compute.md](04-design/compute.md) 1~3절, ADR-001, ADR-005, ADR-006 |
| 데이터 | RDS MySQL(사용자 지정 파라미터 그룹 포함), ElastiCache Redis | Terraform | [data.md](04-design/data.md) 2·3절, ADR-008, S-09, K-03 |
| 배포 대상 | S3 아티팩트 버킷(`commerce-prod-codedeploy-artifacts`), CodeDeploy 애플리케이션 | Terraform | security.md 2.2절, ADR-002, CON-09, K-02, 결정자 지정(2026-11-14) |
| CodeDeploy 배포 그룹 | 서비스별 배포 그룹 3개(앱 서버 `Service` 태그로 1대씩 고름, CodeDeploy 서비스 역할 사용) | **Terraform 밖**, 운영자 수동 생성 | compute.md 2절(v1.1), ADR-002, NFR-10, 결정자 지정(2026-11-14) |
| 서버 소프트웨어 | Java 17, CodeDeploy 에이전트, Alloy(앱 서버), Loki·Grafana(로그 서버), MySQL·Redis 클라이언트(Bastion) | 운영자 수동 설치(Bastion 경유) — **제안** | compute.md 2절, ADR-002, ADR-006, K-01 |
| IAM | 앱 서버 인스턴스 프로파일, CodeDeploy 서비스 역할 | **Terraform 밖**, 운영자 수동 생성 | 01 FR-11(IAM 예외), compute.md C-01, K-04 |
| 비밀값 | RDS 관리형 비밀번호를 Secrets Manager에서 읽어 앱 서버 Secret 파일에 배치 | **Terraform 밖**, 운영자 수동 | ADR-013, DR-11 |
| 배포 파이프라인 | GitHub Actions 워크플로(빌드 → S3 업로드 → 배포 생성) | GitHub Actions | 01 FR-08, ADR-002, 03 4-2절, CON-09 |
| 운영 절차 | 시작·중지, 헬스 체크, 롤백, 삭제(버킷 비우기 포함) | 문서(절차서) | compute.md 3절, security.md 2.2절, 03 4-2·4-3절, DR-06, K-02 |

### 1.2 설계만 하고 구현하지 않음

| 항목 | 이유 | 설계 문서 |
|---|---|---|
| Terraform 안의 IAM 리소스 | 01 FR-11에서 IAM은 Terraform 예외로 정했다 | 01 FR-11, K-04 |
| 서버 시작 순서 자동화 | 순서를 정하지 않고 모든 서버 가동 뒤 헬스 체크를 한다. 상세 절차는 Terraform 밖이다 | compute.md 3절, C-04, DR-06 |
| 백업·RPO | 백업하지 않는다. RPO 5분은 요구사항이 아니다 | data.md 1·4절, 01 NFR-08·NFR-14 |
| 메트릭·알람·예산 알림 | 01 2.2에서 범위 밖이다 | 01 2.2, Q-21, Q-33 |
| AZ-B의 인스턴스 | 서브넷만 만들고 리소스는 두지 않는다. public-b는 서브넷 자체를 만들지 않는다(2026-11-14 삭제) | ADR-014, network.md 2절 |
| S3 VPC 엔드포인트, 인터페이스 엔드포인트 | 두지 않기로 했다 | network.md 4.3절, N-02 |
| appspec·배포 스크립트 상세 | 설계 문서가 없다(DR-03 기각). 앱 저장소 쪽 작업으로 보고 이 계획에서는 동작 조건만 정한다(6절 R-01) | ADR-002, 03 4-2절 |

## 2. 디렉터리와 모듈 구조

```
terraform/
├── README.md                 # 실행 방법, 변수 목록, Terraform 밖 작업 목록
├── versions.tf               # Terraform·AWS 프로바이더 버전 고정
├── providers.tf              # 리전 ap-northeast-2, 공통 태그
├── main.tf                   # 모듈 호출
├── variables.tf              # 입력 변수 (비밀값은 sensitive)
├── outputs.tf
├── terraform.tfvars.example  # 예시만. 실제 tfvars는 Git에 넣지 않음
├── .gitignore                # *.tfstate*, *.tfvars, .terraform/
└── modules/
    ├── network/
    ├── security/
    ├── dns_cert/
    ├── compute/
    ├── data/
    ├── edge/                 # NLB, ALB, 대상 그룹, 리스너
    └── deploy/               # S3 아티팩트 버킷, CodeDeploy
```

- 루트 하나(prod)만 둔다(CON-05). State는 로컬 파일이다(CON-11, Q-31). 모듈은 직접 작성한다(CON-11).
- **이름 규칙**(결정자 지정(2026-11-14)): `{project}-{environment}-{resource}-{role}`, project = `commerce`, environment = `prod`. 예: `commerce-prod-subnet-public-a`, `commerce-prod-sg-app`, `commerce-prod-rds-mysql`. 리소스 이름과 Name 태그에 쓴다. 04의 짧은 이름(`public-a`, `sg-app`)은 `{role}` 자리에 넣는다. 이미 정한 이름(S3 버킷 `commerce-prod-codedeploy-artifacts`)은 그대로 쓴다. 공통 태그 `Project`도 `commerce`다

| 모듈 | 책임 | 입력 | 출력 | 근거 |
|---|---|---|---|---|
| network | VPC, 서브넷 8개, IGW, NAT Gateway + EIP, rt-public·rt-private와 서브넷 연결 | VPC CIDR, 서브넷 표(이름·AZ·CIDR·종류) | VPC ID, 서브넷 ID 맵, NAT EIP | network.md 1~4.2절, ADR-004, ADR-011, ADR-014 |
| security | SG 7개, 인바운드 규칙(SG 참조), 아웃바운드 전체 허용 | VPC ID, 운영자 IP(`/32`) | SG ID 맵 | security.md 1절·3절, ADR-011, DR-02, DR-22 |
| dns_cert | Route 53 호스팅 영역, ACM `*.imcommerce.shop` 요청(DNS 검증 방식). Route 53 레코드와 검증 대기 리소스는 두지 않는다(결정자 지정(2026-11-14)) | 도메인 이름 | 호스팅 영역 ID, 네임서버 4개, 인증서 ARN, 검증 CNAME 이름·값(수동 생성용) | network.md 4.5절, security.md 2.1절, ADR-003, DR-17, S-06 |
| compute | 앱 서버 3대, 로그 서버, Bastion (gp3·암호화·Standard 크레딧). 키 페어는 만들지 않는다 | 서브넷 ID, SG ID, AMI(`ami-05b829d75c9f9183e` 고정), 키 페어 이름 3개(`commerce-prod-app-key`·`commerce-prod-log-key`·`commerce-prod-bastion-key`, locals). 앱 서버에 `Service` 태그 | 인스턴스 ID·사설 IP, Bastion 공인 IP | compute.md 1·2절, ADR-001, ADR-005, ADR-006, DR-09, C-02 |
| data | RDS 서브넷 그룹·파라미터 그룹(`mysql8.4`)·인스턴스(MySQL 8.4.13, 사용자 `dbadmin`, 스키마 `imcommerce`), ElastiCache 서브넷 그룹·복제 그룹(Redis OSS 7.1, 노드 1개) | 서브넷 ID, SG ID. 비밀값 입력 없음(RDS 관리형 비밀번호 `manage_master_user_password`, Redis 인증 토큰 없음) | RDS·Redis 엔드포인트 | data.md 2·3절, ADR-008, ADR-013, S-09, S-10, K-03, DR-09, DR-10, DR-31 |
| edge | ALB(내부용)·대상 그룹 3개·HTTPS 리스너·호스트 규칙·기본 동작 404, NLB(public-nlb-a)·EIP·ALB 대상 그룹·TCP 443 리스너 | 서브넷 ID, SG ID, 인증서 ARN, 앱 인스턴스 ID | NLB EIP(서비스 A 레코드 수동 생성에 씀), ALB ARN, 대상 그룹 ARN | network.md 4.4·5.3절, security.md 2.1절, ADR-003, ADR-010, DR-05, DR-12, DR-26, DR-29 |
| deploy | S3 아티팩트 버킷 `commerce-prod-codedeploy-artifacts`(버전 관리·SSE-S3·퍼블릭 차단), CodeDeploy 애플리케이션. 배포 그룹은 Terraform 밖(결정자 지정(2026-11-14)) | 없음 | 버킷 이름, 애플리케이션 이름 | security.md 2.2절, ADR-002, CON-09, K-02, K-04 |

## 3. 구현 순서

> 일정은 구축 2일(CON-03) 기준 제안이다. "검증"은 4절의 해당 단계 항목을 모두 통과하는 것이다.

| 단계 | 대상 | 실행 방법 | 선행 단계 | 반영된 ADR | 반영된 리뷰 ID | 완료 조건 | 일정(제안) |
|---|---|---|---|---|---|---|---|
| 0 | 사전 준비(Terraform 밖): 루트 MFA 확인, GitHub Actions용 IAM 사용자·액세스 키(Terraform은 루트 계정 `aws login`, NFR-07), 운영자 PC에서 `aws login` 후 `aws sts get-caller-identity` 확인, 키 페어 3개(`commerce-prod-app-key`·`-log-key`·`-bastion-key`)가 서울 리전에 있는지 확인, 로컬 도구(Terraform, AWS CLI, nmap) | 로컬(수동) | - | ADR-005 | DR-22 | 4절 0단계 통과 | 1일 차 오전 |
| 1 | Terraform 골격: versions·providers·변수·`.gitignore`·README | 로컬 | 0 | - | DR-11, K-04 | `terraform init`·`validate` 통과, `.gitignore`에 State·tfvars 포함 | 1일 차 오전 |
| 2 | network 모듈 | 로컬 `plan`·`apply` | 1 | ADR-004, ADR-011, ADR-014 | DR-15, DR-27 | 4절 2단계 통과 | 1일 차 오전 |
| 3 | security 모듈 | 로컬 | 2 | ADR-005, ADR-011 | DR-02, DR-19, DR-22, DR-23 | 4절 3단계 통과 | 1일 차 오전 |
| 4 | dns_cert 모듈 → Route 53 Domains 도메인 등록·네임서버를 Terraform 호스팅 영역 것으로 변경·자동 생성 영역 삭제(수동) → ACM 검증 CNAME 수동 생성 → 인증서 `ISSUED` | 로컬 + Route 53 Domains·Route 53 수동 | 1 | ADR-003 | DR-17 | 4절 4단계 통과(인증서 `ISSUED`) | 1일 차 오전 시작 (위임 전파 대기를 다른 단계와 겹침) |
| 5 | compute 모듈 | 로컬 | 3 | ADR-001, ADR-005, ADR-006 | DR-09, K-04 | 4절 5단계 통과 | 1일 차 오후 |
| 6 | data 모듈 | 로컬 | 3 | ADR-008, ADR-013 | DR-09, DR-10, DR-31, K-03 | 4절 6단계 통과 | 1일 차 오후 |
| 7 | edge 모듈 → 서비스 A 레코드 3개 수동 생성(값은 `terraform output`의 NLB EIP) | 로컬 + Route 53 수동 | 4, 5 | ADR-003, ADR-010 | DR-05, DR-12, DR-17, DR-25, DR-26, DR-29 | 4절 7단계 통과(앱 배포 전이라 `/healthz`는 9단계에서) | 1일 차 오후 |
| 8 | deploy 모듈 | 로컬 | 1 | ADR-002 | K-02, K-04 | 4절 8단계 통과 | 2일 차 오전 |
| 9 | Terraform 밖 구성: (a) IAM 인스턴스 프로파일·CodeDeploy 서비스 역할 만들기와 앱 서버에 붙이기 (b) 서버 소프트웨어 설치 (c) RDS 관리형 비밀번호를 Secrets Manager에서 확인 (d) Secret 파일 배치 (e) CodeDeploy 배포 그룹 3개 생성(서비스 역할, `Service` 태그) | Bastion 경유 수동, (a)·(e)는 콘솔 | 5, 6, 8 | ADR-002, ADR-006, ADR-013 | K-01, K-04, DR-11 | 4절 9단계 통과. 결과는 README의 "Terraform 밖 작업 목록"에 기록 | 2일 차 오전 (9-e는 9-a와 8단계 뒤) |
| 10 | GitHub Actions 워크플로(서비스별 빌드 → S3 업로드 → 배포 생성) | Actions | 8, 9 | ADR-002 | K-02 | 4절 10단계 통과(서비스 3개 각각 배포 성공) | 2일 차 오후 |
| 11 | 운영 절차서: 시작·중지, 헬스 체크, 롤백, 삭제(버킷 비우기, 서비스 A 레코드·ACM 검증 CNAME 수동 삭제, CodeDeploy 배포 그룹 수동 삭제, IAM 수동 삭제, Route 53 Domains 도메인 처리(자동 갱신 여부 포함)), RDS 7일 자동 시작 대비 | 문서 | 10 | ADR-008, ADR-013 | DR-06, K-02 | 4절 11단계 통과 | 2일 차 오후 |
| 12 | 전체 검증과 마감: 04 검증 항목 전체 재실행, `plan -detailed-exitcode` 0, 결과 기록 | 로컬 | 11 | 전체 | 전체 | 7절 완료 정의 충족 | 2일 차 오후 |

- 2·3단계와 4단계는 서로 독립이다. 4단계의 네임서버 위임은 전파에 시간이 걸리므로 가장 먼저 시작한다(A-05).
- 배포 그룹을 수동으로 만들므로 8단계는 서비스 역할이 필요 없다. 9-e는 서비스 역할(9-a)과 애플리케이션(8단계)이 있어야 한다.
- 7단계 HTTPS 리스너는 인증서가 `ISSUED`여야 만들어진다. 4단계의 검증 CNAME 수동 생성을 7단계 전에 마친다(R-20).

## 4. 단계별 검증 계획

> 각 행은 04 문서 "검증 항목"의 이름이다. 명령은 해당 04 문서에 있다. 리뷰에서 채택한 항목은 **굵게** 리뷰 ID를 적었다.

| 단계 | 확인할 검증 항목 (출처) | 리뷰 ID |
|---|---|---|
| 0 | 루트 계정에 액세스 키가 없고 MFA가 켜져 있다 (security 5절) | - |
| 1 | 코드와 저장소에 비밀값이 없다 (security 5절) / `terraform state list`에 `aws_iam_` 리소스가 없다 (이 문서 추가, 01 FR-11) | **DR-11**, **K-04** |
| 2 | VPC CIDR이 `192.168.0.0/24`이다 / **서브넷 8개의 AZ와 CIDR이 2절과 같다** / 서브넷이 AZ 2개에 걸친다 / RDS·ElastiCache 서브넷 그룹(6단계 뒤 재확인) / 프라이빗 서브넷은 공인 IP를 자동 할당하지 않는다 / IGW가 VPC에 붙어 있다 / rt-public 기본 경로가 IGW다 / rt-private 기본 경로가 NAT Gateway다 / **모든 서브넷이 명시적으로 연결돼 있다** / NAT Gateway가 public-a에 있다 / S3 VPC 엔드포인트가 없다 (network 7절) | **DR-15**, **DR-27**(검증 항목 이름) |
| 3 | **`0.0.0.0/0` 인바운드가 예외 목록에만 있다** / SSH 22가 인터넷 전체에 열려 있지 않다 / 모든 SG의 아웃바운드가 전체 허용이다 / **VPC 안 규칙이 SG 참조로 돼 있다(sg-log 포함)** / **Bastion SSH는 운영자 IP에서만 받는다** / ALB는 NLB에서만 받는다 / 앱 서버는 ALB에서만 8080을 받는다 (security 5절) | **DR-02**, **DR-19**, **DR-22**, **DR-23**(예외 근거) |
| 4 | **Route 53 호스팅 영역과 서비스 레코드가 있다**(서비스 레코드는 7단계에서 수동으로 만든 뒤) (network 7절) / **ACM 인증서가 DNS 검증으로 발급됐다(`*.imcommerce.shop`)** (security 5절) / Terraform 코드에 `aws_route53_record`가 없다(이 문서 추가) | **DR-17**, S-06 |
| 5 | 서버별 타입·개수가 1절과 같다 / 서비스별 앱 서버가 1대씩이다 / Auto Scaling 그룹이 없다 / x86, Ubuntu 24.04다 / 루트 볼륨이 gp3, 2절 크기다 / 앱·로그 서버에 공인 IP가 없다 / 서버별 키 페어가 2절과 같다 / CPU 크레딧 모드가 Standard다 (compute 6절) / **RDS·ElastiCache·EBS 저장 암호화가 켜져 있다(EBS)** (security 5절) / 프라이빗 리소스에 공인 IP가 없다 (network 7절) | **DR-09** |
| 6 | **RDS 사양이 2절과 같다(엔진 최신 부 버전)** / RDS가 공개되지 않는다 / RDS 자동 백업이 꺼져 있다 / **부 버전 자동 업그레이드가 꺼져 있다** / RDS 삭제 방지가 꺼져 있다 / **Redis 사양이 3절과 같다** (data 7절) / **RDS·ElastiCache 저장 암호화가 켜져 있다** / **RDS가 TLS가 아닌 접속을 거부한다** / RDS 마스터 비밀번호가 Secrets Manager에서 관리된다 / Bastion에서 MySQL·Redis에 접속된다 / MySQL·Redis는 앱 서버와 Bastion에서만 받는다 / 계층별 서브넷이 나뉘어도 SG 참조로만 통신한다 (security 5절) | **DR-09**, **DR-10**, **DR-31**, **K-03**(DR-07 대체), S-09, S-10 |
| 7 | **NLB가 public-nlb-a에만 있고 EIP 1개를 가진다** / ALB가 내부용이고 프라이빗 서브넷에 있다 / **ALB 기본 동작이 고정 응답 404다** / 서비스 도메인이 NLB의 EIP로 해석된다 (network 7절) / **ALB TLS 정책이 2.1절과 같다** / **TLS 1.2 이상만 받는다** / 진입점에 열린 포트가 443 하나다 / HTTP 80을 받지 않는다 / 인터넷에서 서버·DB에 직접 닿지 않는다 (security 5절) / **ALB 대상 그룹 상태 확인 값이 network.md 5.3절 표와 같다**(`aws elbv2 describe-target-groups --target-group-arns <3개> --query 'TargetGroups[].[HealthCheckPath,HealthCheckIntervalSeconds,HealthCheckTimeoutSeconds,HealthyThresholdCount,UnhealthyThresholdCount]'`, 이 문서 추가) | **DR-05**, **DR-12**, **DR-17**, **DR-25**, **DR-26**, **DR-29** |
| 8 | S3 버킷 공개가 막혀 있다 / **S3 버전 관리가 켜져 있다** / S3 기본 암호화가 켜져 있다 (security 5절) / 버킷 이름이 `commerce-prod-codedeploy-artifacts`다 | **K-02** |
| 9 | 앱 서버에 에이전트가 동작한다 (compute 6절) / **Alloy 수집 대상이 앱 로그만이다**(Alloy 설정 파일 확인, 이 문서 추가) / 서버 SSH는 Bastion에서만 받는다 / 로그 서버는 앱 서버의 3100, Bastion의 3000만 받는다 (security 5절) / **Secret 파일이 저장소와 State에 없다**(`git grep`, `grep -c <비밀값> terraform.tfstate` 결과 0, 이 문서 추가) / CodeDeploy 배포 그룹 3개가 서로 다른 `Service` 태그(서비스 1대)를 고른다(`aws deploy get-deployment-group`, 이 문서 추가, NFR-10) | **K-01**, **K-04**, **DR-11** |
| 10 | 01 FR-08 검증(서비스 3개 각각 배포 성공, S3 새 JAR, 해시 일치) / 01 NFR-10 검증(대상 아닌 서비스 JAR 해시 불변) / 01 NFR-11 검증(배포 뒤 `/healthz` 200) / **서비스별 대상 그룹 상태가 구분된다** / **NLB를 거쳐 ALB로 요청이 간다** (network 7절) / 인증서가 유효하다 (security 5절) / 01 FR-02·FR-03 검증(`/signup` 접속) | **DR-05**, **DR-27** |
| 11 | 수동 중지·시작이 된다 (compute 6절) / 중지·시작 뒤 데이터가 남는다 (data 7절, NFR-14) / 01 NFR-04 검증(시작 직후·종료 직전 `/healthz` 200) / 01 NFR-08 검증(이전 S3 버전으로 재배포 뒤 해시 일치) / 절차서에 **버킷 비우기(모든 버전)** 와 **상세 시작 절차**가 있다 | **DR-06**, **K-02** |
| 12 | 위 단계 항목 전체 재실행 / 모든 리소스가 서울 리전에 있다 (network 7절) / `terraform plan -detailed-exitcode` 결과 0 (01 FR-11) | 전체 |

- 문서 정정만 한 리뷰 항목(DR-13, DR-18, DR-20, DR-21, DR-24, DR-28)은 구현 결과로 확인할 대상이 없다. 8절에 "문서 확인"으로 적었다.
- DR-24로 TLS 표에 추가한 "암호화하지 않음" 구간(Alloy → Loki, Bastion → Grafana)은 검증 항목이 아니라 설계 기록이다. 반대로 Bastion → Redis는 K-03 때문에 TLS가 필요하므로 6단계 검증에 들어 있다.

## 5. AI 작업 방식과 금지 사항

### 5.1 작업 방식

| 항목 | 방식 |
|---|---|
| 작업 단위 | 3절의 단계 하나씩 진행한다. 단계마다 코드 작성 → `terraform fmt`·`validate` → `plan` 결과 요약 → 운영자 확인 → 운영자가 `apply` 순서로 한다 |
| 근거 표기 | 코드의 주요 리소스·설정값 옆에 근거(04 절, ADR, 리뷰 ID)를 주석으로 단다 |
| 설계와 다를 때 | 구현 중 04·ADR과 다르게 해야 할 이유가 생기면 코드를 바꾸지 않고 멈춘 뒤 결정을 요청한다. 결정은 ai-log와 해당 설계 문서에 먼저 기록한다 |
| 확인 필요 항목 | 04·ADR에 "(확인 필요)"로 남은 AWS 동작은 해당 단계에서 먼저 확인하고 결과를 보고한다(6절 R-02~R-06) |
| 비밀값 | Terraform 변수로 받는 비밀값이 없다. RDS 비밀번호는 RDS 관리형(Secrets Manager)이고 Redis 인증 토큰은 쓰지 않는다(ADR-013). 비밀값 변수를 새로 만들어야 하면 `sensitive`로 받고 값은 운영자가 로컬 `*.tfvars`나 환경 변수로 넣는다 |
| 기록 | 단계가 끝나면 검증 결과와 Terraform 밖 작업 내용을 README에 남긴다 |

### 5.2 금지 사항

| ID | 금지 | 근거 |
|---|---|---|
| AI-01 | AI가 `terraform apply`·`destroy`를 직접 실행하지 않는다. 실행은 운영자가 한다 | CON-12, 03 4-3절 |
| AI-02 | 04와 ADR에 없는 리소스를 만들지 않는다 | 이 문서 규칙 |
| AI-03 | Terraform 코드에 IAM 리소스(사용자, 역할, 정책, 인스턴스 프로파일)를 넣지 않는다 | 01 FR-11, K-04 |
| AI-04 | 액세스 키, 비밀번호, 토큰을 코드·Git 저장소·커밋 메시지·PR 설명에 쓰지 않는다 | security.md P-08, ADR-013 |
| AI-05 | State 파일과 실제 값이 든 `*.tfvars`를 Git에 넣지 않는다 | CON-11, Q-31 |
| AI-06 | `0.0.0.0/0` 인바운드를 sg-nlb 443 말고는 만들지 않는다. 22번 포트를 `/32` 운영자 IP 말고 열지 않는다 | security.md P-01, P-02 |
| AI-07 | HTTP 80 리스너, 리디렉션, 인터넷 연결형 ALB를 만들지 않는다 | security.md P-03, P-06 |
| AI-08 | 승인된 문서(01~04, ADR)를 결정자 지시 없이 고치지 않는다. ADR 결정이 바뀌면 기존 ADR은 "대체됨"으로 두고 새 ADR을 만든다 | CLAUDE.md, 결정자 지시 |
| AI-09 | 추측으로 값을 채우지 않는다. 정해지지 않은 값은 질문한다 | CLAUDE.md |

## 6. 위험과 대응

| ID | 위험 | 관련 | 영향 | 대응 |
|---|---|---|---|---|
| R-01 | IAM 리소스와 CI/CD 상세(appspec, 배포 스크립트, 서비스 역할)가 설계되지 않았다. **DR-01·DR-03은 기각됐다** | FR-08, NFR-08, NFR-11, K-04 | 10단계에서 배포가 실패하거나 일정이 밀린다 | 9-a에서 만들 IAM 리소스와 필요한 권한을 README에 먼저 적고 결정자 확인을 받는다. appspec 훅은 10단계 전에 앱 저장소에서 준비한다 |
| R-02 | Ubuntu 24.04에서 CodeDeploy 에이전트가 동작하지 않을 수 있다 | A-06, ADR-002 | FR-08 실패 | Terraform 구현 단계에서는 확인하지 않는다. 에이전트는 운영자가 추후 수동으로 설치하며 그때 확인한다(결정자 지정(2026-11-14)). 실패하면 대안을 정한다(ADR 변경 필요) |
| R-03 | NLB(AZ 1개) → ALB(AZ 2개) 구성, ALB 대상 그룹의 HTTPS 상태 확인, sg-alb ← sg-nlb 참조가 동작하는지 확인하지 않았다 | ADR-010, network.md 4.4, DR-05 | 진입 경로 전체(FR-02, FR-06, FR-13) 실패 | NLB 교차 영역 로드 밸런싱을 끄고(명시), NLB(AZ-A)와 같은 AZ에 ALB 서브넷(private-alb-a)을 둔다(결정자 지정(2026-11-14), network.md 4.4절). `apply` 직후 대상 상태를 확인한다 |
| R-04 | ElastiCache 서브넷 그룹을 서브넷 하나로 만들 수 있는지, 전송 중 암호화 때 복제 그룹 리소스가 필요한지 확인하지 않았다 | N-06, data.md 3절 | 6단계 실패 또는 재작업 | Redis는 복제 그룹 리소스로 만든다(결정자 지정(2026-11-14)). 서브넷 하나는 6단계 시작 때 확인한다. Redis 인증 토큰은 쓰지 않는다(ADR-013). 서브넷은 private-cache-a 하나만 쓰고 AZ-B 캐시 서브넷은 두지 않는다(결정자 지정(2026-11-14), network.md N-08). 서브넷 하나로 안 되면 6단계를 멈추고 결정자에게 다시 요청한다(예비 대역 없음) |
| R-05 | IAM 인스턴스 프로파일을 Terraform 밖에서 붙이면 `plan`에 차이가 생겨 FR-11 검증이 실패한다 | FR-11, K-04 | 12단계 실패 | compute 모듈에서 인스턴스 프로파일 속성을 변경 감지에서 뺀다(`lifecycle { ignore_changes }`). 9-a 뒤 `plan`으로 확인한다 |
| R-06 | ALB TLS 정책을 비우면 오래된 기본 정책이 붙는다 | security.md 2.1, DR-29 | TLS 1.2 이상 검증(DR-25) 실패 | 정책 이름을 반드시 명시한다 |
| R-07 | ~~가비아 위임~~ 도메인 등록과 네임서버 변경(Route 53 Domains) 전파가 늦으면 ACM 검증과 도메인 해석이 늦어진다. 호스팅 영역을 다시 만들면 네임서버 변경을 다시 해야 한다. 등록 때 자동으로 생긴 호스팅 영역의 네임서버를 그대로 두면 Terraform 영역의 레코드(검증 CNAME 등)가 해석되지 않는다 | A-05, DR-17, Q-37 | 4·7·10단계 지연 | 4단계를 가장 먼저 시작한다. 호스팅 영역은 테스트 기간 중 다시 만들지 않는다 |
| R-08 | 시작 순서가 없어 앱이 RDS보다 먼저 뜨면 `/healthz`가 실패할 수 있다 | DR-06, C-04, NFR-04 | 운영일마다 NFR-04 실패 가능 | 11단계 절차서에 "헬스 체크 실패 시 앱 재시작" 단계를 넣는다 |
| R-09 | RDS는 중지 7일 뒤 자동으로 시작돼 과금된다 | ADR-008, data.md D-03 | 예산 초과 | 절차서에 구축과 운영 사이 간격이 7일을 넘으면 다시 중지하는 일정을 넣는다 |
| R-10 | 중지해도 나가는 비용 때문에 리소스가 오래 존재하면 월 100달러를 넘는다. 문서마다 기한이 다르다(ADR-004 약 23일, ADR-010 약 25일, ADR-008 약 28일). **DR-14는 기각됐다** | NFR-12, CON-01 | 예산 초과 | 가장 짧은 **약 23일**을 일정 상한으로 쓴다(9절 ④). 구축 시작일부터 날짜를 센다 |
| R-11 | 버전 관리를 켠 버킷은 `terraform destroy`로 지워지지 않는다. **DR-04는 기각됐다** | K-02, Q-04 | 테스트 종료 때 삭제 실패 | 11단계 절차서에 "모든 객체·이전 버전 삭제 → `destroy`" 순서를 넣는다 |
| R-12 | IAM 리소스는 `destroy`로 지워지지 않는다 | K-04, Q-04 | 리소스가 남는다 | 절차서에 수동 삭제 목록을 넣는다 |
| R-13 | 2일 일정에 작업이 몰려 있다. **DR-16은 기각됐다** | CON-03, CON-12 | 일정 초과 | 3절의 반나절 단위 일정을 따르고, 단계가 밀리면 Should 항목(로그, FR-09·NFR-09)의 검증을 운영 기간으로 넘길지 결정자에게 묻는다 |
| R-14 | S3 버킷 정책에 HTTPS 강제가 없다. **DR-30은 기각됐다** | security.md 2.2 | 평문 요청을 클라이언트 설정에만 의존 | 업로드·다운로드는 AWS CLI·에이전트 기본(HTTPS)만 쓴다 |
| R-15 | 운영 절차·알람이 없어 장애를 늦게 알아챈다. **DR-32는 기각됐다** | A-03, Q-21 | 검증 시간 손실 | 11단계 절차서의 헬스 체크 항목으로만 대응한다 |
| R-16 | GitHub에 저장하는 키가 Terraform 수준 권한을 가진다. **DR-34는 기각됐다** | CON-13, NFR-07 | 키 유출 시 계정 전체 영향 | 키는 GitHub 저장소 Secrets에만 둔다. 테스트 종료 뒤 키를 비활성화한다(절차서) |
| R-17 | 앱 서버 루트 볼륨 8GB가 이전 리비전 보관으로 찰 수 있다. **DR-35는 기각됐다** | compute.md 2절 | 배포 실패 | 9단계에서 `df -h`로 여유를 확인한다 |
| R-18 | Terraform State가 운영자 PC에 암호화 없이 있다. RDS 비밀번호·Redis 토큰은 State에 없지만(ADR-013) 리소스 ID·주소 등이 남는다 | Q-31, ADR-013 | PC 분실 시 노출·삭제 곤란 | State는 Git에 넣지 않는다(AI-05) |
| R-19 | 서비스 A 레코드와 ACM 검증 CNAME은 State에 없어서 Terraform이 관리하지 않는다. 레코드가 남아 있으면 호스팅 영역이 비어 있지 않아 `terraform destroy`가 실패한다 (AWS 사양, 일반 지식). NLB EIP가 바뀌어도 레코드 값은 저절로 바뀌지 않는다 | DR-17, network.md 4.5절 "삭제", FR-06 | 테스트 종료 때 삭제 실패, 도메인이 옛 IP를 가리킴 | 11단계 절차서에 "A 레코드 3개·검증 CNAME 수동 삭제 → `destroy`" 순서를 넣는다. edge 모듈을 다시 만들어 EIP가 바뀌면 A 레코드 값을 다시 넣는다 |
| R-20 | ACM 검증 CNAME을 수동으로 만들지 않으면 인증서가 `PENDING_VALIDATION`에 머문다. 7단계 HTTPS 리스너를 만들 수 없고, 나중에 레코드를 지우면 자동 갱신(FR-02)이 실패한다 | security.md 2.1절, network.md 4.5절, FR-02 | 7·10단계 실패 | 4단계에서 `terraform output`의 검증 CNAME을 Route 53에 넣고 `ISSUED`를 확인한 뒤 7단계로 간다. 테스트 기간 중 지우지 않는다 |
| R-21 | RDS 관리형 비밀번호는 Secrets Manager가 자동으로 교체한다(기본 7일로 알고 있음, 확인 필요). 교체되면 앱 서버 Secret 파일 값과 달라진다. Terraform은 루트 계정으로 실행하므로(NFR-07) Secrets Manager·KMS 권한 문제는 없다 | ADR-013, data.md 2절 | DB 접속 실패, 6단계 `apply` 실패 | 6단계 시작 전에 교체 주기와 끄는 방법을 확인해 결정자에게 보고한다. 다르게 해야 하면 멈추고 결정을 요청한다(5.1절) |
| R-22 | Terraform을 루트 계정으로 실행한다. 권한 제한이 없어 잘못된 `apply`나 `destroy` 한 번이 계정 전체에 영향을 준다. CloudTrail 등에 호출 주체가 사용자 단위로 남지 않는다 | NFR-07(01 v1.5), CON-13 | 의도하지 않은 리소스 변경·삭제 | 루트 MFA를 켜고 루트 액세스 키는 만들지 않는다(`aws login` 임시 자격 증명만 쓴다). 05 5.1절대로 `plan` 결과를 운영자가 확인한 뒤에만 `apply`한다. AI는 `apply`·`destroy`를 실행하지 않는다(AI-01) |

## 7. 완료 정의 (Definition of Done)

| # | 조건 | 근거 |
|---|---|---|
| 1 | 3절 0~12단계가 모두 끝났고, 4절의 단계별 검증 항목이 모두 통과했다 | 이 문서 |
| 2 | 01의 Must 요구사항(FR-02~FR-08, FR-11, FR-13, NFR-02, NFR-04, NFR-06, NFR-07, NFR-11~NFR-14) 검증이 통과했다 | 01 |
| 3 | `terraform plan -detailed-exitcode` 결과가 0이다 | 01 FR-11 |
| 4 | `terraform state list`에 IAM 리소스가 없고, 저장소에 비밀값·State·실제 tfvars가 없다 | 01 FR-11, K-04, security.md P-08 |
| 5 | 서비스 3개가 GitHub Actions로 각각 배포되고 `/healthz` 200을 준다 | 01 FR-08, FR-13, NFR-11 |
| 6 | 운영 절차서(시작·중지, 헬스 체크 실패 시 대응, 롤백, 삭제와 버킷 비우기, 서비스 A 레코드·검증 CNAME·배포 그룹 수동 삭제, IAM 수동 삭제, RDS 7일 대비)가 있다 | DR-06, K-02, R-08~R-12, R-19, R-20 |
| 7 | README에 Terraform 밖 작업 목록과 결과가 있다 | K-04, DR-11 |
| 8 | 8절 추적표의 모든 행이 "검증 완료" 또는 "문서 확인"이다 | 이 문서 |

## 8. 추적표 (리뷰 채택·수정 항목)

> design-review-summary.md에서 기각되지 않은 항목 전부다. 기각 항목(DR-01, DR-03, DR-04, DR-08, DR-14, DR-16, DR-30, DR-32, DR-34, DR-35)은 6절 위험에 넣었다.

| 리뷰 ID | 결정 요지 | 반영된 설계 위치 | 구현 단계 | 검증 방법 |
|---|---|---|---|---|
| DR-02 | NLB 인바운드 443 출발지 `0.0.0.0/0` | security.md 1.2절, 3절 예외 목록 | 3 | `0.0.0.0/0` 인바운드가 예외 목록에만 있다 |
| DR-05 | NLB → ALB HTTPS 상태 확인, ALB 기본 동작 404, FR-13은 대상 그룹 3개로 검증 | network.md 4.4·5.3·7절 | 7, 10 | ALB 기본 동작이 고정 응답 404다 / 서비스별 대상 그룹 상태가 구분된다 |
| DR-06 | 상세 시작 절차는 Terraform 밖 | compute.md 3절 | 11 | 절차서에 상세 시작 절차가 있다 / NFR-04 검증 |
| DR-07 → K-03 | (DR-07 "TLS 사용 안 함"은 K-03으로 대체) 데이터 계층 전송 암호화 켬 | security.md 2.1절, data.md 2·3절 | 6 | RDS가 TLS가 아닌 접속을 거부한다 / Bastion에서 MySQL·Redis에 접속된다(Redis는 `--tls`) |
| DR-09 | 저장 데이터 암호화 켬 | security.md 2.2절, compute.md 2절, data.md 2·3절 | 5, 6 | RDS·ElastiCache·EBS 저장 암호화가 켜져 있다 |
| DR-10 | MySQL·Redis 최신 부 버전(MySQL 8.4.13, Redis OSS 7.1, 2026-11-14 조회) | data.md 2·3절(v1.1) | 6 | RDS 사양·Redis 사양이 같다(엔진 버전) |
| DR-11 | Secret 파일은 Terraform 밖 | security.md 2.2절, ADR-013 | 1, 9 | 코드와 저장소에 비밀값이 없다 / Secret 파일이 저장소와 State에 없다 |
| DR-12 | NLB 서브넷 이름은 network·security 기준 | ADR-010 결정 절 | 7 | NLB가 public-nlb-a에만 있고 EIP 1개를 가진다 |
| DR-13 | 예전 문장 취소선 처리 | 03, ADR-007, 02 | - | 문서 확인 |
| DR-15 | 서브넷은 network.md 기준(ADR-012로 대체, 2026-11-15 ADR-014로 다시 대체) | ADR-014, network.md 2절 | 2 | 서브넷 8개의 AZ와 CIDR이 같다 / 모든 서브넷이 명시적으로 연결돼 있다 |
| DR-17 | Route 53 `imcommerce.shop` 생성, 서비스 레코드는 NLB EIP(레코드는 수동 생성) | network.md 4.5절 | 4, 7 | Route 53 호스팅 영역과 서비스 레코드가 있다 / 서비스 도메인이 NLB의 EIP로 해석된다 |
| DR-18 | 선행 문서 버전·변경 이력 정리 | 02, 03, 04 머리 표 | - | 문서 확인 |
| DR-19 | P-05 검증에 sg-log 추가 | security.md 5절 | 3 | VPC 안 규칙이 SG 참조로 돼 있다(sg-log 포함) |
| DR-20 | ADR-006 단점의 서버 크기 정정 | ADR-006 | - | 문서 확인 |
| DR-21 | 03 X-06·X-07은 compute.md 우선 | 03 8절 | - | 문서 확인 |
| DR-22 | Bastion 출발지 제한 반영 | security.md 1.2절, ADR-011, 03 6·8절 | 0, 3 | Bastion SSH는 운영자 IP에서만 받는다 |
| DR-23 | `0.0.0.0/0` 예외 근거 정정 | security.md 3절 | 3 | 문서 확인(예외 목록 검증과 함께) |
| DR-24 | TLS 표에 VPC 안 구간 추가 | security.md 2.1절 | - | 문서 확인 |
| DR-25 | TLS 1.2 이상 검증 방법 변경 | security.md 5절 | 7 | TLS 1.2 이상만 받는다 |
| DR-26 | ALB 대상 그룹 상태 확인 값(AWS 기본값) | network.md 5.3절 | 7 | 대상 그룹 상태 확인 값이 표와 같다(이 문서 4절 추가 명령) |
| DR-27 | 검증 항목 이름 "NLB를 거쳐 ALB로 요청이 간다" | network.md 7절 | 10 | NLB를 거쳐 ALB로 요청이 간다 |
| DR-28 | RDS 스토리지 비용 gp3 기준 | data.md 5절 | - | 문서 확인 |
| DR-29 | TLS 정책 유지(`ELBSecurityPolicy-TLS13-1-2-2021-06`) | security.md 2.1절 | 7 | ALB TLS 정책이 2.1절과 같다 |
| DR-31 | RDS·ElastiCache 부 버전 자동 업그레이드 끔 | data.md 2·3절 | 6 | 부 버전 자동 업그레이드가 꺼져 있다 |
| DR-33 | 로그가 빠지는 것은 허용 | (설계 변경 없음) | - | 검증 대상 없음 |
| K-01 | Alloy 수집 대상은 앱 로그만 | compute.md 2절 | 9 | Alloy 수집 대상이 앱 로그만이다 |
| K-02 | S3 버전 관리 켬, 삭제 전 수동 비우기 | security.md 2.2절 | 8, 11 | S3 버전 관리가 켜져 있다 / 절차서에 버킷 비우기가 있다 |
| K-03 | 데이터 계층 전송 암호화 켬(DR-07 대체) | security.md 2.1절, data.md 2·3절 | 6 | DR-07 → K-03 행과 같다 |
| K-04 | Terraform 코드에 IAM 리소스를 넣지 않음 | 01 FR-11, compute.md 2절 | 1, 5, 9 | `terraform state list`에 `aws_iam_` 리소스가 없다 |

## 9. 우선순위 때문에 다른 문서 내용을 따르지 않은 곳

| # | 따른 내용 (우선) | 따르지 않은 내용 | 이유 |
|---|---|---|---|
| ① | 결정자 지정(2026-11-14): Git push는 프로젝트를 마친 뒤 한 번에 하고, 단계별 PR은 만들지 않는다. 이제 00·03(PR 절차 없음)과 차이가 없다 | 00 3.4(Q-P-04) "Terraform PR 절차는 적용하지 않음", 03 4-3절(PR 없이 운영자가 plan → apply) | 05 작성 지시가 PR 단위를 요구했다. 다만 00·03의 "별도 승인자 없음"과 맞추려고 PR은 변경 묶음 단위로만 쓰고 운영자가 직접 병합한다고 적었다(읽는 법). 00은 참조 우선순위 목록에 없지만 확정 사항이라 함께 적는다 |
| ② | 리뷰 K-03(전송 암호화 켬) | 리뷰 DR-07(TLS 사용 안 함) | 같은 summary 안에서 K-03이 DR-07을 바꾸는 결정이다 |
| ③ | 04 security.md 5절 `redis-cli --tls`(인증 토큰 없음) | 01 FR-04 검증 `<인증·암호화 옵션>`, data.md 7절 "세션이 Redis에 저장된다"의 `<인증·암호화 옵션>` | 04가 01보다 우선이고, security.md가 S-10(2026-11-15 변경, ADR-013)에서 값을 정했다 |
| ④ | ADR-004의 예산 초과 기한 **약 23일** | 02 13.2절·03 6절·ADR-010의 약 25일, ADR-008의 약 28일 | ADR이 03보다 우선이다. ADR끼리도 값이 달라(DR-14 기각) 가장 짧은 값을 안전한 일정 상한으로 썼다 |
| ⑤ | 01 FR-11(IAM 예외), K-04 | ADR-002 "공용 IAM 사용자 키 하나로 동작한다" | ADR-002 문구는 GitHub Actions 쪽 설명이다. 에이전트용 인스턴스 프로파일은 K-04에 따라 Terraform 밖에서 만든다 |
| ⑥ | 01 v1.4 (FR-12 삭제) | 00 5.2 "MVP 테스트를 마친 뒤 리소스 삭제"를 검증하는 요구사항 | 01에서 FR-12를 지웠다. 삭제 절차는 절차서(11단계)에만 두고 완료 정의에는 넣지 않았다 |
| ⑦ | ADR-014 (서브넷 8개) | ADR-007 (AZ마다 하나씩, 대체됨), ADR-012 (서브넷 10개, 대체됨), 03 3절 다이어그램(AZ 단위 표기) | 대체된 ADR은 참조하지 않는다. 03은 N-07 결정대로 AZ 단위로만 그린다 |
| ⑧ | 04 data.md 1·4절(백업 없음) | data.md D-02 "RPO 5분을 넣을지"(열린 항목) | 01이 RTO·RPO를 정의하지 않으므로 구현 범위에 넣지 않았다 |
| ⑨ | | | **해소(2026-11-14)**: 결정자 지시로 network.md v1.1 4.5절을 고쳐 차이가 없어졌다. 레코드를 먼저 지우는 순서는 R-19에 남는다 |
