# 04-design / data.md — 데이터 계층 상세 설계

| 항목 | 값 |
|---|---|
| 상태 | Approved |
| 버전 | 1.5 |
| 날짜 | 2026-11-15 |
| 작성자 | 박가온누리 |
| 선행 문서 | [01-requirements.md](../01-requirements.md) v1.5 (Approved), [03-architecture.md](../03-architecture.md) v1.9 (Approved), [adr/](../adr/) ADR-001~ADR-014 (Accepted. ADR-007·ADR-009·ADR-012는 대체됨), [network.md](network.md) v1.5 (Approved), [security.md](security.md) v1.4 (Approved) |

### 변경 이력

| 버전 | 변경 내용 | 근거 |
|---|---|---|
| 0.1 | 최초 작성 | 03 v1.4, ADR-001~ADR-011 |
| 0.2 | network.md v0.6의 용도별 서브넷 이름으로 바꿈(RDS private-db-a, 서브넷 그룹 private-db-a·private-db-b. Redis private-cache-a, 서브넷 그룹 private-cache-a 하나) | network.md v0.6 |
| 0.3 | 설계 리뷰 결정 반영: 엔진은 구축 시점 최신 부 버전(DR-10), 전송 TLS·Redis 인증 토큰 없음(DR-07), 저장 암호화 켬(DR-09). D-01·D-04 해결 | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.4 | 선행 문서 버전 수정(DR-18), RDS 스토리지 비용 근거를 gp3 기준으로 수정(DR-28) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.5 | RDS·ElastiCache 부 버전 자동 업그레이드 끔(DR-31). 검증 항목 1개 추가 | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.6 | K-03 반영: 전송 TLS 사용(DR-07 변경). Redis 인증 토큰은 미정(security.md S-10) | [설계 리뷰 통합](../reviews/design-review-summary.md), 결정자 지정 (2026-11-12) |
| 0.7 | 01 v1.4에서 FR-12가 삭제돼 근거를 00 종료 처리(Q-04)로 바꿈(4곳). 선행 문서 버전 갱신 | 01 v1.4 FR-12 삭제 (결정자 지정, 2026-11-12) |
| 0.8 | RDS 사용자 지정 파라미터 그룹(`require_secure_transport=ON`) 사용(S-09). Redis 인증 토큰 사용(S-10) | 결정자 지정 (2026-11-12) |
| 0.9 | Redis 인증 토큰은 임시 값으로 만들고 구축 뒤 바꿈(security.md S-11) | 결정자 지정 (2026-11-12) |
| 0.10 | ADR-007이 ADR-012로 대체돼(설계 리뷰 DR-15) 근거 참조를 ADR-012로 바꿈. 내용 변경 없음 | [ADR-012](../adr/ADR-012-subnet-layout.md), 결정자 지시 (2026-11-12) |
| 1.0 | 승인 | 박가온누리 승인 (2026-11-12) |
| 1.1 | 2절: 엔진 8.4.13 고정, 마스터 사용자 이름·초기 스키마 이름 확정. 3절: 엔진 7.1 고정, 복제 그룹 리소스로 만듦 | 결정자 지정 (2026-11-14) |
| 1.2 | network.md v1.3 반영: 3절 Redis 서브넷 그룹은 private-cache-a 하나만 쓰고 AZ-B 캐시 서브넷은 두지 않음(N-08). 선행 문서 버전 갱신. 승인 | network.md v1.3 N-08, 결정자 지정 (2026-11-14), 박가온누리 승인 (2026-11-15) |
| 1.3 | ADR-013(ADR-009 대체) 반영: 2절 마스터 비밀번호는 RDS 관리형(Secrets Manager), 3절 Redis 인증 토큰 쓰지 않음(TLS 유지), 5절 Secrets Manager 비용 추가. ADR-012 참조를 ADR-014로 바꿈. 선행 문서 버전 갱신 | 결정자 지정 (2026-11-15), [ADR-013](../adr/ADR-013-secrets-managed-rds.md), [ADR-014](../adr/ADR-014-subnet-layout-8.md) |
| 1.4 | 선행 문서 버전 갱신(00 v1.7·01 v1.5 NFR-07 변경, 03 v1.9). 내용 변경 없음 | 결정자 지정 (2026-11-15), 00 v1.7, 01 v1.5 |
| 1.5 | 2절 마스터 비밀번호: 05 R-21 확인 결과(기본 7일 자동 교체, 주기 변경 가능, DB 삭제 때 시크릿도 삭제)와 대응(구축 직후 Terraform 밖에서 자동 교체를 끔, 안 되면 주기 999일) 기록 | 결정자 지정 (2026-11-15, 05 6단계 구현 질문), [ai-log](../../ai-log/ai-decisions.md) |

