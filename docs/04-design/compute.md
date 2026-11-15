# 04-design / compute.md — 컴퓨팅 상세 설계

| 항목 | 값 |
|---|---|
| 상태 | Approved |
| 버전 | 1.4 |
| 날짜 | 2026-11-15 |
| 작성자 | 박가온누리 |
| 선행 문서 | [01-requirements.md](../01-requirements.md) v1.5 (Approved), [03-architecture.md](../03-architecture.md) v1.9 (Approved), [adr/](../adr/) ADR-001~ADR-014 (Accepted. ADR-007·ADR-009·ADR-012는 대체됨), [network.md](network.md) v1.5 (Approved), [security.md](security.md) v1.4 (Approved) |

### 변경 이력

| 버전 | 변경 내용 | 근거 |
|---|---|---|
| 0.1 | 최초 작성 | 03 v1.4, ADR-001~ADR-011 |
| 0.2 | network.md v0.6의 용도별 서브넷 이름으로 1절 서브넷 열을 바꿈(앱 서버 private-app-a, 로그 서버 private-log-a) | network.md v0.6 |
| 0.3 | C-01~C-05 결정 반영: IAM 인스턴스 프로파일은 구축 완료 뒤 별도 구성, CPU 크레딧 Standard, 로그 서버·Bastion은 수동 중지, 시작 순서 해당 없음, AZ-A 인스턴스 유형 확인 완료 | 결정자 지정 (2026-11-12) |
| 0.4 | 설계 리뷰 결정 반영: 볼륨 암호화 켬(DR-09). 상세 시작 절차는 Terraform 범위 밖(DR-06) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.5 | 선행 문서 버전을 현재 값으로 수정(DR-18) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.6 | IAM 리소스는 Terraform 코드에 넣지 않음(K-04). Alloy 수집 대상은 앱 로그만(K-01) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.7 | 01 v1.4에서 FR-12가 삭제돼 근거를 00 종료 처리(Q-04)로 바꿈(2곳). 선행 문서 버전 갱신 | 01 v1.4 FR-12 삭제 (결정자 지정, 2026-11-12) |
| 1.0 | 승인 | 박가온누리 승인 (2026-11-12) |
| 1.1 | 2절: AMI ID 고정, 앱 서버 Service 태그 추가(CodeDeploy 배포 그룹은 Terraform 밖 수동) | 결정자 지정 (2026-11-14) |
| 1.2 | network.md v1.3 반영: 1절 로그 서버 서브넷을 private-app-a로 바꿈(private-log-a 삭제). 선행 문서 버전 갱신. 승인 | network.md v1.3, 결정자 지정 (2026-11-14), 박가온누리 승인 (2026-11-15) |
| 1.3 | 2절 키 페어: AWS에 있는 키 페어 3개를 이름으로 지정하고 Terraform은 만들지 않음. 6절 검증 항목 1개 추가. ADR-012 참조를 ADR-014로 바꿈. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), [ADR-014](../adr/ADR-014-subnet-layout-8.md) |
| 1.4 | 선행 문서 버전 갱신(00 v1.7·01 v1.5 NFR-07 변경, 03 v1.9). 내용 변경 없음 | 결정자 지정 (2026-11-15), 00 v1.7, 01 v1.5 |

> 모든 값에 근거를 붙였다(요구사항 ID, ADR, 또는 "AWS 기본값/관례"). 03에 없는 구성 요소는 넣지 않았다.

## 1. 서버별 사양

| 서버 | 인스턴스 타입 | vCPU / 메모리 | 개수 | 서브넷 | 근거 |
|---|---|---|---|---|---|
| 앱 서버 admin | t3.medium | 2 / 4GB | 1 | private-app-a | ADR-001, CON-14 |
| 앱 서버 b2b | t3.medium | 2 / 4GB | 1 | private-app-a | ADR-001, CON-14 |
| 앱 서버 b2c | t3.medium | 2 / 4GB | 1 | private-app-a | ADR-001, CON-14 |
| 로그 서버 (Loki + Grafana) | t3.large | 2 / 8GB | 1 | ~~private-log-a~~ private-app-a | ADR-006, network.md N-05(2026-11-14 변경) |
| Bastion | t3.medium | 2 / 4GB | 1 | public-a | ADR-005 |
| NAT Gateway | 관리형 (인스턴스 아님) | - | 1 | public-a | ADR-004 |

- **선정 근거:**
  - 앱 서버는 02 11절 메모리 검토 결과 예상 사용량이 약 0.75~1.35GB다. 4GB면 Spring Boot 3, CodeDeploy 에이전트, Alloy를 함께 띄워도 여유가 있다(ADR-001).
  - 로그 서버와 Bastion의 크기는 결정자가 지정했다(ADR-006, ADR-005).
