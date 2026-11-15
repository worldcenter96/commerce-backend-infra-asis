# AI 산출물 결정 기록

> AI가 만든 검토·제안에 대해 사람이 내린 결정을 기록한다.
> - **결정 내용(원문)**: 사용자가 적은 문구를 바꾸지 않고 옮긴다. 적지 않은 경우 `-`로 둔다.
> - **반영 위치**: 결정이 반영됐거나 반영될 문서와 항목이다. `(예정)`은 아직 반영하지 않은 것이다.

---

## 2026-11-12 — 01-requirements 독립 검토 결과

| 항목 | 값 |
|---|---|
| 검토 문서 | [docs/reviews/01-requirements-review.md](../docs/reviews/01-requirements-review.md) |
| 검토 대상 | docs/01-requirements.md v0.2 |
| 결정자 | 박가온누리 |
| 결정일 | 2026-11-12 |

| ID | 심각도 | 리뷰 지적 (요약) | 결정 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|---|---|---|
| R-01 | High | NFR-01(검증 중 5xx 0건)이 의도적 중지·배포 다운타임과 충돌 | 기각 | 관련된 내용을 이미 수정 | 01 v0.3: NFR-01 삭제, 6.2 A-01·6.4 Q-14·Q-16 참조 정리 (반영 완료) |
| R-02 | High | FR-11·FR-12의 "전체/전부" 범위에 코드 밖 리소스(IAM 사용자·액세스 키, 루트 MFA) 경계가 없음 | 채택 | 액세스키가 필요한 부분은 주석으로 내용을 표기하고 추후 Terraform 실행 전에 코드에 삽입 | 01 v0.4 FR-11 요구사항·검증 (2) (반영 완료). terraform/ 코드 주석 (05 승인 후, 예정) |
| R-03 | Medium | Must인 FR-03의 판정이 Should인 NFR-09(로그 조회)에 의존 | 수정 | FR-03 검증 과정은 예시) https://도메인/signup 등으로 접속 및 기능을 검증 | 01 v0.4 FR-03 검증 방법 (반영 완료) |
| R-04 | Medium | FR-02의 `openssl s_client`가 호스트 이름을 검증하지 않음 | 수정 | FR-02 검증 과정은 예시) https://도메인/signup 등으로 접속 및 기능을 검증 | 01 v0.4 FR-02 검증 방법 (반영 완료) |
| R-05 | Medium | FR-01 검증 (2)가 해석 결과의 정확성을 보지 않음 | 채택 | FR-01 기능 요구사항을 삭제 | 01 v0.4 FR-01 삭제, 6.1(3.4 도메인·서비스 도메인 3개, 3.3 admin 외부 공개)·6.2 A-05 참조 정리 (반영 완료) |
| R-06 | Medium | FR-04의 `nc`·`DBSIZE` 검증이 세 서비스의 실제 연결을 증명하지 못함 | 채택 | FR-04 검증 과정은 Bastion 서버에서 MySQL, Redis로 접속이 가능한지 확인하는 방향으로 수정 | 01 v0.4 FR-04 검증 방법 (반영 완료) |
| R-07 | Medium | FR-05의 "외부 인터넷 아웃바운드"가 00 3.1 "그 밖의 외부 연동은 제외"와 맞는지 불분명 | 채택 | 일반 아웃바운드용 고정 IP 필요 | 00 v1.2 3.1 외부 연동·고정 공인 IP, 6절 Q-34 (반영 완료, 재승인). 01 v0.4 FR-05, FR-06, 6.1 3.1 행 (반영 완료) |
| R-08 | Medium | FR-05 검증이 대상(저장소·배포 도구·인터넷)별로 연결을 확인하지 않음 | 기각 | - | 없음 |
| R-09 | Medium | FR-08의 `gh run watch`가 `--exit-status` 없이 실패해도 0으로 끝남 | 기각 | - | 없음 |
| R-10 | Medium | FR-10 검증이 MySQL·Redis의 실제 중지 상태를 확인하지 않음 | 채택 | FR-10 기능 요구 사항을 삭제 | 01 v0.4 FR-10 삭제. 수동 중지·시작은 CON-03으로 옮김. FR-06·NFR-14 검증, 5.2, 6.1(3.4 상시 가동, 3.4 상태 확인)·6.3(5.2 기간과 가동 시간)·7절 P-06 참조 정리 (반영 완료) |
| R-11 | Medium | FR-12의 "다음 날 일일 비용 0" 판정 시점과 조회 API 요금 | 기각 | - | 없음 |
| R-12 | Medium | NFR-02가 전역 리소스·리전 속성 없는 리소스를 판정할 수 없음 | 기각 | - | 없음 |
| R-13 | Medium | NFR-06 (1) `nmap`이 첫 주소만 검사하고 관리 접속 경로를 검사하지 않음 | 기각 | - | 없음 |
| R-14 | Medium | NFR-06 (3) 외부에서 사설 주소로 `nc`를 시도하면 항상 실패 | 기각 | - | 없음 |
| R-15 | Medium | 관리 접속 경로의 접근 제한 수준에 측정 목표가 없음 | 기각 | - | 없음 |
| R-16 | Medium | NFR-10 검증이 미정인 서버 배치(Q-17)를 전제 | 기각 | - | 없음 |
| R-17 | Medium | NFR-12에 구축 전 비용 산정 검증이 없고 세금 포함 판별 방법이 없음 | 기각 | - | 없음 |
| R-18 | Medium | NFR-13의 비교 날짜·허용 오차가 없고 Q-03에 의존 | 기각 | - | 없음 |
| R-19 | Medium | 00 5.1 비용 산정 기준일(2026-11-10)이 01에 없음 | 기각 | - | 없음 |
| R-20 | Medium | 6.1 State 보관 행의 "위험을 수용한 것으로 본다"가 00에 없는 추정 | 기각 | - | 없음 |
| R-21 | Low | FR/NFR 문장에 고정 기술 이름이 들어가 머리말 규칙과 맞지 않음 | 기각 | - | 없음 |
| R-22 | Low | FR-09와 NFR-09의 내용·검증이 거의 같음 | 기각 | - | 없음 |
| R-23 | Low | NFR-04 문장과 가동 중 의도적 중지 시험·배포 다운타임이 맞지 않음 | 기각 | - | 없음 |
| R-24 | Low | NFR-07이 액세스 키 개수를 확인하지 않음 | 기각 | - | 없음 |
| R-25 | Low | FR-08이 서비스 3개 배포를 확인하지 않고, 이전 아티팩트 보존 요구가 없음 | 기각 | - | 없음 |
| R-26 | Low | Q-22, 국내 전용, 3.5 일부 제외 항목이 01에 반영되지 않음 | 기각 | - | 없음 |
| R-27 | Low | 6.1·6.2 추적표 일부가 본문·00과 맞지 않음 | 기각 | - | 없음 |
| R-28 | Low | 구축 기간 밖에서 검증하는 항목(FR-12, NFR-12, NFR-13)이 Must | 기각 | - | 없음 |
| R-29 | Low | NFR-14 `mysql` 명령에 접속 인자와 DB 이름이 없음 | 기각 | - | 없음 |

