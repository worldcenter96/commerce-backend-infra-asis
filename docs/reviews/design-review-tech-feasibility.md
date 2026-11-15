# 설계 리뷰 — 구현 가능성 (01·02·ADR·03·04-design)

| 항목 | 값 |
|---|---|
| 검토 대상 | [01-requirements.md](../01-requirements.md) v1.3 (Approved) |
| | [02-options.md](../02-options.md) v1.3 (Approved) |
| | [adr/](../adr/) ADR-001~ADR-011 (머리 표에 버전 없음. 상태는 모두 Accepted, ADR-009는 "Accepted (세부 방식 미정)") |
| | [03-architecture.md](../03-architecture.md) v1.4 (Approved) |
| | [04-design/network.md](../04-design/network.md) v0.8 (Draft) |
| | [04-design/security.md](../04-design/security.md) v0.7 (Draft) |
| | [04-design/compute.md](../04-design/compute.md) v0.3 (Draft) |
| | [04-design/data.md](../04-design/data.md) v0.2 (Draft) |
| | 04-design/cicd.md — **설계 문서 없음**. CI/CD 값은 FR-08, ADR-002, 03 4-2절, compute.md 2절에서 모아 비교했다 |
| 검토일 | 2026-11-12 |
| 검토자 | 구현 가능성 리뷰 에이전트 |

> **검토 기준**
> - 관점 1: 05 구현 계획에서 만들 범위를 기준으로, 복잡도가 과하거나 구현을 막는 부분. 기준은 구축 2일(CON-03), 단일 운영자(CON-12), 숙련도는 AWS 중·최근 2년 공백, Terraform 중(02 읽는 법, Q-19)이다.
> - 관점 2: 04 파일 사이의 값 충돌(network ↔ security ↔ CI/CD), 04 ↔ 03·ADR 충돌.
> - ~~취소선~~은 대체된 기록이라 현재 내용으로 보지 않았다. **미정**은 결정 안 된 것 자체가 구현을 막는지만 판단했다.
> - "AWS 공식 권장사항(일반 지식)" / "AWS 사양(일반 지식)"은 리뷰어가 알고 있는 지식이다. 웹으로 확인하지 않았다.

---

## 1. 요약

| 관점 | Critical | Major | Minor | Suggestion | 합계 |
|---|---|---|---|---|---|
| 관점 1: 복잡도·구현 가능성 | 1 | 9 | 0 | 2 | 12 |
| 관점 2: 문서 간 충돌 | 0 | 4 | 6 | 0 | 10 |
| **합계** | **1** | **13** | **6** | **2** | **22** |

- **가장 큰 위험**: 앱 서버 IAM 인스턴스 프로파일을 "인프라 구축 완료 뒤 별도 구성"으로 미뤘고(compute.md C-01), CodeDeploy 서비스 역할도 어디에도 없다. 이대로면 FR-08(배포)과 FR-11(전체 IaC)이 함께 막힌다(COST-01).
- CI/CD 설계 문서가 없다. 배포 그룹, appspec, 아티팩트 버킷 구조, 에이전트 설치 방식이 흩어져 있거나 정해지지 않았다(COST-02).
- 생성할 때만 정할 수 있는 값(NLB 출발지, Redis TLS·인증 토큰, 저장 암호화, 엔진 부 버전)이 미정이라 해당 리소스의 Terraform 코드를 쓸 수 없다(COST-08, COST-09).
- 상시 과금과 "예산 초과까지 남은 일수"가 문서마다 다르다($3.94/23일, 28일, $3.58/25일)(COST-06).

## 2. 발견 사항