- 모든 서버가 x86, 2 vCPU라 CON-14를 지킨다. 다만 CON-14의 "메모리 최소 스펙"과는 다르다. 결정자가 00과 01은 고치지 않기로 했다(ADR-001).

## 2. 공통 설정

| 항목 | 값 | 근거 |
|---|---|---|
| AMI | Ubuntu 24.04 LTS 공식 AMI (x86_64). **`ami-05b829d75c9f9183e`로 고정**(`ubuntu-noble-24.04-amd64-server-20261108`, 소유자 Canonical `099720109477`, 2026-11-14 조회). 최신 AMI를 조회해 쓰지 않는다(새 AMI가 나오면 `plan`이 서버 교체로 나와 FR-11 검증이 실패한다) | CON-07, CON-14, 결정자 지정(2026-11-14) |
| 앱 서버 서비스 태그 | `Service` = `admin` / `b2b` / `b2c`. Terraform이 붙인다. CodeDeploy 배포 그룹(Terraform 밖 수동 생성)이 이 태그로 서비스별 1대를 고른다 | NFR-10, 결정자 지정(2026-11-14) |
| 구매 옵션 | 온디맨드 | ADR-001 |
| CPU 크레딧 모드 | **Standard** | 결정자 지정(C-02). AWS 기본값(Unlimited)과 다르므로 명시한다. CPU를 오래 높게 쓰면 추가 요금 대신 성능이 제한된다(NFR-12, CON-02) |
| 루트 볼륨 유형 | gp3 | AWS 관례(gp2보다 저렴하고 기본 성능이 같거나 높음) |
| 루트 볼륨 크기 | 앱 서버·Bastion 8GB, 로그 서버 20GB | AWS 기본값(Ubuntu 공식 AMI 루트 8GB). 로그 서버는 ADR-006(20GB) |
| 볼륨 암호화 | 켬. AWS 관리형 키 | security.md S-08, 결정자 지정(2026-11-12, 설계 리뷰 DR-09) |
| 종료 시 볼륨 삭제 | 켬 | AWS 기본값. Q-04(테스트 후 리소스 삭제) |
| 공인 IP | 앱·로그 서버 없음. Bastion만 자동 할당 | network.md 2절, security.md P-04, ADR-005 |
| 키 페어 | ~~SSH 키 인증~~ SSH 키 인증. AWS(ap-northeast-2)에 이미 있는 키 페어를 이름으로 지정하고, Terraform은 키 페어를 만들지 않는다. 앱 서버 3대(admin / b2b / b2c) `commerce-prod-app-key`, 로그 서버 `commerce-prod-log-key`, Bastion `commerce-prod-bastion-key` | security.md 2.1, ADR-005, 결정자 지정(2026-11-15) |
| 보안 그룹 | 앱 sg-app, 로그 sg-log, Bastion sg-bastion | security.md 1.1 |
| IAM 인스턴스 프로파일 | 인프라 구축 완료 뒤 별도로 구성. Terraform 코드에 IAM 리소스를 넣지 않는다 | 결정자 지정(C-01, 설계 리뷰 K-04). 03 리뷰 A-02 |
| 설치 에이전트 | 앱 서버: CodeDeploy 에이전트, Alloy. Alloy 수집 대상은 앱 로그만 | ADR-002, ADR-006, 결정자 지정(2026-11-12, 설계 리뷰 K-01) |

## 3. 스케일링·가동 정책

| 항목 | 값 | 근거 |
|---|---|---|
| Auto Scaling | 쓰지 않음 | CON-14, Q-17 |
| 수평 확장 | 하지 않음. 서비스별 1대 고정 | CON-14 |
| 수직 확장 | 필요하면 수동으로 타입 변경(중지 → 변경 → 시작) | AWS 관례. 운영자 수동 대응(CON-12) |
| 가동 시간 | 하루 2시간 | CON-03 |
| 매일 중지·시작 대상 | 앱 서버 3대 | CON-03(컴퓨팅) |
| 로그 서버·Bastion의 중지 | 운영자가 수동으로 중지 | 결정자 지정(C-03), CON-03 |
| 시작 순서 | 정하지 않음. 모든 서버가 가동된 뒤 헬스 체크를 한다. 상세 시작 절차(앱 재시작 등)는 Terraform 범위 밖에서 정한다 | 결정자 지정(C-04), NFR-04, 결정자 지정(2026-11-12, 설계 리뷰 DR-06) |
| 장애 시 자동 복구 | 하지 않음 | 00 3.2, A-03, CON-12 |

## 4. 비용 영향 (추정치)