**집계** (29건): 채택 5건(R-02, R-05, R-06, R-07, R-10), 수정 2건(R-03, R-04), 기각 22건(R-01, R-08, R-09, R-11~R-29).

---

## 2026-11-12 — 고정 공인 IP 위치 변경 (나가는 쪽 → 들어오는 쪽)

| 항목 | 값 |
|---|---|
| 계기 | 03-architecture 작성 뒤 사용자 재검토 |
| 결정자 | 박가온누리 |
| 결정일 | 2026-11-12 |
| 영향받는 이전 결정 | 위 R-07("일반 아웃바운드용 고정 IP 필요"). 원문은 고치지 않고 이 항목으로 변경을 기록한다 |

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 고정 IP 위치 | 내가 잘못 생각했습니다 NAT 에서는 공인 IP가 필요 없고 들어올 때 NLB에서 EIP가 필요합니다. | 00 v1.6 Q-36, 3.1, 5.4. 01 v1.3 FR-06, CON-15 (반영 완료) |
| NAT Gateway | ADR-004(NAT Gateway) 이건 유지해줘 | ADR-004 맥락·결정·장점·관련 요구사항, 02 v1.1 D-04 (반영 완료) |
| NLB + EIP | NLB + EIP 바로 확정 | ADR-010 신규(비교 생략 명시), 02 v1.1 D-10, ADR-003, ADR-007, 03 v1.0 (반영 완료) |
| 고정 IP를 쓰는 주체 | 협력사가 자기 방화벽의 나가는 쪽 허용 목록에 우리 IP를 등록 | 00 v1.6 2.2, Q-36. 01 FR-06. 03 2절 Context (반영 완료) |
| 승인 | 전체 수정하고 바로 승인도 해주세요 | 00 v1.6, 01 v1.3, 02 v1.1, 03 v1.0 Approved (반영 완료) |
| ALB 위치 | ADR-010에서 NLB까지 public으로 접근하고 ALB는 프라이빗 서브넷에서 TLS 복호화와 도메인 분기만 진행한다 | ADR-010 결정, ADR-003, ADR-007, 02 v1.2 13.2절, 03 v1.1 (반영 완료) |
| ALB의 `/healthz` 확인 | 네 (ALB가 /healthz 상태 확인도 계속 맡음) | ADR-010 결정·후속 조치 (반영 완료) |
| ALB 위치 반영 범위 | 네 전체를 수정해주세요 | 02 v1.2, 03 v1.1 Approved (반영 완료) |

---

## 2026-11-12 — 03-architecture 독립 검토 결과

| 항목 | 값 |
|---|---|
| 검토 문서 | [docs/reviews/03-architecture-review.md](../docs/reviews/03-architecture-review.md) |
| 검토 대상 | docs/03-architecture.md v1.1 |
| 결정자 | 박가온누리 |

| ID | 리뷰 지적 (요약) | 결정 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|---|---|
| A-01 | 인터넷 게이트웨이, 라우팅 테이블, 보안 그룹이 03에 없음 | 채택 | 인터넷 게이트웨를 통해서 백엔드, Bastion이 외부와 아웃바운드 통신할 수 있도록 합니다. 보안그룹은 ALB와 EC2 서버 사이(0.0.0.0/0 443 허용), EC2와 MySQL, Redis 사이(EC2 서버 IP가 MySQL, Redis 포트에만 접근 가능하도록 함) | ADR-011 신규, 03 v1.2 3·5·6절 (반영 완료) |
| A-01 보충 | 위 답변의 확인 질문 | - | 백엔드는 NAT 거쳐 IGW / ALB→EC2 출발지는 ALB 보안 그룹만 / MySQL·Redis 접근은 앱 서버 + Bastion / ADR-011 새로 작성 | ADR-011 결정 절 (반영 완료) |

---

## 2026-11-12 — 설계 전체 리뷰(보안·안정성·구현 가능성) 통합 결과

| 항목 | 값 |
|---|---|
| 검토 문서 | [docs/reviews/design-review-summary.md](../docs/reviews/design-review-summary.md) (원래 리뷰 3개를 통합, DR-01~DR-35) |
| 결정자 | 박가온누리 |
| 결정 범위 | DR-01~DR-17. DR-18~DR-35는 결정 없음 |