> 모든 값에 근거를 붙였다(요구사항 ID, ADR, 또는 "AWS 기본값/관례"). 03에 없는 구성 요소는 넣지 않았다.

## 1. RPO 5분 요구사항에 대해

> **승인된 문서에는 RPO 5분 요구사항이 없다.** 01 NFR-08과 00 Q-08은 "RTO와 RPO를 정의하지 않는다", 00 Q-09와 01 NFR-14는 "백업하지 않는다"로 확정했다. 그래서 이 문서는 **백업 없음**으로 설계했다. RPO 5분을 충족하는 방법은 4절에 따로 적었다. 반영하려면 00, 01을 먼저 고쳐야 한다.

## 2. RDS MySQL

| 항목 | 값 | 근거 |
|---|---|---|
| 엔진 | ~~MySQL 8.x 중 구축 시점의 최신 부 버전(작성 시점 기준 8.4 계열, 확인 필요)~~ **MySQL 8.4.13** (8.4 최신 부 버전, 2026-11-14 서울 리전 조회. 파라미터 그룹 종류 `mysql8.4`). 8.0은 표준 지원이 2026-07-31에 끝나 확장 지원 요금이 붙으므로 쓰지 않는다 | CON-08, 결정자 지정(2026-11-12, 설계 리뷰 DR-10), 결정자 지정(2026-11-14) |
| 인스턴스 클래스 | db.t3.micro | ADR-008 |
| 배포 | Single-AZ, AZ-A의 private-db-a | ADR-008, ADR-014, network.md 2절 |
| 서브넷 그룹 | private-db-a, private-db-b | network.md 2절, AWS 요구사항(AZ 2개) |
| 스토리지 | gp3 20GB | AWS 요구사항(MySQL gp3 최소 20GB). Q-14(데이터 규모 최소) |
| 스토리지 자동 확장 | 끔 | CON-02, Q-14 |
| 포트 | 3306 | AWS 기본값, security.md 1.2 |
| 퍼블릭 액세스 | 끔 | security.md P-04, NFR-06 |
| 보안 그룹 | sg-rds | security.md 1.1 |
| 마스터 사용자 이름 | `dbadmin` | 결정자 지정(2026-11-14) |
| 초기 스키마(DB) 이름 | `imcommerce` | 결정자 지정(2026-11-14) |
| 마스터 비밀번호 | ~~임시 비밀번호로 만들고 구축 뒤 변경~~ RDS 관리형 비밀번호(`manage_master_user_password = true`). RDS가 Secrets Manager 시크릿에 두며 Terraform 변수·State에 없다. ~~자동 교체 주기와 끌 수 있는지는 6단계 전에 확인(05 R-21)~~ **자동 교체**: RDS가 기본 7일마다 교체하고 주기는 Secrets Manager에서 바꿀 수 있다(최대 999일). DB를 지우면 시크릿도 지워진다(AWS 문서, 2026-11-15 확인). 교체되면 Secret 파일 값과 달라지므로 **구축 직후 운영자가 Terraform 밖에서 자동 교체를 끈다**(콘솔 "Disable automatic rotation"). 꺼지지 않으면 주기를 999일로 바꾼다. 끄는 기능은 공식 문서로 확인하지 못해 apply 뒤 확인한다 | ADR-013, 결정자 지정(2026-11-15), 05 R-21, 결정자 지정(2026-11-15, 05 6단계 구현 질문) |
| 저장 암호화 | 켬. AWS 관리형 키 | security.md S-08, 결정자 지정(2026-11-12, 설계 리뷰 DR-09) |
| 전송 TLS | ~~쓰지 않음~~ 사용. DB 쪽에서도 강제한다(security.md S-09) | security.md S-07, 결정자 지정(2026-11-12, 설계 리뷰 K-03, DR-07 변경) |
| 파라미터 그룹 | ~~기본~~ 사용자 지정. `require_secure_transport=ON` 말고는 기본값 | 결정자 지정(2026-11-12)(security.md S-09). 기본 파라미터 그룹은 값을 바꿀 수 없다(AWS 사양) |
| 자동 백업 보존 기간 | **0일 (자동 백업 끔)** | 00 Q-09, NFR-14(백업 안 함). API 기본값은 1일이므로 명시한다(AWS 기본값과 다름) |
| 삭제 시 최종 스냅샷 | 만들지 않음 | Q-04(테스트 후 리소스 삭제), Q-09 |
| 삭제 방지 | 끔 | Q-04 |
| 수동 중지·시작 | 함 | CON-03 |
| 7일 뒤 자동 시작 | AWS 사양. 대비 절차는 05에서 정함 | ADR-008 |
| 유지 관리 창 | AWS가 정함 | AWS 기본값 |
| 부 버전 자동 업그레이드 | 끔 | 결정자 지정(2026-11-12, 설계 리뷰 DR-31). AWS 기본값(켬)과 다르므로 명시한다 |