| ID | 심각도 | 위치(파일/절) | 문제 | 근거 | 영향 | 제안 |
|---|---|---|---|---|---|---|
| COST-01 | Critical | compute.md 2절 "IAM 인스턴스 프로파일", 5절 C-01. 03 5절, ADR-002 | 앱 서버의 IAM 인스턴스 프로파일(S3 읽기, CodeDeploy 에이전트 권한)을 "인프라 구축 완료 뒤 별도로 구성"으로 미뤘다. CodeDeploy 배포 그룹에 필요한 **서비스 역할**은 03, ADR-002, 04 어디에도 없다. ADR-002 단점에 "서비스 역할을 관리해야 한다"고만 적혀 있다. "별도 구성"이 Terraform 밖에서 하는 것인지도 정해지지 않았다 | FR-08 (Must), FR-11 (Must), FR-12 (Must), ADR-002. AWS 사양(일반 지식): EC2 대상 CodeDeploy 에이전트는 인스턴스 프로파일 자격 증명으로 CodeDeploy를 폴링하고 S3에서 리비전을 받는다. 배포 그룹을 만들 때 서비스 역할 ARN이 필수다 | 프로파일이 없으면 에이전트가 배포 명령을 받지 못해 FR-08이 실패한다. 서비스 역할이 없으면 배포 그룹을 만들 수 없다. Terraform 밖에서 붙이면 `plan -detailed-exitcode`에 차이가 생겨 FR-11 검증이 실패하고, `destroy`에서 빠져 FR-12 검증(state 0줄, 다음 날 비용 0)도 어렵다 | 05 전에 04에 IAM 항목을 넣는다: (1) EC2 역할 + 인스턴스 프로파일(대상 버킷 `s3:GetObject`, 에이전트 설치 버킷 읽기), (2) CodeDeploy 서비스 역할(관리형 정책 `AWSCodeDeployRole`). 둘 다 Terraform으로 만든다. 인스턴스 프로파일은 나중에 붙여도 되지만 그것도 Terraform 변경으로 한다. 대안으로 IAM 사용자 키를 에이전트에 넣는 온프레미스 등록 방식이 있지만, 배포 그룹 대상 지정 방식이 바뀌므로 결정자에게 비교를 요청한다 |
| COST-02 | Major | 04-design (cicd.md 없음). FR-08, ADR-002, 03 4-2절, compute.md 2절 | CI/CD 상세 설계 문서가 없다. 흩어진 내용으로는 다음 값이 정해지지 않았다: CodeDeploy 애플리케이션 이름, 배포 그룹 3개의 대상 지정 방식(EC2 태그 키·값), 배포 설정(예: `CodeDeployDefault.AllAtOnce`), appspec 훅 스크립트(ApplicationStop/BeforeInstall/ApplicationStart/ValidateService), 아티팩트 버킷 이름·키 구조(FR-08 검증은 `s3://<버킷>/<서비스>/`를 전제), 버킷 버전 관리, GitHub Actions 워크플로 개수·트리거·자격 증명 보관 위치, 에이전트·Java 17·Alloy 설치 방식(사용자 데이터인지 수동인지) | FR-08 (Must), NFR-08, NFR-10, NFR-11 (Must), ADR-002 | 05에서 배포 경로를 작업 단위로 쪼갤 수 없다. 서버 프로비저닝(에이전트 설치)과 배포(appspec)의 경계가 정해지지 않아 구축 2일 중 가장 늦게 막히는 부분이 된다 | 04-design에 cicd.md를 만들거나 compute.md에 절을 추가해 위 값을 정한다. NFR-10을 위해 배포 그룹은 서비스 태그(예: `Service=admin`)로 한 대씩만 고르게 한다. 에이전트 설치 방식은 사용자 데이터와 수동 설치를 비교해 결정자에게 요청한다 |
| COST-03 | Major | ADR-010 "결정" 4번째 줄. network.md 2절·4.4절, security.md 1.1절 | ADR-010은 "NLB는 AZ-A의 퍼블릭 서브넷(**public-a**) 하나에만" 둔다고 적었다(취소선 없음). network.md와 security.md는 NLB를 **public-nlb-a**(`10.0.2.0/24`)에 두고, public-a에는 Bastion·NAT Gateway를 둔다 | ADR-010, network.md N-03, security.md 1.1 | 05에서 NLB 서브넷 ID를 어느 문서 기준으로 넣을지 정할 수 없다. 검증 명령(network.md 7절 `<public-nlb-a>`)도 ADR과 맞지 않는다 | ADR-010 문구를 "AZ-A 퍼블릭 서브넷(04 network.md의 public-nlb-a)"으로 고치거나, 04를 ADR에 맞춘다. 어느 쪽인지 결정자에게 요청한다 |
| COST-04 | Major | ADR-007 "결정" 2번째 줄. network.md 2절(서브넷 10개), N-07 | ADR-007은 "서브넷은 AZ 2개에 퍼블릭·프라이빗을 **하나씩** 만든다"고 정했다(취소선 없음). network.md는 결정자 구성도를 따라 퍼블릭 3개, 프라이빗 7개, 모두 10개로 나눴다. N-07은 03과의 차이만 정리했고 ADR-007은 고치지 않았다. 용도별 서브넷 분리는 ADR에서 비교·결정된 적이 없다. 보안 그룹이 SG 참조로만 통제하므로(security.md P-05) 서브넷을 나눠도 접근 통제 효과는 없다(security.md 5절 "허용은 서브넷이 아니라 SG로 갈린다") | ADR-007, CON-02, CON-03, CON-12 | ADR과 04가 다르다. 서브넷·라우팅 연결·검증 대상이 4개에서 10개로 늘어 2일 구축의 Terraform 작업과 검증 명령 수가 함께 늘어난다 | (A) ADR-007을 개정해 용도별 서브넷 10개를 기록한다. (B) ADR-007대로 4개(public-a/b, private-a/b)로 줄인다. 둘을 비교해 결정자에게 요청한다. 구현 부담만 보면 (B)가 작다 |
| COST-05 | Major | 03 3절 다이어그램 아래 첫 줄, 03 3절 `privB` 노드. ADR-007 "단점". 02 12절 표 D-10 행 | 다음 문장이 취소선 없이 남아 현재 결정(ADR-010 NLB 단일 AZ, network.md N-06 캐시 서브넷 그룹 1개)과 맞지 않는다: 03 "AZ-B 서브넷은 **NLB(퍼블릭)**, ALB(프라이빗), DB·**캐시** 서브넷 그룹(프라이빗)처럼 AZ 2개를 요구하는 리소스를 위해 둔다", 03 `privB` "DB·캐시 서브넷 그룹용", ADR-007 "다른 AZ의 **NLB**·ALB 노드는 살아 있어도", 02 12절 "NLB도 퍼블릭 서브넷이 AZ 2개 있어야 한다" | ADR-010, network.md N-03·N-06, 03 v1.4 변경 이력(NLB AZ-A 반영이라고 적음) | 05 작성자가 public-b·private-db-b의 용도를 잘못 읽을 수 있다. 03은 v1.4에서 NLB 변경을 반영했다고 적었지만 이 문장들은 남았다 | 해당 문장을 취소선으로 바꾸고 현재 값(AZ-B 퍼블릭은 예비, AZ-B 프라이빗은 ALB 노드와 RDS 서브넷 그룹용)을 적는다 |
| COST-06 | Major | ADR-004 "예산 영향", ADR-008 "충돌과 후속 조치". ADR-010 "단점", 03 6절 NFR-12, 02 13.2절 | 상시 과금과 "예산 초과까지 일수"가 취소선 없이 서로 다르다. ADR-004: 하루 약 **$3.94**, 약 **23일**. ADR-008: 약 **28일**. ADR-010·03·02: 하루 약 **$3.58**, 약 **25일** | NFR-12 (Must), NFR-13 (Must), CON-01 | 구축 시작일(Q-03)이 미정이라 05에서 "구축 시작부터 삭제까지 며칠 안에 끝내야 하는지"를 일정 제약으로 넣어야 한다. 기준 값이 문서마다 달라 5일 차이가 난다 | ADR-004·ADR-008의 수치를 취소선 처리하고 02 13.2절(하루 약 $3.58, 약 25일)을 가리키게 한다. 05에는 이 값을 일정 상한으로 적는다 |
| COST-07 | Major | network.md 5.3절 "NLB → ALB (전달·상태 확인) TCP 443". 03·04 전체(ALB 리스너 기본 동작) | NLB가 ALB를 대상으로 할 때의 상태 확인을 "TCP 443"으로 적었다. ALB 443 리스너의 **기본 동작**(호스트 규칙 3개에 맞지 않는 요청 처리)도 어느 문서에도 없다 (확인 필요) | FR-06 (Must), FR-13 (Must), ADR-010. AWS 사양(일반 지식): 대상 유형이 `alb`인 NLB 대상 그룹은 상태 확인 프로토콜이 HTTP 또는 HTTPS만 된다. ALB 리스너는 기본 동작이 필수다 | Terraform에서 대상 그룹 생성이 실패하거나, 상태 확인 요청(호스트 헤더가 서비스 도메인이 아님)이 기본 동작으로 가서 비정상으로 판정될 수 있다. ADR-010이 "구축 첫날 확인"으로 미룬 구성에 실패 요인이 하나 더 붙는다 | NLB 대상 그룹 상태 확인을 HTTPS(포트 443, 경로·성공 코드 지정)로 정하고, ALB 기본 동작(예: 고정 응답 404, 상태 확인 경로만 200)을 04에 적는다. 값은 결정자에게 요청한다 |
| COST-08 | Major | security.md 1.2절 sg-nlb 인바운드, 3절 예외 목록, 4절 S-03 | NLB 인바운드 출발지(S-03)가 **미정**이다. security.md 1.1절대로 NLB 보안 그룹은 NLB를 만들 때만 붙일 수 있다 | NFR-06 (Must), FR-02 (Must), FR-06 (Must), ADR-011 후속 조치. AWS 사양(일반 지식): NLB 보안 그룹은 생성 시 지정해야 하고 나중에 처음 붙일 수 없다 | sg-nlb 규칙이 없으면 NLB를 만들 수 없고, 진입 경로 전체(FR-02, FR-03, FR-06, FR-13) 구현이 막힌다. S-03 대안 (B)는 서비스 사용자를 막으므로 FR-02와 충돌한다 | 05 전에 S-03을 결정받는다. 대안 (A) `0.0.0.0/0`만 FR-02·FR-03을 충족한다는 점을 함께 제시한다 |
| COST-09 | Major | security.md 2.1절(앱 → RDS·Redis TLS), 2.2절(저장 암호화), 4절 S-06·S-07·S-08. data.md 2절·3절, 6절 D-01·D-04. ADR-009 후속 조치(Redis 인증 토큰) | 생성할 때만 정할 수 있는 값이 미정이다: Redis 전송 중 암호화·인증 토큰(S-07, ADR-009), RDS·ElastiCache·EBS 저장 암호화(S-08), MySQL·Redis 부 버전(D-01), ACM 이름 범위(S-06). FR-04 검증 명령도 `<인증·암호화 옵션>`으로 비어 있다 | FR-04 (Must), FR-02 (Must), NFR-12 (Must). AWS 사양(일반 지식): ElastiCache 전송 중·저장 암호화와 RDS 스토리지 암호화는 만든 뒤 바꾸려면 다시 만들어야 한다. Redis 인증 토큰은 전송 중 암호화가 전제이며, Terraform에서는 복제 그룹 리소스로 만들어야 할 수 있다 (확인 필요). RDS for MySQL 8.0은 표준 지원이 2026-07-31에 끝나 이후 생성 시 Extended Support 요금이 붙는다 (확인 필요) | RDS·ElastiCache·EBS·ACM 리소스 코드를 쓸 수 없다. S-07 결정에 따라 ElastiCache Terraform 리소스 종류가 바뀔 수 있다. D-01에서 MySQL 8.0을 고르면 NFR-12 비용 산정에 없는 요금이 생길 수 있다 | 05 전에 S-06·S-07·S-08·D-01을 한 번에 결정받는다. D-01 비교에는 8.0의 Extended Support 요금 여부를 넣는다(8.4 권장, 확인 필요). S-07은 앱 설정(Spring Data Redis SSL)과 FR-04 검증 명령의 옵션까지 함께 정한다 |
| COST-10 | Major | ADR-009 후속 조치, 03 4-2절·8절 X-04, security.md 2.2절 "Secret 파일" | Secret 파일을 서버에 넣는 방법·위치·권한이 미정이다. 03 X-04와 ADR-009 모두 "05 전"에 정한다고 적었다 | FR-04 (Must), FR-02·FR-03 (Must, 검증이 기능 경로 `/signup` 접속), FR-13 (Must), ADR-009 | 앱이 DB 비밀번호를 받지 못하면 서비스가 MySQL·Redis에 연결하지 못한다. Spring Boot Actuator 기본 health에 DB·Redis가 포함되면 `/healthz`도 실패한다 (확인 필요). 방법(CodeDeploy 묶음 / Bastion 수동 복사)에 따라 COST-02의 appspec 범위가 달라진다 | 05 전에 주입 방법을 2개 이상 비교해 결정받는다(예: Bastion 경유 수동 복사 vs CodeDeploy 훅). 서버 3대·값 변경 시 3곳 수정(ADR-009 단점)을 일정에 넣는다 |
| COST-11 | Major | compute.md 3절 "시작 순서", 5절 C-04 | 시작 순서를 "정하지 않음. 모든 서버가 가동된 뒤 헬스 체크"로 정했다. 매일 RDS와 앱 서버를 함께 시작하는데(CON-03), 앱이 먼저 뜨면 실패할 수 있다는 위험(03 X-07)은 그대로 남았다. 앱 프로세스의 재시작 정책(예: systemd `Restart=`)도 어느 문서에도 없다 (확인 필요) | NFR-04 (Must), FR-13 (Must), CON-03 | RDS는 시작에 수 분이 걸린다(AWS 사양, 일반 지식). 그 사이 Spring Boot가 DB 연결 실패로 종료되면 재시작 정책이 없는 한 다시 뜨지 않아, NFR-04 검증("시작 직후 3/3 `/healthz` 200")이 운영일마다 실패할 수 있다 | (A) 시작 절차를 "RDS available 확인 → 앱 서버 시작"으로 05에 넣는다. (B) 앱을 systemd 서비스로 두고 `Restart=on-failure`로 재시도하게 한다. 둘을 비교해 결정자에게 요청한다 |
| COST-12 | Major | security.md 2.2절, 03 5절 "S3 버킷 (아티팩트)", FR-12 | 아티팩트 버킷의 삭제 방식이 정해지지 않았다. 버킷에는 JAR가 계속 쌓인다 | FR-12 (Must). Terraform AWS 프로바이더 동작(일반 지식): 객체가 남은 버킷은 `force_destroy`를 켜지 않으면 `destroy`가 실패한다. 버전 관리를 켜면 이전 버전도 남는다 | 테스트 종료 시 `terraform destroy`가 버킷에서 멈춰 FR-12 검증(state 0줄)이 실패한다 | 04에 버킷 설정(`force_destroy = true` 여부, 버전 관리 여부)을 적는다. NFR-08(이전 버전 재배포)은 서비스별 키에 버전명을 넣는 방식으로도 되므로 버전 관리 필요 여부를 함께 정한다 |
| COST-13 | Major | 04-design 전체, 02 각 결정 지점의 "구현 난이도", ADR-002·ADR-006·ADR-010 | 구축 2일·1인 기준으로 누적 작업량을 검토한 곳이 없다. 02 기준 난이도는 D-06 로그 **상**("2일 일정에서 다른 작업을 밀어낼 수 있다"), D-02 CodeDeploy **중**, D-10 NLB→ALB **하~중**이고, 여기에 모듈 직접 작성(CON-11), 서브넷 10개(COST-04), SG 7개, NLB·내부 ALB 이중 진입점, Alloy·Loki·Grafana 설정이 더해진다. "구축 첫날 확인"으로 미룬 항목도 5개가 겹친다(A-06 에이전트, NLB 단일 AZ → ALB 2 AZ, ElastiCache 서브넷 1개, ALB TLS 기본 정책, 실제 JAR 메모리) | CON-03, CON-12, CON-11, Q-19(02 읽는 법), 02 2절 난이도 정의 | 개별 결정은 ADR에서 받아들였지만 합계는 아무도 보지 않았다. 첫날 확인 항목 하나라도 실패하면 대안 설계로 돌아가야 해 Must 요구사항(FR-02, FR-06, FR-08) 검증이 밀린다 | 05에서 작업을 반나절 단위로 나눠 2일(4칸) 안에 들어가는지 먼저 보인다. 넘치면 Should 항목(FR-09·NFR-09 로그)을 운영 기간으로 미루는 안을 결정자에게 제시한다(01 우선순위 정의상 허용). 첫날 확인 항목은 1일 차 오전에 모아 실패 시 대체안을 미리 적는다 |
| COST-14 | Major | 04-design 전체(DNS 항목 없음), 03 5절 Route 53·ACM | Route 53 호스팅 영역을 Terraform이 새로 만드는지, 이미 있는 것을 참조하는지 정하지 않았다. 서비스 도메인 3개의 별칭 레코드, ACM DNS 검증 레코드, 검증 대기 방식도 04에 없다 (확인 필요) | FR-02 (Must), FR-06 (Must), FR-12 (Must), CON-10. AWS 사양(일반 지식): 호스팅 영역을 새로 만들면 네임서버 4개가 새로 정해지므로 등록기관(가비아) 위임을 다시 해야 하고, 위임 전에는 ACM DNS 검증이 끝나지 않는다. 호스팅 영역에 Terraform 밖 레코드가 남으면 삭제가 실패한다 | 새로 만든다면 구축 첫날 가비아 NS 변경과 전파 대기가 일정에 들어가야 하고, ACM 발급이 늦어져 FR-02 검증이 밀린다. 참조라면 FR-12 삭제 대상에서 빠지는 것을 명시해야 한다 | 04에 DNS 절을 추가해 (A) Terraform이 호스팅 영역 생성 (B) 기존 영역을 data 소스로 참조 중 하나를 결정받는다. 레코드 3개(NLB 별칭)와 ACM 검증 레코드도 적는다 |
| COST-15 | Minor | security.md·compute.md·data.md·03·02 머리 표 "선행 문서" | 선행 문서 버전이 현재 버전과 다르다: security.md → network.md v0.5 (현재 v0.8), compute.md·data.md → network.md v0.6·security.md v0.5 (현재 v0.8·v0.7), 03 → 02 v1.2 (현재 v1.3), 02 → 00 v1.4·01 v1.1 (02 v1.1 변경 이력은 01 v1.3 반영). compute.md v0.2와 data.md v0.2는 "network.md v0.6의 용도별 서브넷 이름"이라고 적었지만 용도별 이름은 network.md v0.4·v0.5에서 생겼다 | 머리 표 규칙(문서 간 추적성) | 어느 버전을 기준으로 검토했는지 추적할 수 없다 | 선행 문서 버전을 현재 값으로 고친다 |
| COST-16 | Minor | security.md·03·02 변경 이력 표 | 변경 이력 행이 버전 순서가 아니다(security.md: 0.1, 0.5, 0.6, 0.7, 0.4, 0.3, 0.2 / 03: 1.4 다음 1.3 / 02: 1.3, 1.2, 1.1) | 표기 오류 | 최신 변경을 찾기 어렵다 | 버전 순서로 정렬한다 |
| COST-17 | Minor | network.md 7절 "NLB를 거쳐 AZ 2개의 ALB로 요청이 간다", 6절 N-07 | 7절 검증 항목 이름은 AZ 2개의 ALB 노드로 간다고 적었지만, 4.4절대로 NLB가 AZ-A에만 있고 교차 영역 로드 밸런싱이 "해당 없음"이면 AZ-A ALB 노드로만 간다 (확인 필요). N-07은 "프라이빗 서브넷 6개"라고 적었지만 2절 표는 7개다 | ADR-010, network.md 4.4절·2절 | 검증 결과를 잘못 해석할 수 있다 | 7절 이름을 "NLB를 거쳐 ALB로 요청이 간다"로 바꾸고, N-07의 개수를 7개로 고친다 |
| COST-18 | Minor | ADR-006 "단점" 1번째 줄 | 단점에 "로그 서버 1대(**t3.small**, 20GB)"가 취소선 없이 남았다. 결정은 t3.large다(ADR-006 결정, compute.md 1절) | ADR-006, compute.md 1절 | 02 비교표 인용이지만 표시가 없어 사양을 잘못 읽을 수 있다 | "(02 비교 당시 t3.small 기준)"을 붙이거나 취소선 처리한다 |
| COST-19 | Minor | security.md 5절 "VPC 안 규칙이 SG 참조로 돼 있다" | 검증 대상 SG 목록에 sg-log가 빠졌다. sg-log도 VPC 안 출발지(sg-app, sg-bastion)를 가진다 | security.md P-05, 1.2절 | P-05 검증에서 sg-log가 빠진다 | `--group-ids`에 `<sg-log>`를 넣는다 |
| COST-20 | Minor | data.md 5절 "RDS 스토리지 약 $0.09", 02 2.1절 | RDS 스토리지 일일 비용이 gp2 단가(약 0.131/GB-월) 기준인데 data.md 2절은 gp3를 골랐다. 단가 근거가 섞여 있다 | NFR-13 (Must), data.md 2절 | 금액 차이는 작지만 NFR-13 대조 시 근거가 맞지 않는다 | gp3 단가로 다시 적거나 "gp2 단가로 추정"이라고 표시한다 |
| COST-21 | Suggestion | security.md 2.3절, CON-13, NFR-07 | Terraform과 GitHub Actions가 같은 IAM 사용자 키를 쓰므로, GitHub에 저장되는 키가 Terraform 실행 수준(인프라 전체 생성·삭제) 권한을 가진다. 보관 위치와 수명 관리가 04에 없다 | AWS 공식 권장사항(일반 지식): 장기 액세스 키 대신 임시 자격 증명(OIDC), 최소 권한. 다만 CON-13·NFR-07이 고정 제약이므로 요구사항 위반은 아니다 | 키가 유출되면 계정 전체가 영향을 받는다 | 제약 안에서 할 수 있는 것만 적는다: GitHub 저장소 Secrets에 보관, 테스트 종료(FR-12) 직후 키 비활성화·삭제를 05 절차에 넣는다 |
| COST-22 | Suggestion | compute.md 2절 "루트 볼륨 크기 앱 서버 8GB" | 앱 서버 8GB에 OS, Java 17, CodeDeploy 에이전트, Alloy, JAR, 앱 로그가 함께 들어간다. CodeDeploy 에이전트는 이전 리비전을 서버에 보관한다 | AWS 사양(일반 지식): CodeDeploy 에이전트 `max_revisions` 기본값은 5다 | 운영 2일 범위에서는 문제 가능성이 낮지만, 디스크가 차면 배포가 실패한다 | 에이전트 `max_revisions`를 줄이거나 루트 볼륨 여유를 구축 첫날 `df -h`로 확인한다 |