| ID | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| DR-01 | ~~IAM 인스턴스 프로파일을 Terraform 밖 범위로 정한다~~ 기각 | 기각으로 문서 변경 없음 (결정자, 2026-11-12) |
| DR-02 | NLB 인바운드 443 출발지는 0.0.0.0/0 이다 | security.md v0.8 1.2·3절·S-03, ADR-011 후속 조치 (반영 완료) |
| DR-03 | ~~해당 상세 설정은 Terraform 밖 범위로 정한다~~ 기각 | 기각으로 문서 변경 없음 (결정자, 2026-11-12) |
| DR-04 | ~~해당 상세 설정은 Terraform 밖 범위로 정한다~~ 기각 | 기각으로 문서 변경 없음 (결정자, 2026-11-12) |
| DR-05 | 확정 | network.md v0.9 4.4·5.3·7절 (반영 완료) |
| DR-06 | 해당 상세 설정은 Terraform 밖 범위로 정한다 | compute.md v0.4 3절 (반영 완료) |
| DR-07 | 앱서버에서 RDS, Redis 구간은 TLS 사용하지 않는다 | security.md v0.8 2.1·S-07, data.md v0.3, ADR-009 후속 조치 (반영 완료) |
| DR-08 | ~~ACM 인증서는 와일드카드 1개로 Terraform에서는 ACM인프라만 만들고 인증서는 추후 인프라가 구축되면 업로드 한다~~ 기각 | 기각으로 문서 변경 없음 (결정자, 2026-11-12) |
| DR-09 | 암호화 확정 | security.md v0.8 2.2·S-08, data.md v0.3, compute.md v0.4 (반영 완료) |
| DR-10 | MySQL·Redis 부 버전은 최신버전으로 한다. | data.md v0.3 2·3절·D-01 (반영 완료) |
| DR-11 | Secret 파일은 Terraform 밖 범위로 정한다 | security.md v0.8 2.2, ADR-009 후속 조치 (반영 완료) |
| DR-12 | network.md, security.md가 우선이며 그에 맞춰 수정 | ADR-010 결정 절 (반영 완료) |
| DR-13 | 해당 문장을 취소선으로 바꾸고 현재 값을 적는다 | 03 v1.5, ADR-007, 02 v1.4 (반영 완료, 03·02 재승인 대기) |
| DR-14 | ~~따로 취소선 처리 하지 않는다~~ 기각 | 기각으로 문서 변경 없음 (결정자, 2026-11-12) |
| DR-15 | network.md에 맞춰 내용을 수정 | ADR-007 결정 절 (반영 완료) |
| DR-16 | 기각 | 없음 |
| DR-17 | Route53 호스팅 영역을 imcommerce.shop으로 만들고 예를 들어 b2b.imcommerce.shop 으로 접속할 경우 NLB public ip를 응답하도록 한다. | network.md v0.9 4.5절·7절 (반영 완료) |
| DR-18 | 확정 | 02 v1.4, 03 v1.5, network.md v0.10, security.md v0.9, compute.md v0.5, data.md v0.4 선행 문서 버전·변경 이력 정렬 (반영 완료) |
| DR-19 | 확정 | security.md v0.9 5절 P-05 검증에 sg-log 추가 (반영 완료) |
| DR-20 | 취소선 처리 | ADR-006 단점 (반영 완료) |
| DR-21 | compute.md를 우선한다 | 03 v1.5 8절 X-06·X-07 해결 표시 (반영 완료) |
| DR-22 | 출발지 제한이 정해졌기에 거기에 맞춰 내용을 수정 | ADR-011 후속 조치, 03 v1.5 6절 NFR-06(○)·8절 X-03 (반영 완료) |
| DR-23 | 확정 | security.md v0.9 3절 예외 목록 근거 (반영 완료) |
| DR-24 | 확정 | security.md v0.9 2.1 TLS 표에 3개 구간 추가 (반영 완료) |
| DR-25 | TLS 1.2 이상 | security.md v0.9 5절 TLS 검증 방법 변경 (반영 완료) |
| DR-26 | 값을 표에 적고 근거를 "AWS 기본값"으로 단다. | network.md v0.10 5.3절 상태 확인 값 표 (반영 완료) |
| DR-27 | NLB를 거쳐 ALB로 요청이 간다"로 바꾼다 | network.md v0.10 7절 검증 항목 이름, N-07 서브넷 개수 (반영 완료) |
| DR-28 | gp3 기준으로 수정 | data.md v0.4 5절 (반영 완료) |
| DR-29 | TLS 1.2로 그대로 유지 | security.md v0.10 (TLS 정책 변경 없음) |
| DR-30 | 기각 | 없음 |
| DR-31 | 자동 업그레이드를 끈다 | data.md v0.5 2·3절, 검증 항목 (반영 완료) |
| DR-32 | MVP용 인프라이기 때문에 기각 | 없음 |
| DR-33 | 로그가 빠지는 것은 상관 없음 | 없음 (K-01과 함께 수집 범위를 늘리지 않음) |
| DR-34 | 기각 | 없음 |
| DR-35 | 기각 | 없음 |
| K-01 | Alloy 수집 대상은 앱 로그만 | compute.md v0.6 2절 (반영 완료) |
| K-02 | S3 버전 관리 킨다 → 확인 질문 답: 삭제 전에 버킷을 수동으로 비우는 절차를 05에 넣는다 | security.md v0.10~0.11 2.2절, 검증 항목 (반영 완료). 05 작성 때 버킷 비우기 절차를 넣는다 |
| K-03 | 데이터 계층 전송 암호화 결정 → 확인 질문 답: (b) DR-07을 바꿔 전송 암호화를 켠다. 이 경우 Redis 인증 토큰도 쓸 수 있게 됩니다 | security.md v0.11, data.md v0.6, ADR-009 (반영 완료). DR-07 결정을 대체 |
| K-04 | Terraform 코드에 IAM 리소스 생성을 넣지 않는다 → 확인 질문 답: 01 FR-11에 IAM은 예외라는 문구를 넣습니다. | compute.md v0.6 2절, 01 v1.4 FR-11·2.1 (반영 완료, 01 재승인 대기) |

---

## 2026-11-12 — 04-design/security.md 남은 결정 (설계 리뷰 통합 이후)