## 3. ElastiCache Redis

| 항목 | 값 | 근거 |
|---|---|---|
| 엔진 | ~~Redis OSS 7.x 중 구축 시점의 최신 부 버전(작성 시점 기준 7.1, 확인 필요)~~ **Redis OSS 7.1** (7.x 최신, 2026-11-14 서울 리전 조회. 파라미터 그룹 종류 `redis7`) | CON-08, 결정자 지정(2026-11-12, 설계 리뷰 DR-10), 결정자 지정(2026-11-14) |
| 노드 타입 | cache.t3.micro | ADR-008 |
| 노드 수 | 1 (복제본 없음) | ADR-008, 00 3.2 |
| 클러스터 모드 | 끔 | AWS 관례(노드 1개) |
| 위치 | AZ-A의 private-cache-a. 서브넷 그룹도 private-cache-a 하나. AZ-B 캐시 서브넷은 두지 않는다(대비용 예비 대역 없음) | ADR-014, network.md 2절, N-06·N-08(결정자 지정, 2026-11-14) |
| 포트 | 6379 | AWS 기본값, security.md 1.2 |
| 보안 그룹 | sg-redis | security.md 1.1 |
| 용도 | 로그인 세션 저장. 유실 허용 | FR-04, Q-15 |
| 스냅샷 보존 기간 | **0일 (스냅샷 끔)** | 00 Q-09, Q-15 |
| 인증 토큰 | ~~쓰지 않음. 전송 중 암호화를 쓰지 않으므로 쓸 수 없다(AWS 사양)~~ ~~**쓴다**. 임시 토큰으로 만들고 구축 뒤 운영자가 바꾼다. 바꾼 값은 Secret 파일(ADR-009 예외 확대, security.md S-11)~~ **쓰지 않음**. 전송 중 암호화는 켠다. 접근은 sg-redis로만 제한한다 | ADR-013, 결정자 지정(2026-11-15), security.md S-10 |
| 전송 중 / 저장 암호화 | 전송 중: ~~쓰지 않음~~ 켬 / 저장: 켬(AWS 관리형 키) | security.md S-07·S-08, K-03·DR-09. 둘 다 만들 때만 정할 수 있다(AWS 사양). ~~전송 중 암호화를 켜면 Terraform에서 복제 그룹 리소스로 만들어야 할 수 있다(확인 필요)~~ Terraform에서 **복제 그룹 리소스**로 만든다(노드 1개, 결정자 지정 2026-11-14) |
| 중지 | 할 수 없음. 존재하는 동안 과금 | CON-03, ADR-008, NFR-13 |
| 부 버전 자동 업그레이드 | 끔 | 결정자 지정(2026-11-12, 설계 리뷰 DR-31) |

## 4. 백업 주기와 보관 기간

| 대상 | 백업 주기 | 보관 기간 | 근거 |
|---|---|---|---|
| RDS MySQL | 없음 | 없음 | 00 Q-09, NFR-14 |
| ElastiCache Redis | 없음 | 없음 | 00 Q-09, Q-15 |
| 데이터 유지 방식 | RDS 스토리지가 중지·시작 사이에 데이터를 유지 | NFR-14 |

**RPO 5분을 요구사항으로 넣는다면** (지금 설계에는 반영하지 않음)

| 항목 | 바꿀 값 | 효과 |
|---|---|---|
| RDS 자동 백업 보존 기간 | 1일 이상 | 특정 시점 복구가 가능해진다. 복구 가능한 최신 시점은 보통 현재보다 약 5분 앞이다(AWS 사양, 일반 지식). 그래서 RPO 약 5분이 된다 |
| 비용 | 백업 저장 공간이 DB 크기(20GB)까지는 무료 | AWS 요금 정책(추정, 확인 필요) |
| 필요한 문서 변경 | 00 Q-08·Q-09, 01 NFR-08·NFR-14, 2.2 백업·보관 범위 | CLAUDE.md 순서 규칙 |
| Redis | 바꾸지 않음 | 세션 유실 허용(Q-15) |