## 3. ADR 확인

ADR에서 받아들인 트레이드오프라 지적하지 않은 항목이다.

- ADR-001: 앱 서버 t3.medium이 CON-14 "메모리 최소 스펙"과 다르고, 00·01과 02 13절 비용은 고치지 않기로 함.
- ADR-002: CodeDeploy 구현 난이도 중, Ubuntu 24.04 에이전트 동작(A-06)은 구축 첫날 확인.
- ADR-003: ALB는 중지할 수 없어 상시 과금(하루 약 $0.54).
- ADR-004: NAT 인스턴스보다 약 11배 비싼 NAT Gateway(하루 약 $1.54)를 받아들임.
- ADR-005: Bastion 22번 포트가 인터넷에 열림(출발지 `/32` 제한, security.md S-04), 사양 t3.medium.
- ADR-006: 로그 스택 자체 호스팅의 운영 부담 높음·구현 난이도 상, 로그 서버 t3.large.
- ADR-007: AZ-A 장애 시 전체 서비스 중단.
- ADR-008: ElastiCache 중지 불가(상시 과금), RDS 7일 뒤 자동 시작(대비 절차는 05에서 정함).
- ADR-009: Secret 파일 평문 저장, RDS 임시 비밀번호가 State에 남음, 비밀번호 변경 감지 제외 방식은 05에서 확정.
- ADR-010: 대안 비교 없이 확정, NLB 단일 AZ·EIP 1개, NLB 단일 AZ → ALB 2 AZ 구성은 구축 첫날 확인.
- ADR-011: AZ-B 프라이빗 서브넷도 AZ-A NAT Gateway 사용, 보안 그룹 규칙 대안 비교 생략.