> design-review-summary.md 밖에서 내린 결정이다. summary의 결정 기록은 위 "설계 전체 리뷰" 항목에 있다.

| ID | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| S-06 | *.imcommerce.shop 와일드카드 1개 | security.md v0.13 2.1절·5절 (반영 완료) |
| S-09 | (A) 사용자 지정 파라미터 그룹에 require_secure_transport=ON | security.md v0.13 2.1절·5절, data.md v0.8 2절 (반영 완료) |
| S-10 | (A) 쓴다 | security.md v0.13 2.1절·5절, data.md v0.8 3절, ADR-009 후속 조치 (반영 완료) |
| S-11 | (A) RDS처럼 임시 토큰으로 만들고 구축 뒤 바꿉니다. ADR-009의 예외를 Redis까지 넓히는 방식입니다. | ADR-009 결정 절·단점·후속 조치, security.md v0.14 2.3절, data.md v0.9 3절 (반영 완료) |

---

## 2026-11-12 — ADR 대체 처리

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| ADR-012 (ADR-007 대체, 설계 리뷰 DR-15) | ADR-012 확정 | ADR-012 상태 Accepted, ADR-007 상태 대체됨(ADR-012) (반영 완료) |

---

## 2026-11-14 — 05 1단계(Terraform 골격) 구현 중 질문

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 버전 고정 | 부 버전 범위 (Recommended) — Terraform `~> 1.17`, AWS 프로바이더 `~> 6.73` | terraform/versions.tf, terraform/README.md (반영 완료) |
| 공통 태그 | 태그 3개 (Recommended) — `Project=imcommerce`, `Environment=prod`, `ManagedBy=terraform` | terraform/providers.tf, terraform/README.md (반영 완료) |
| 변수 범위 | 루트 입력 전부 지금 선언 (Recommended) — 운영자 IP, SSH 공개 키, 임시 RDS 비밀번호·Redis 토큰(sensitive), CodeDeploy 서비스 역할 ARN. 문서에 정해진 값은 locals | terraform/variables.tf, terraform/README.md 2절 (반영 완료) |
| 버전 고정 변경 | `required_version = "1.17.2"`, aws `version = "6.71.0"` (결정자가 준 terraform 블록) | terraform/versions.tf, terraform/README.md, .terraform.lock.hcl (반영 완료). 앞의 "버전 고정" 결정을 대체 |

---

## 2026-11-14 — 모듈 작성 전 결정 항목 (A·B)

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| A-1 이름 규칙 | naming_convention: pattern: "{project}-{environment}-{resource}-{role}", project: commerce, environment: prod | 05 v1.2 2절 (반영 완료) |
| A-1 확인 질문 | 공통 태그 Project를 "commerce로 변경 (Recommended)" | terraform/providers.tf, README (반영 완료) |
| A-2 ACM·DNS | ACM에서 인증서를 만드는 방식으로 변경하고 Route53 퍼블릭 호스팅 영역만 테라폼에서 생성하고 레코드는 terraform에서 만들지 않고 추후 수동으로 생성하는 방식으로 변경합니다. | network.md v1.2 4.5절, security.md v1.1 2.1절, 05 v1.2 (반영 완료) |
| A-2 확인 질문 | "인증서는 Terraform (Recommended)" — 인증서 요청은 Terraform, DNS 검증 CNAME은 수동 | 같음 |
| A-3 AMI | AMI는 "ami-05b829d75c9f9183e" 를 사용하겠습니다. (조회 결과: ubuntu-noble-24.04-amd64-server-20261108, Canonical 099720109477, x86_64) | compute.md v1.1 2절 (반영 완료) |
| A-4 CodeDeploy | CodeDeploy 배포그룹은 수동으로 구축하겠습니다. | compute.md v1.1, 05 v1.2 (반영 완료) |
| A-4 확인 질문 | "앱은 TF, 그룹은 수동 (Recommended)" — 앱 서버 Service 태그는 Terraform이 붙임 | 같음, terraform/variables.tf에서 codedeploy_service_role_arn 삭제 (반영 완료) |
| A-5 RDS | RDS 마스터 사용자 이름은 "dbadmin", 처음 스키마 이름은 "imcommerce"으로 확정하겠습니다. | data.md v1.1 2절 (반영 완료) |
| A-6 MySQL 버전 | mysql 엔진 버전은 "8.0"을 사용하겠습니다. | 아래 확인 질문으로 대체 |
| A-6 확인 질문 | "8.4로 변경 (Recommended)" — 8.0은 표준 지원 종료(2026-07-31)로 확장 지원 요금. 8.4 최신 부 버전 8.4.13(2026-11-14 조회) | data.md v1.1 2절 (반영 완료) |
| A-7 S3 | S3 버킷 이름은 "commerce-prod-codedeploy-artifacts"으로 확정 (2026-11-14 조회: 사용 가능) | security.md v1.1 2.2절, 05 v1.2 (반영 완료) |
| A-8 CodeDeploy 이름 | 1번 규칙을 따릅니다. | 05 v1.2 2절 (반영 완료) |
| A-9 Git | git pr은 나중에 해당 프로젝트가 완성되면 한번에 push 하겠습니다. | 05 v1.2 읽는 법, 9절 ① (반영 완료) |
| B R-04 | Redis는 복제 그룹 리소스로 지정하겠습니다. | data.md v1.1 3절, 05 R-04 (반영 완료) |
| B R-03 | NLB가 AZ Cross를 허용하지 않도록 하고 ALB와 NLB가 같은 AZ subnet에 배치되도록 합니다. | network.md v1.2 4.4절, 05 R-03 (반영 완료) |
| B R-02 | CodeDeploy 설치는 추후 수동으로 할 예정이니 여기서는 확인하지 않습니다. | 05 R-02 (반영 완료) |

---