## 5. 비용 영향 (추정치)

| 대상 | 상시 과금/일 | 근거 |
|---|---|---|
| ElastiCache (중지 불가) | 약 $0.60 | 02 13.2절 |
| Secrets Manager 시크릿 1개 (RDS 관리형 비밀번호) | 약 $0.013 (월 약 $0.40) | ADR-013. 시크릿 1개 월 $0.40(추정치, 2025년 기준 일반 지식) |
| RDS 스토리지 (중지해도 과금) | 약 $0.09 | gp3 20GB 기준(설계 리뷰 DR-28). 단가 약 $0.131/GB-월(2025년 기준 서울 리전 추정). RDS gp3는 gp2와 같은 단가로 알고 있다(확인 필요) |

## 6. 추가 결정 필요

| ID | 항목 | 왜 필요한가 | 관련 요구사항 |
|---|---|---|---|
| D-01 | ~~MySQL 8.0 / 8.4, Redis OSS 7.0 / 7.1 중 부 버전~~ **해결(2026-11-12)**: 구축 시점 최신 부 버전 (DR-10) | CON-08은 주 버전만 정했다 | CON-08 |
| D-02 | RPO 5분 요구사항을 넣을지 | 1절. 넣는다면 00·01부터 고쳐야 한다 | NFR-08, NFR-14 |
| D-03 | RDS 7일 자동 시작 대비 절차 | ADR-008 후속 조치. 05에서 정한다 | NFR-12, NFR-13 |
| D-04 | ~~암호화(저장·전송)와 Redis 인증 토큰~~ **해결(2026-11-12)**: 저장 켬, 전송 ~~끔~~ 켬(K-03). 인증 토큰과 RDS TLS 강제는 security.md S-10, S-09에서 정한다 | security.md S-07, S-08, ADR-009 | FR-04 |

## 7. 검증 항목

| 설계 항목 | 검증 방법 (명령어/도구) | 관련 요구사항 |
|---|---|---|
| RDS 사양이 2절과 같다 | `aws rds describe-db-instances --db-instance-identifier <ID> --query 'DBInstances[].[Engine,EngineVersion,DBInstanceClass,MultiAZ,AvailabilityZone,StorageType,AllocatedStorage]'` | CON-08, ADR-008 |
| RDS가 공개되지 않는다 | 같은 명령의 `PubliclyAccessible`이 `false` | NFR-06 |
| RDS 자동 백업이 꺼져 있다 | `--query 'DBInstances[].BackupRetentionPeriod'` 결과가 `0` | Q-09, NFR-14 |
| 부 버전 자동 업그레이드가 꺼져 있다 | `aws rds describe-db-instances --query 'DBInstances[].AutoMinorVersionUpgrade'`, `aws elasticache describe-cache-clusters --query 'CacheClusters[].AutoMinorVersionUpgrade'` 결과가 모두 `false` | DR-31 |
| RDS 삭제 방지가 꺼져 있다 | `--query 'DBInstances[].DeletionProtection'` 결과가 `false` | Q-04 |
| 중지·시작 뒤 데이터가 남는다 | NFR-14 검증 절차(검증 테이블 행 수·체크섬 비교) | NFR-14 |
| Redis 사양이 3절과 같다 | `aws elasticache describe-cache-clusters --cache-cluster-id <ID> --query 'CacheClusters[].[Engine,EngineVersion,CacheNodeType,NumCacheNodes,PreferredAvailabilityZone,SnapshotRetentionLimit]'` 결과에서 노드 1개, 스냅샷 보존 `0` | CON-08, ADR-008 |
| 세션이 Redis에 저장된다 | 로그인 뒤 Bastion에서 `redis-cli -h <Redis 주소> <인증·암호화 옵션> DBSIZE` 값이 늘어난다 | FR-04 |
| 삭제 뒤 스냅샷이 남지 않는다 | `terraform destroy` 뒤 `aws rds describe-db-snapshots --query 'DBSnapshots'`와 `aws elasticache describe-snapshots --query 'Snapshots'`가 모두 `[]` | Q-04 |