| 서버 | 시간당 단가 (USD) | 근거 |
|---|---|---|
| t3.medium | 약 0.052 | ADR-001(2025년 기준 서울 리전 공개 요금, 02 2.1절과 같은 기준) |
| t3.large | 약 0.104 | 같은 기준. 확정 전 AWS 요금 계산기로 확인 |

- 서버는 중지하면 EBS만 과금된다(NFR-13).
- 02 13절 합계는 t3.small 기준이고, 결정자 지시로 다시 계산하지 않았다.

## 5. 추가 결정 필요

| ID | 항목 | 왜 필요한가 | 관련 요구사항 |
|---|---|---|---|
| C-01 | ~~앱 서버의 IAM 인스턴스 프로파일 (S3 읽기, CodeDeploy 에이전트 권한)~~ **해결(2026-11-12)**: 인프라 구축 완료 뒤 별도로 구성 | 03에 없다(03 리뷰 A-02). 없으면 에이전트가 S3에서 아티팩트를 받지 못해 **FR-08이 실패한다** | FR-08, FR-05 |
| C-02 | ~~CPU 크레딧 모드 (Unlimited / Standard)~~ **해결(2026-11-12)**: Standard | 기본값 Unlimited는 CPU를 오래 높게 쓰면 추가 요금이 붙는다. Standard는 그때 CPU가 제한된다 | NFR-12, CON-02 |
| C-03 | ~~로그 서버·Bastion을 매일 중지할지~~ **해결(2026-11-12)**: 수동으로 중지 | 03 X-06과 같다 | CON-03, NFR-13 |
| C-04 | ~~서버 시작 순서~~ **해결(2026-11-12)**: 해당 없음. 모든 서버 가동 뒤 헬스 체크 | 03 X-07과 같다. 앱이 DB보다 먼저 뜨면 `/healthz`가 실패할 수 있다 | NFR-04, FR-13 |
| C-05 | ~~사용할 인스턴스 유형을 AZ-A에서 제공하는지 확인~~ **해결(2026-11-12)**: 결정자 확인 완료 | network.md N-01과 같다 | NFR-02 |

## 6. 검증 항목

| 설계 항목 | 검증 방법 (명령어/도구) | 관련 요구사항 |
|---|---|---|
| 서버별 타입·개수가 1절과 같다 | `aws ec2 describe-instances --filters Name=vpc-id,Values=<VPC ID> --query 'Reservations[].Instances[].[Tags[?Key==\`Name\`]\|[0].Value,InstanceType,Placement.AvailabilityZone]' --output table` | CON-14, ADR-001, ADR-005, ADR-006 |
| 서비스별 앱 서버가 1대씩이다 | 위 결과에서 admin, b2b, b2c가 각각 1행 | CON-14, NFR-05 |
| Auto Scaling 그룹이 없다 | `aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups'` 결과가 `[]` | CON-14 |
| x86, Ubuntu 24.04다 | 각 서버에서 `uname -m` 결과 `x86_64`, `lsb_release -rs` 결과 `24.04` | CON-07, CON-14 |
| 루트 볼륨이 gp3, 2절 크기다 | `aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=<ID> --query 'Volumes[].[VolumeType,Size,DeleteOnTermination]'` | Q-04 |
| 앱·로그 서버에 공인 IP가 없다 | `aws ec2 describe-instances --instance-ids <ID> --query 'Reservations[].Instances[].PublicIpAddress'` 결과가 비어 있다 | NFR-06 |
| 앱 서버에 에이전트가 동작한다 | 앱 서버에서 `systemctl is-active codedeploy-agent alloy` 결과가 둘 다 `active` | FR-08, FR-09, A-06 |
| 서버별 키 페어가 2절과 같다 | `aws ec2 describe-instances --filters Name=vpc-id,Values=<VPC ID> --query 'Reservations[].Instances[].[Tags[?Key==\`Name\`]\|[0].Value,KeyName]' --output table` 결과가 앱 서버 3대 `commerce-prod-app-key`, 로그 서버 `commerce-prod-log-key`, Bastion `commerce-prod-bastion-key` | ADR-005, 결정자 지정(2026-11-15) |
| CPU 크레딧 모드가 Standard다 | `aws ec2 describe-instance-credit-specifications --instance-ids <ID들> --query 'InstanceCreditSpecifications[].CpuCredits'` 결과가 모두 `standard` | NFR-12, C-02 |
| 수동 중지·시작이 된다 | `aws ec2 stop-instances` 뒤 상태 `stopped`, `start-instances` 뒤 `running`. 시작 뒤 도메인 3개 `/healthz`가 200 | CON-03, NFR-04 |