## 2026-11-14 — VPC·서브넷 대역 변경

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| VPC·서브넷 | VPC와 서브넷 대역을 바꾸겠습니다. VPC : 192.168.0.0/24 (서브넷 표: /27 8개 — Public(Bastion, NAT Gateway) `.0/27` 2a, Public(NLB) `.128/27` 2a, Private(ALB) `.64/27` 2a·`.224/27` 2c, Private(App, 로그 모니터링 서버) `.32/27` 2a, Private(Redis) `.160/27` 2a, Private(RDS) `.192/27` 2a·`.96/27` 2c) | network.md v1.3 1.1·2·3·5·6·7절(public-b·private-log-a 삭제, N-05 변경), ADR-012 개정, 03 v1.7, security.md v1.2, compute.md v1.2, 05 v1.3, terraform/README.md (반영 완료) |
| N-08 | ElastiCache 서브넷은 1개만 사용하겠습니다. | network.md v1.3 2절·N-06·N-08, data.md v1.2 3절, 05 v1.3 R-04 (반영 완료) |

## 2026-11-15 — 승인

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 일괄 반영·승인 | 현재까지 요청했던 부분과 관련된 모든 문서 내용을 수정해주시고 자동 승인 후 버전 업 해주세요 | 03 v1.7, network.md v1.3, security.md v1.2, compute.md v1.2, data.md v1.2, 05 v1.3 Approved, ADR-012 개정 승인 (반영 완료) |

---

## 2026-11-15 — 05 2단계(network 모듈) 구현 중 질문

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| Name 태그(VPC·IGW·NAT·EIP) | "role 채우기" — `commerce-prod-vpc-main`, `commerce-prod-igw-main`, `commerce-prod-nat-public-a`, `commerce-prod-eip-nat-public-a` | terraform/modules/network/main.tf, terraform/README.md (반영 완료) |
| 자격 증명 | local에서 aws login 후 배포 할 예정 입니다. | terraform/README.md 1.2절 (반영 완료) |
| 키 페어 | ssh_public_key는 이미 AWS에 만들어진 키 페어를 사용할 예정입니다. / admin, b2b, b2c 서버는 commerce-prod-app-key 키페어 사용 / 로그 모니터링 서버는 commerce-prod-log-key 키페어 사용 / bastion 서버는 commerce-prod-bastion-key 키페어 사용 | compute.md v1.3 2절, 05 v1.4, terraform/variables.tf·README (반영 완료) |
| RDS 비밀번호 | rds_temp_master_password 는 RDS에서 기본으로 제공하는 password를 사용할 예정입니다. → 확인 질문: "RDS 관리형 비밀번호" (manage_master_user_password, Secrets Manager) | ADR-013, data.md v1.3 2절, security.md v1.3 2.3절, 05 v1.4 (반영 완료) |
| Redis 토큰 | redis_temp_auth_token 는 사용하지 않습니다. → 확인 질문: "토큰 없음, TLS 유지" | ADR-013, security.md v1.3 S-10·S-11·2.1·2.3·5절, data.md v1.3 3절, 05 v1.4 (반영 완료) |
| ADR 처리 | "새 ADR로 대체" — ADR-009 → ADR-013, ADR-012(직접 고친 내용 되돌림) → ADR-014 | ADR-009·ADR-012 상태 대체됨, ADR-013·ADR-014 Accepted (반영 완료) |
| 실행 자격 증명 | AWS 루트 계정으로 실행하겠습니다. → 확인 질문: "Terraform만 루트"(GitHub Actions는 IAM 사용자 키 유지, 루트 액세스 키 만들지 않음), "00·01 수정" | 00 v1.7 3.4·Q-20, 01 v1.5 NFR-07·CON-13, 03 v1.9, security.md v1.4 2.3·5절, 05 v1.5, terraform/README.md·providers.tf (반영 완료) |
| 2단계 apply | terraform apply tfplan 을 진행해주세요 — 05 AI-01("AI가 apply를 실행하지 않는다")의 1회 예외로 AI가 실행. 05 규칙은 바꾸지 않음 | terraform/README.md 4절 검증 기록 (반영 완료) |

---

## 2026-11-15 — 05 3단계(security 모듈) 구현 중 질문

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| SG 규칙 방식 | 별도 규칙 리소스 (Recommended) — `aws_vpc_security_group_ingress_rule`·`_egress_rule`. security.md 1.2절 규칙에는 순환 참조가 없음(인라인 블록과 비교) | terraform/modules/security/main.tf, terraform/README.md (반영 완료) |
| SG 설명 | 영문으로 붙는 곳 (Recommended) — security.md 1.1절 "붙는 곳"·"서브넷"을 영문으로(AWS가 한글을 받지 않음, 바꾸면 SG 재생성) | terraform/modules/security/main.tf (반영 완료) |
| 규칙 설명 | 영문으로 붙임 (Recommended) — 예: "HTTPS from internet (DR-02)" | terraform/modules/security/main.tf (반영 완료) |
| 3단계 apply | terraform apply를 실행해주세요 — 05 AI-01의 1회 예외로 AI가 `apply tfplan` 실행(2단계와 같은 방식). 05 규칙은 바꾸지 않음 | terraform/README.md 4절 검증 기록 (반영 완료) |

---