## 4. 점검했으나 이상 없음

- **network ↔ security 포트 값**: NLB TCP 443, ALB HTTPS 443, 앱 8080, SSH 22, MySQL 3306, Redis 6379, Loki 3100, Grafana 3000이 network.md 5절과 security.md 1.2절에서 모두 같다.
- **SG 참조 방향과 경로**: network.md 5절의 모든 VPC 내부 흐름에 대응하는 인바운드 규칙이 security.md 1.2절에 있고, 그 밖의 허용 규칙은 없다(ALB ← NLB, 앱 ← ALB·Bastion, 로그 ← 앱·Bastion, RDS·Redis ← 앱·Bastion). ADR-011 표와도 같다.
- **서브넷·SG 이름 대응**: security.md 1.1절, compute.md 1절, data.md 2·3절의 서브넷·SG 이름이 network.md 2절과 같다(ADR-010 문구만 예외, COST-03).
- **CI/CD 경로 값(흩어진 내용 기준)**: 03 4-2절의 "에이전트 → CodeDeploy·S3는 NAT Gateway 경유", network.md 4.3·5.2절(VPC 엔드포인트 없음, HTTPS 443), security.md 아웃바운드 전체 허용(S-05), 03 X-02 해결 내용이 서로 같다.
- **HTTP 80 거부(NFR-06)**: NLB·ALB 모두 80 리스너 없음(network.md 5.1, security.md P-03), 검증 명령도 01 NFR-06과 같다.
- **AWS 사양과 맞는 값**: ALB 서브넷 크기(/27 이상, 여유 IP 8개), RDS 서브넷 그룹 AZ 2개, 퍼블릭 NAT Gateway의 퍼블릭 서브넷 배치, NLB 보안 그룹은 생성 시에만 지정(AWS 사양, 일반 지식). ElastiCache 서브넷 그룹은 서브넷 1개로도 만들 수 있다(AWS 사양, 일반 지식. Multi-AZ를 쓰지 않으므로 network.md N-06은 문제없다).
- **ALB TLS 정책 명시**: API·Terraform에서 정책을 비우면 오래된 기본 정책(`ELBSecurityPolicy-2016-08`)이 적용되므로 명시한다는 security.md 2.1절 판단은 맞다(AWS 사양, 일반 지식).
- **NFR-13 중지 시 과금 목록**: 04에서 만드는 리소스 중 중지해도 과금되는 것(NLB·EIP, ALB, NAT Gateway·EIP, ElastiCache, RDS 스토리지, EBS, Route 53)이 02 13.2절과 03 6절 목록에 모두 있다. EBS 합계(앱 8GB×3, Bastion 8GB, 로그 20GB = 52GB)도 02 13.1절 값과 같다.
- **데이터 계층 삭제 설정(FR-12)**: RDS 자동 백업 0일, 최종 스냅샷 없음, 삭제 방지 끔, ElastiCache 스냅샷 0일이 Q-09·FR-12와 같다. data.md 1절은 승인 문서에 없는 RPO 5분을 반영하지 않고 분리해 적었다.
- **NFR-02·NFR-03 검증**: AZ 매핑(2a, 2c)과 검증 명령이 network.md 1.2·7절에서 일관된다.
- **CPU 크레딧 Standard(C-02)**: T3 기본값 Unlimited와 다르므로 명시한다는 내용과 검증 명령이 02 2.1절 권고와 같다.