## 2026-11-15 — 05 4단계(dns_cert 모듈) 구현 중 질문

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 가비아 미사용 | 결정자가 가비아를 쓰지 않기로 함(4단계 지시). 조회 결과: 계정에 호스팅 영역 0개, Route 53 Domains 등록 도메인 0개, `dig NS imcommerce.shop` NXDOMAIN(`.shop` 레지스트리) | 00 Q-37 등록 |
| Q-37 ① 레지스트라 | "Route 53 Domains" — 이 AWS 계정에서 등록. 등록은 Terraform 밖 수동 작업 | 00 v1.8 3.4·A-05·Q-37, 01 v1.6 CON-10, 03 v1.10 구성도·외부 시스템 표, network.md v1.6 4.5절, 05 v1.6, terraform/README.md 3절 (반영 완료) |
| Q-37 ② 호스팅 영역 | "Terraform으로 새로 만듦 (Recommended)" — network.md 4.5절 그대로. 등록 때 AWS가 자동으로 만드는 호스팅 영역은 운영자가 도메인 네임서버를 Terraform 영역 것으로 바꾼 뒤 수동 삭제 | network.md v1.6 4.5절, README 3절 4번 (반영 완료) |
| Q-37 ③ 문서 범위 | "전부 갱신 (Recommended)" — 00·01·03·network.md·05·README·루트 outputs.tf 주석. discovery/questions.md와 reviews/는 당시 기록이라 고치지 않음 | 같음 (반영 완료) |
| Name 태그 | "route53-main / cert-wildcard" — `commerce-prod-route53-main`, `commerce-prod-cert-wildcard` | terraform/modules/dns_cert/main.tf, README (반영 완료) |
| 키 알고리즘 | "RSA_2048 (Recommended)" — ACM 기본값을 코드에 명시 | terraform/modules/dns_cert/main.tf (반영 완료) |
| 인증서 lifecycle | "넣지 않음" — `create_before_destroy`를 쓰지 않음(기본 동작: 삭제 뒤 생성) | terraform/modules/dns_cert/main.tf (반영 완료) |
| force_destroy | "false (Recommended)" — 기본값을 코드에 명시. network.md 4.5절 삭제 절차·05 R-19 그대로 | terraform/modules/dns_cert/main.tf (반영 완료) |
| 4단계 apply | terraform apply를 해주세요 — 05 AI-01의 1회 예외로 AI가 `apply tfplan` 실행(2·3단계와 같은 방식). 05 규칙은 바꾸지 않음. 첫 요청은 `aws login` 만료(ExpiredToken)로 실행하지 않았고, 재로그인 뒤 같은 요청으로 실행. 직전 답변의 미결 항목(Name 태그 `commerce-prod-zone-imcommerce` 제안, D-032 출처, ACM 포함 여부)은 답이 없어 기존 결정대로 적용 | terraform/README.md 4절 검증 기록 (반영 완료) |

---

## 2026-11-15 — 05 5단계(compute 모듈) 구현 중 질문

> 질문 전 확인: 루트 볼륨 유형·크기·암호화, 종료 시 볼륨 삭제, Bastion 공인 IP 방식(자동 할당)은 compute.md 2절에 이미 값이 있어 묻지 않았다. 조회(2026-11-15): 키 페어 3개 서울 리전에 있음, AMI `ami-05b829d75c9f9183e` `available`·Canonical·x86_64·루트 8GB gp3·`ImdsSupport=v2.0`, t3.medium·t3.large가 ap-northeast-2a에서 제공됨. 05 6절에서 5단계에 확인할 "(확인 필요)" 항목은 없음(R-02는 결정자 지정으로 에이전트 설치 때 확인, R-05는 9-a 뒤 `plan`으로 확인). 04·ADR과 다르게 한 곳 없음

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| Name 태그 | "ec2-app-admin 형식 (Recommended)" — `commerce-prod-ec2-app-admin`·`-ec2-app-b2b`·`-ec2-app-b2c`·`-ec2-log`·`-ec2-bastion` | terraform/modules/compute/main.tf, README (반영 완료) |
| IMDSv2 | "명시: required (Recommended)" — `http_endpoint = enabled`, `http_tokens = required`(AMI 기본과 같음) | terraform/modules/compute/main.tf (반영 완료) |
| user_data | "쓰지 않음 (Recommended)" — 05 1.1절·README 3절 8번(수동 설치) 그대로 | terraform/modules/compute/main.tf (반영 완료) |
| 종료 보호 | "끔, 코드에 false 명시 (Recommended)" — `disable_api_termination = false` | terraform/modules/compute/main.tf (반영 완료) |
| 루트 볼륨 Name 태그 | "붙임: ebs-root-app-admin 등 (Recommended)" — `commerce-prod-ebs-root-<role>` | terraform/modules/compute/main.tf (반영 완료) |
| 사설 IP | "AWS 자동 할당 (Recommended)" — `private_ip` 쓰지 않음 | terraform/modules/compute/main.tf (반영 완료) |
| 나머지 기본값 | "모두 명시 (Recommended)" — `monitoring = false`, `disable_api_stop = false`, `instance_initiated_shutdown_behavior = "stop"`, `http_put_response_hop_limit = 2` | terraform/modules/compute/main.tf (반영 완료) |
| 5단계 apply | terraform apply 를 해주세요 — 05 AI-01의 1회 예외로 AI가 `apply tfplan` 실행(2·3·4단계와 같은 방식). 05 규칙은 바꾸지 않음 | terraform/README.md 4절 검증 기록 (반영 완료) |

---

## 2026-11-15 — 05 6단계(data 모듈) 구현 중 질문

> 질문 전 확인(2026-11-15, 루트 `aws login`, ap-northeast-2): MySQL 8.4.13 `available`(`mysql8.4`, 8.4 최신), db.t3.micro·gp3(최소 20GB)·저장 암호화 주문 가능(ap-northeast-2a 포함), `default.mysql8.4`의 `require_secure_transport`는 값 없음(`dynamic`, 수정 가능), Redis OSS 7.1 제공(`redis7`, 7.x 최신), cache.t3.micro 제공. R-04: AWS 문서의 전송 중 암호화 조건은 복제 그룹·VPC·명시적 `TransitEncryptionEnabled`뿐이고 노드 수·서브넷 수 제한은 없음(apply 때 최종 확인). R-21: 관리형 비밀번호는 기본 7일마다 교체되고 주기는 바꿀 수 있음(최대 999일), DB 삭제 때 시크릿도 삭제됨(AWS 문서). 교체를 끄는 방법은 공식 문서로 확인하지 못함(re:Post에 콘솔 "Disable automatic rotation" 답변). 04·ADR과 다르게 한 곳 없음. data.md에 값이 있는 항목(최종 스냅샷, 백업 0일, 유지 관리 창, 스냅샷 0일, 삭제 방지 등)은 묻지 않음

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| R-21 자동 교체 | "Terraform 밖에서 끄기 (Recommended)" — apply 직후 운영자가 시크릿 자동 교체를 끈다(콘솔 "Disable automatic rotation"). 꺼지지 않으면 주기를 999일로 바꾼다. 시크릿은 Terraform 리소스가 아니므로 코드·ADR 변경 없음 | docs/04-design/data.md v1.5 2절, terraform/README.md 3절 9-1번 (반영 완료) |
| 이름·Name 태그 | "리소스 종류 + 대상 (Recommended)" — `commerce-prod-rds-mysql`, `commerce-prod-dbsubnet-mysql`, `commerce-prod-dbparam-mysql84`, `commerce-prod-redis-session`, `commerce-prod-cachesubnet-redis` | terraform/modules/data/main.tf, README (반영 완료) |
| apply_immediately | "true 명시 (Recommended)" — RDS·ElastiCache 모두. 대기 중 변경으로 plan 차이가 남지 않게 함(FR-11) | terraform/modules/data/main.tf (반영 완료) |
| Redis 전송 암호화 모드 | "required 명시 (Recommended)" — `transit_encryption_mode = "required"`(security.md 2.1절 Bastion → Redis TLS 필수) | terraform/modules/data/main.tf (반영 완료) |
| 6단계 apply | terraform apply 해주세요 — 05 AI-01의 1회 예외로 AI가 `apply tfplan` 실행(2~5단계와 같은 방식). 05 규칙은 바꾸지 않음. Redis 생성 대기 중 `aws login` 만료(ExpiredToken)로 apply가 멈춰 Redis가 tainted로 남음 | terraform/README.md 4절 검증 기록 (반영 완료) |
| Redis untaint | untaint로 진행해주세요 — 재로그인 뒤 Redis `available`·설정이 plan과 같음을 확인하고 `terraform untaint`. 이어서 출력값만 State에 저장(리소스 변경 0). `plan -detailed-exitcode` 0 | terraform/README.md 4절 검증 기록 (반영 완료) |

---

## 2026-11-15 — 05 7단계(edge 모듈) 구현 중 질문

> 시작 전 확인(2026-11-15, 루트 `aws login`, ap-northeast-2): ACM `*.imcommerce.shop`(`…certificate/5d1ce3d5-…`) `PENDING_VALIDATION`. README 3절 4번 미완료(`route53domains get-domain-detail` "not found in account", `list-domains` 0개, `check-domain-availability` `AVAILABLE`). 4-a(`dig NS` 응답 없음)·4-1(호스팅 영역 `Z09113121195Y9EQDKADH`에 NS·SOA뿐) 미완료. 4-b는 등록 전이라 자동 생성 영역이 없음(이 이름의 영역은 Terraform 것 하나)

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| R-20 적용 | "코드·plan만 먼저 (Recommended)" — 결정자가 "이번 배포도 이전 배포처럼"(인증서 발급 확인 없이 진행)을 요청. HTTPS 리스너는 `ISSUED` 인증서가 있어야 만들어지므로 `ISSUED` 확인을 7단계 **apply 전 조건**으로 좁혀 적용한다. 지금은 확인 → 질문 → 코드 → `fmt`·`validate`·`plan`까지만 하고, apply는 3절 4·4-b·4-a·4-1 수동 작업과 `ISSUED` 확인 뒤에 한다. 05 R-20 문구("`ISSUED`를 확인한 뒤 7단계로 간다")는 바꾸지 않고 이번 1회 적용 범위로 기록 | terraform/README.md 4절 검증 기록 |

> 질문 전 확인(2026-11-15, AWS 문서·`describe-ssl-policies`): ① NLB(AZ 1개) → ALB(AZ 2개) 가능(같은 AZ는 권장일 뿐). 교차 영역 기본값 `false`, 끄면 NLB 노드는 같은 AZ 대상에만 보냄 ② 대상 종류 `alb`: 대상 그룹 프로토콜 TCP만, 포트는 ALB 리스너 포트와 같아야 함, 상태 확인 HTTP/HTTPS만, 성공 코드 200~599, 대상 그룹 속성 변경 불가, ALB에 같은 포트 리스너가 있어야 등록됨 ③ 상태 확인 Host 헤더는 NLB 노드 IP → ALB 기본 동작 404 응답. TLS 1.3만 받는 대상은 HTTPS 상태 확인 실패(정한 정책은 1.2도 받음) ④ 대상 SG가 NLB SG를 트래픽·상태 확인 포트로 참조하면 됨. 상태 확인은 NLB SG 아웃바운드를 따름 ⑤ Terraform·CLI로 만든 HTTPS 리스너의 기본 정책은 `ELBSecurityPolicy-2016-08`(TLS 1.0~1.2) → 명시 필요. `ELBSecurityPolicy-TLS13-1-2-2021-06`은 TLS 1.2·1.3. 참고: 현재 콘솔 기본값은 `ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09`로 security.md 2.1절 근거 문구("콘솔 권장 기본 정책")와 다름. 정책 값은 DR-29대로 유지. 04·ADR과 다르게 할 곳 없음. 문서에 값이 있는 항목(ALB 대상 그룹 상태 확인 표, TLS 정책, 교차 영역 끔, 기본 동작 404)은 묻지 않음. NLB EIP는 `subnet_mapping.allocation_id`밖에 방법이 없어 묻지 않음

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 이름·Name 태그 | "체계·대상 표시 (Recommended)" — `commerce-prod-alb-internal`(26자), `commerce-prod-nlb-public`(24자), `commerce-prod-eip-nlb`, `commerce-prod-tg-app-admin`·`-tg-app-b2b`·`-tg-app-b2c`, `commerce-prod-tg-nlb-alb`. 모두 32자 이하 | terraform/modules/edge/main.tf, README |
| 앱 서버 대상 등록 | "Terraform attachment (Recommended)" — `aws_lb_target_group_attachment` 3개(포트 8080, compute 모듈 `instance_ids`) | terraform/modules/edge/main.tf |
| 호스트 규칙 우선순위 | "10·20·30 (Recommended)" — admin 10, b2b 20, b2c 30 | terraform/modules/edge/main.tf |
| 잘못된 헤더 필드 삭제 | "끔, false 명시" — `drop_invalid_header_fields = false`(AWS 기본값) | terraform/modules/edge/main.tf |
| 삭제 보호 | "끔, false 명시 (Recommended)" — ALB·NLB `enable_deletion_protection = false` | terraform/modules/edge/main.tf |
| ALB 유휴 시간 | "60초 명시 (Recommended)" — `idle_timeout = 60`(AWS 기본값) | terraform/modules/edge/main.tf |
| NLB 대상 그룹 상태 확인 나머지 값 | "AWS 기본값 명시 (Recommended)" — 간격 30초, 타임아웃 10초, 정상 5회, 비정상 2회(생략하면 프로바이더 기본 임계값 3·3이 들어감) | docs/04-design/network.md v1.7 5.3절, terraform/modules/edge/main.tf |
| 리스너·규칙 Name 태그 | "붙임 (Recommended)" — `commerce-prod-listener-alb-https`, `commerce-prod-listener-nlb-tcp`, `commerce-prod-rule-admin`·`-rule-b2b`·`-rule-b2c` | terraform/modules/edge/main.tf |
| 7단계 apply | "그대로 진행합니다" — 마지막 plan(`tfplan`, 16개 추가)으로 `apply tfplan`을 AI가 실행(05 AI-01 1회 예외, 2~6단계와 같은 방식. 05 규칙은 바꾸지 않음). 실행 직전 확인: 인증서 `PENDING_VALIDATION`(요청 2026-11-15 02:08 KST, 72시간 기한 약 2026-11-18 02:08), 등록 도메인 0개. HTTPS 리스너·규칙 3개·NLB→ALB 등록이 실패하고 일부만 생성되는 것을 결정자가 감수(C안). 대안 A(`ISSUED` 뒤 한 번에)·B(`-target`으로 11개만)는 채택하지 않음. 앞서 정한 "R-20 적용"(apply는 `ISSUED` 뒤)을 이번 apply에 한해 바꿈 | terraform/README.md 4절 검증 기록 |

---

## 2026-11-15 — 05 8단계(deploy 모듈) 구현 중 질문

> 질문 전 확인(2026-11-15, 루트 `aws login` `arn:aws:iam::<account-id>:root`, ap-northeast-2): `aws s3api head-bucket --bucket commerce-prod-codedeploy-artifacts` 결과 `404 Not Found`(전역에 같은 이름 버킷 없음, 다른 계정 소유면 `403`) → 이름 사용 가능. 이 계정 버킷 0개, CodeDeploy 애플리케이션 0개, State에 `s3`·`codedeploy` 리소스 0개. 계정 수준 S3 퍼블릭 액세스 차단은 설정 없음(04에 없어 건드리지 않음, AI-02). 05 6절·security.md·compute.md에 8단계에서 확인할 "(확인 필요)" 항목 없음(A-06 에이전트는 05 R-02대로 9-b에서). 참고: 버전 관리와 상관없이 `force_destroy = false` 버킷은 객체·이전 버전이 남아 있으면 `destroy`가 `BucketNotEmpty`로 실패(R-11·K-02 수동 비우기 절차와 맞음, 문서 변경 없음). 04·ADR과 다르게 할 곳 없음. 문서에 값이 있는 항목(버킷 이름, SSE-S3 `AES256`, 퍼블릭 차단 4개, 버전 관리, 플랫폼 EC2/온프레미스)은 묻지 않음. 아래 결정은 모두 04 값을 바꾸지 않으므로(AWS 기본값과 같거나 04에 없는 이름·태그) 04 설계 문서는 고치지 않고 ai-log와 README에 기록한다(AI-08)

| 항목 | 결정 내용 (원문) | 반영 위치 |
|---|---|---|
| 버킷 force_destroy | "false 명시 (Recommended)" — `force_destroy = false`. 05 R-11·K-02 수동 비우기 절차, README 3절 11번 그대로 | terraform/modules/deploy/main.tf, README (반영 완료) |
| 객체 소유권 | "명시하지 않음 (Recommended)" — `aws_s3_bucket_ownership_controls`를 만들지 않음(AI-02). AWS 기본값 `BucketOwnerEnforced`를 apply 뒤 확인만 함 | terraform/modules/deploy/main.tf(주석), README (반영 완료) |
| bucket_key_enabled | "false 명시 (Recommended)" — SSE-S3에서는 효과 없음, KMS를 쓰지 않음을 명시 | terraform/modules/deploy/main.tf (반영 완료) |
| CodeDeploy 애플리케이션 이름·Name 태그 | "-codedeploy-app + Name 태그 (Recommended)" — `commerce-prod-codedeploy-app`. 버킷·애플리케이션 모두 Name 태그 = 리소스 이름 | terraform/modules/deploy/main.tf, README (반영 완료) |
| 8단계 apply | apply 해주세요 — 05 AI-01의 1회 예외로 AI가 `apply tfplan` 실행(2~7단계와 같은 방식. 05 규칙은 바꾸지 않음). 실행 직전 인증서 `PENDING_VALIDATION`이라 plan의 edge 5개 중 `alb_https`가 실패할 것을 직전 보고에 적었고, 결정자가 그대로 지시. `-target`은 쓰지 않음(결정자 지시). 결과: deploy 5개 생성, `alb_https` `UnsupportedCertificate`로 실패(7단계 1차와 같음) | terraform/README.md 4절 검증 기록 (반영 완료) |
