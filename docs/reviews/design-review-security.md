# 설계 보안 검토 — SG 규칙, 암호화·TLS 정책

| 항목 | 값 |
|---|---|
| 검토 대상 | [01-requirements.md](../01-requirements.md) v1.3 (Approved) |
| | [02-options.md](../02-options.md) v1.3 (Approved) |
| | [adr/](../adr/) ADR-001~ADR-011 (모두 Accepted, ADR에는 버전 표기 없음. ADR-009는 "Accepted (세부 방식 미정)") |
| | [03-architecture.md](../03-architecture.md) v1.4 (Approved) |
| | [04-design/network.md](../04-design/network.md) v0.8 (Draft) |
| | [04-design/security.md](../04-design/security.md) v0.7 (Draft) |
| | [04-design/compute.md](../04-design/compute.md) v0.3 (Draft) |
| | [04-design/data.md](../04-design/data.md) v0.2 (Draft) |
| 검토일 | 2026-11-12 |
| 검토자 | 보안 리뷰 에이전트 |
| 검토 관점 | (1) SG 규칙: 과도한 허용, CIDR 대신 SG 참조가 가능한 규칙, `0.0.0.0/0` 예외의 타당성 (2) 암호화, TLS 정책 |

> - 위 문서 내용만 근거로 판단했다. AWS 동작에 대한 판단은 "AWS 공식 권장사항(일반 지식)" 또는 "AWS 사양(일반 지식)"으로 표시했다.
> - ~~취소선~~ 부분은 현재 내용으로 보지 않았다. **미정** 항목은 "결정되지 않음"으로 보고, 결정이 없는 것 자체가 요구사항을 막는지 또는 보안 위험인지 판단했다.

---

## 1. 요약

| 관점 | Critical | Major | Minor | Suggestion | 계 |
|---|---|---|---|---|---|
| (1) SG 규칙 | 1 | 1 | 4 | 0 | 6 |
| (2) 암호화·TLS | 0 | 2 | 2 | 3 | 7 |
| 공통 (문서 표기) | 0 | 0 | 1 | 0 | 1 |
| **계** | **1** | **3** | **7** | **3** | **14** |

- 핵심: 진입점(NLB) 인바운드 출발지가 아직 **미정**이라 Must 요구사항(FR-02, FR-03, FR-06, NFR-06)을 구현·검증할 수 없다(SEC-01).
- 데이터 계층의 전송 암호화와 Redis 인증 토큰이 미정이다. 둘 다 만들 때만 정할 수 있고, Must인 FR-04의 검증 명령이 이 결정에 달려 있다(SEC-02).
- 그 밖의 SG 규칙은 VPC 안 규칙을 모두 SG 참조로 썼고, `0.0.0.0/0` 인바운드는 sg-nlb 443 하나로 제한돼 있어 대체로 양호하다.

## 2. 발견 사항

| ID | 심각도 | 위치(파일/절) | 문제 | 근거 | 영향 | 제안 |
|---|---|---|---|---|---|---|
| SEC-01 | Critical | 04-design/security.md 1.2 (sg-nlb 인바운드), 3절 `0.0.0.0/0` 예외 목록, 4절 S-03 | sg-nlb 인바운드 443의 출발지가 **미정**이고, `0.0.0.0/0` 예외 목록의 유일한 행도 상태가 **미정**이다. 대안 (B) "협력사 IP만"은 서비스 사용자의 접속을 막는다고 문서 스스로 적었다. 그런데도 5절 검증 항목("`0.0.0.0/0` 인바운드가 예외 목록에만 있다" → 결과 `sg-nlb`뿐)은 이미 (A)를 전제로 쓰여 있다 | FR-02·FR-03·FR-06·NFR-06 (모두 Must), ADR-011 후속 조치("협력사만 허용할지, 모두 허용할지는 정하지 않았다"), 01 6.1(admin 외부 공개 허용, Q-S-04) | 결정 없이는 sg-nlb 인바운드 규칙을 만들 수 없다. 규칙이 없으면 서비스 도메인 3개로 아무도 접속하지 못해 FR-02·FR-03·FR-06(Must)을 충족하지 못한다. 진입점의 보안 경계(NFR-06)도 확정되지 않은 상태로 05에 넘어간다. NLB SG는 만들 때만 붙일 수 있어(security.md 1.1) 나중에 SG 자체를 바꾸려면 NLB를 다시 만들어야 한다 | 05 전에 S-03을 결정하도록 사람에게 요청한다. 요구사항상 (B)는 FR-02·FR-03을 어기므로 사실상 (A) `0.0.0.0/0`, TCP 443만 남는다. 결정 후 1.2절과 예외 목록의 "미정"을 지우고, IPv6을 쓰지 않으므로 `::/0` 규칙은 두지 않는다고 함께 적는다 |
| SEC-02 | Major | 04-design/security.md 2.1 (앱 서버 → RDS·Redis), 4절 S-07; 04-design/data.md 2·3절(전송 TLS, 인증 토큰, 파라미터 그룹 "기본"), 6절 D-04 | 앱 서버 → RDS·ElastiCache 구간 TLS와 Redis 인증 토큰이 모두 **미정**이다. (1) ElastiCache 전송 중 암호화는 만들 때만 켤 수 있다. (2) ElastiCache의 AUTH 토큰(및 RBAC)은 전송 중 암호화를 켜야만 쓸 수 있다. 따라서 S-07에서 (B)를 고르면 Redis 인증도 쓸 수 없게 되는데, 문서는 두 결정을 "함께 정한다"고만 적었다. (3) S-07에서 (A)를 골라도 RDS가 TLS를 **강제**하려면 `require_secure_transport=ON`인 사용자 지정 파라미터 그룹이 필요한데, data.md는 파라미터 그룹을 "기본"으로 정했다 | FR-04(Must) 검증 명령 `redis-cli -h <Redis 주소> <인증·암호화 옵션> PING`, ADR-009 후속 조치(ElastiCache 인증 토큰 미정), 03 8절 X-04("05 전"), AWS 사양(일반 지식: ElastiCache 전송 중 암호화는 생성 시 설정, AUTH는 전송 중 암호화 필수, RDS MySQL TLS 강제는 파라미터 그룹 설정) | Redis는 로그인 세션 저장소다(FR-04). 인증·암호화가 없으면 sg-redis가 허용한 호스트(앱 서버 3대, Bastion) 중 하나만 침해돼도 세션을 읽거나 바꿀 수 있다. 결정이 늦으면 Terraform 기본값(꺼짐)으로 만들어지고, 바꾸려면 ElastiCache를 다시 만들어야 한다. FR-04 검증 명령의 옵션 값도 확정되지 않는다 | 05 전에 S-07과 Redis 인증 토큰을 **한 결정**으로 묶어 사람에게 요청한다. 대안: (A) Redis 전송 중 암호화 + AUTH 토큰, RDS는 사용자 지정 파라미터 그룹으로 TLS 강제 (B) 둘 다 끔(VPC 안 구간, SG로만 제어). (A)를 고르면 data.md 2절 파라미터 그룹 값과 AUTH 토큰을 넣는 방법(ADR-009 Secret 파일 적용 여부)을 함께 고친다 |
| SEC-03 | Major | 04-design/security.md 2.1 (ACM 인증서 범위), 4절 S-06 | ACM 인증서 이름 범위(이름 3개 / 와일드카드 1개)가 **미정**이다. 인증서가 없으면 ALB HTTPS 리스너를 만들 수 없다 | FR-02(Must), ADR-003, AWS 공식 권장사항(일반 지식: 인증서 범위는 필요한 이름으로 최소화) | 결정이 없으면 FR-02의 구현이 막힌다. (B) 와일드카드는 같은 도메인의 다른 서브도메인에도 쓸 수 있어, 키가 쓰이는 범위가 필요 이상으로 넓다 | 05 전에 S-06 결정을 사람에게 요청한다. 보안 관점에서는 (A) 서비스 도메인 3개를 이름으로 넣는 쪽이 범위가 좁다. 두 안 모두 FR-02를 충족하고 ACM 공인 인증서는 추가 요금이 없다(AWS 요금 정책, 일반 지식) |
| SEC-04 | Major | adr/ADR-010 결정 절; 04-design/network.md 2절(public-nlb-a), 04-design/security.md 1.1(sg-nlb 서브넷) | ADR-010은 "NLB는 AZ-A의 퍼블릭 서브넷(**public-a**) 하나에만" 둔다고 적었다. network.md·security.md는 NLB를 **public-nlb-a**에 두고, public-a에는 Bastion과 NAT Gateway를 둔다. security.md 1.1은 public-nlb-a의 근거로 ADR-010을 들었지만 ADR-010의 서브넷 이름과 다르다 | ADR-010, network.md 2절, security.md 1.1 (문서 간 충돌) | ADR대로 구현하면 인터넷 진입점(NLB)과 관리 접속 경로(Bastion)가 같은 서브넷에 놓인다. SG로 분리되므로 바로 사고로 이어지지는 않지만, 근거 문서와 설계 문서가 서로 다른 배치를 가리켜 구현 때 어느 쪽을 따를지 알 수 없다 | ADR-010의 "(public-a)"를 "AZ-A의 퍼블릭 서브넷(04-design에서 public-nlb-a로 지정)"처럼 고치거나, 03처럼 AZ 단위 이름만 쓰도록 ADR-010을 고칠지 사람에게 요청한다 |
| SEC-05 | Minor | 04-design/security.md 1.2 (sg-alb ← sg-nlb), 5절 "ALB는 NLB에서만 받는다"; 04-design/network.md 5.3 (NLB → ALB 전달·상태 확인 TCP 443) | sg-alb 인바운드를 sg-nlb 참조로만 열었다. NLB 대상 그룹 종류가 ALB일 때 클라이언트 IP 보존이 어떻게 동작하는지, 그 상태에서 SG 참조 규칙이 맞는지, NLB → ALB 상태 확인 프로토콜(ALB 대상은 HTTP/HTTPS 상태 확인만 지원하는 것으로 알고 있음)이 무엇인지 문서에 없다. network.md 5.3은 상태 확인을 "TCP 443"으로만 적었다 (확인 필요) | ADR-010("NLB의 대상 그룹 종류를 ALB로 두는 설정이 처음일 수 있다"), AWS 사양(일반 지식, 확신 낮음) | SG 참조가 기대대로 맞지 않으면 NLB → ALB 트래픽이나 상태 확인이 막혀 FR-02·FR-13이 실패한다. network.md 7절의 `/healthz` 200 검증으로 구축 첫날 드러나기는 한다 | 구축 전에 NLB(SG 연결) + ALB 대상 그룹에서 sg-alb의 sg-nlb 참조 규칙만으로 통신·상태 확인이 되는지 AWS 문서로 확인하고, 결과와 상태 확인 프로토콜·포트를 security.md 1.2 근거와 network.md 5.3에 적는다 |
| SEC-06 | Minor | 04-design/security.md 5절 "VPC 안 규칙이 SG 참조로 돼 있다" | P-05(VPC 안 규칙은 SG 참조로만) 검증 명령의 대상이 `<sg-alb> <sg-app> <sg-rds> <sg-redis>`뿐이다. VPC 안 출발지 규칙 3개(3100, 3000, 22)를 가진 **sg-log**가 빠졌다 | security.md P-05, 1.2절 sg-log 규칙 | sg-log에 CIDR 규칙이 잘못 들어가도 이 검증으로 잡지 못한다 | 검증 명령의 `--group-ids`에 `<sg-log>`를 더한다 |
| SEC-07 | Minor | 04-design/security.md 3절 `0.0.0.0/0` 예외 목록 근거 | 예외 목록의 근거를 "00 2.1(admin 외부 공개 허용)"로 적었다. 01 6.1 추적표는 이 항목을 00 **3.3** "admin 외부 공개 허용"(Q-S-04)으로 적었다 (확인 필요: 00은 이번 검토 범위 밖이라 열지 않았다) | 01 6.1 (3.3 / admin 외부 공개 허용 / Q-S-04) | `0.0.0.0/0` 예외의 근거 추적이 틀릴 수 있다 | 근거를 "01 6.1(00 3.3, Q-S-04), FR-02, FR-03"으로 바꾼다 |
| SEC-08 | Minor | adr/ADR-011 후속 조치; 03-architecture.md 6절 NFR-06 행, 8절 X-03 | security.md v0.7에서 S-04(Bastion 허용 IP `<operator-ip>/32`)를 해결했지만, ADR-011 후속 조치는 여전히 "Bastion 보안 그룹 … 허용할 IP 값은 정하지 않았다"로 남아 있다. 같은 후속 조치의 S-01·S-02·S-05 항목은 취소선으로 갱신됐는데 이 항목과 NLB 보안 그룹 항목만 갱신되지 않았다. 03 6절 NFR-06의 △ 사유와 8절 X-03(결정 시점 "04 전")도 열린 채다 | ADR-011, security.md S-04, 03 6·8절 | 관리 접속 경로의 출발지 제한이 정해졌는지 문서마다 다르게 읽힌다 | ADR-011 후속 조치의 Bastion 항목을 취소선 처리하고 security.md S-04로 연결한다. 03 X-03은 04 승인 때 "해결(04-design/security.md S-04)"로 표시할지 사람에게 요청한다 |
| SEC-09 | Minor | 04-design/security.md 2.1 TLS 표 | 구간별 TLS 표에 일부 구간이 없다: 앱 서버(Alloy) → Loki 3100, Bastion → Grafana 3000(SSH 터널의 Bastion 이후 구간), Bastion → RDS 3306·Redis 6379. 표에는 앱 서버 → RDS·Redis만 있다 | network.md 5.1·5.3 (해당 경로), security.md 2절 제목("TLS 정책과 암호화 대상") | Grafana 로그인 정보와 로그 데이터가 VPC 안에서 평문 HTTP로 오가는 구간이 있다는 사실이 기록되지 않는다. Bastion에서 DB에 접속할 때의 TLS 옵션도 FR-04 검증 명령과 연결되지 않는다 | 2.1 표에 세 구간을 추가하고 각각 "암호화하지 않음(VPC 안, SG로 제어)" 또는 S-07 결정 연동으로 적는다 |
| SEC-10 | Minor | 04-design/security.md 5절 "TLS 1.1 이하를 받지 않는다" | 검증을 `openssl s_client … -tls1_1`의 실패로 판정한다. OpenSSL 3.x는 기본 보안 수준에서 클라이언트 쪽이 TLS 1.1을 쓰지 않으므로, 서버가 TLS 1.1을 받더라도 명령이 실패해 검증이 통과할 수 있다 (확인 필요) | FR-02, AWS 공식 권장사항(일반 지식: TLS 1.2 이상) | 거짓 통과(위양성) 가능. 다만 바로 위 행의 `describe-listeners`로 정책 이름을 확인하므로 실제 위험은 작다 | `-tls1_1 -cipher 'DEFAULT@SECLEVEL=0'`처럼 클라이언트 제한을 풀고 시험하거나, `nmap --script ssl-enum-ciphers -p 443 <도메인>`으로 프로토콜 목록을 확인하도록 바꾼다 |
| SEC-11 | Minor | 04-design/security.md 머리 표·변경 이력; compute.md·data.md 머리 표; 03-architecture.md 머리 표 | (1) security.md 선행 문서가 network.md **v0.5**인데 현재 network.md는 v0.8이다. (2) compute.md·data.md는 security.md **v0.5**를 선행 문서로 적었는데 현재 security.md는 v0.7이고, v0.6~0.7에서 SG 규칙(S-01·S-02·S-04)이 바뀌었다. (3) security.md 변경 이력이 0.1, 0.5, 0.6, 0.7, 0.4, 0.3, 0.2 순서로 섞여 있다. (4) 03 선행 문서의 02 버전이 v1.2인데 02는 v1.3이다 | 각 문서 머리 표 | SG 규칙이 바뀐 뒤의 버전을 기준으로 다른 문서가 맞춰졌는지 추적하기 어렵다 | 선행 문서 버전을 현재 버전으로 맞추고, 변경 이력을 버전 순으로 정렬한다 |
| SEC-12 | Suggestion | 04-design/security.md 2.2 (RDS·ElastiCache·EBS 저장 암호화), 4절 S-08; compute.md 2절 볼륨 암호화 | 저장 데이터 암호화가 모두 **미정**이다. 01에는 저장 암호화 요구사항이 없어(개인정보·규제 범위 제외) 요구사항 위반은 아니다. 다만 세 가지 모두 만들 때만 정할 수 있고, 결정이 없으면 Terraform·계정 기본값(꺼짐)으로 만들어진다. ADR-009로 Secret 파일이 EBS에 평문으로 남으므로, EBS 암호화가 그 파일을 보호하는 유일한 저장 계층 통제가 된다 | AWS 공식 권장사항(일반 지식: 저장 데이터 암호화 기본 사용, AWS 관리형 키는 추가 요금 없음), ADR-009 단점(비밀값이 EBS에 평문) | 미정인 채로 05에 넘어가면 암호화 없이 만들어지고, 나중에 켜려면 다시 만들어야 한다 | 05 전에 S-08을 사람에게 요청한다. 비용 차이가 없으므로(문서 추정치) (A) AWS 관리형 키로 모두 켜는 안을 검토하고, EBS는 계정 수준 "기본 암호화"를 켜는 방법과 인스턴스별 지정 방법을 비교한다 |
| SEC-13 | Suggestion | 04-design/security.md 2.1 ALB 보안 정책 | `ELBSecurityPolicy-TLS13-1-2-2021-06`은 TLS 1.2에서 CBC 계열 암호 모음도 허용한다. AWS에는 TLS 1.2에서 AEAD·ECDHE만 남긴 제한형(`…-Res-…`) 정책도 있다 | AWS 공식 권장사항(일반 지식) | 현재 정책으로도 FR-02를 충족한다. 오래된 클라이언트를 지원할 필요가 없으면 더 좁힐 수 있다 | 협력사·사용자 클라이언트 호환성 요구가 없다면 `ELBSecurityPolicy-TLS13-1-2-Res-2021-06`(또는 그 시점의 최신 제한형 정책)과 현재 정책을 비교해 결정을 요청한다 |
| SEC-14 | Suggestion | 04-design/security.md 2.2 S3 아티팩트 버킷, 3절 P-09 | S3 버킷은 비공개·SSE-S3로 정했지만, HTTPS가 아닌 요청을 거부하는 버킷 정책(`aws:SecureTransport = false` 거부)은 없다. 앱 서버는 VPC 엔드포인트 없이 NAT를 거쳐 S3 공인 엔드포인트로 간다(network.md N-02) | AWS 공식 권장사항(일반 지식: S3 전송 중 암호화 강제), network.md 4.3 | 현재 경로(HTTPS 443)로는 문제가 없지만, 평문 요청을 막는 장치는 클라이언트 설정에만 의존한다 | 버킷 정책에 `aws:SecureTransport` 거부 문을 넣을지 사람에게 요청한다. 요금은 없다 |

## 3. ADR 확인

> ADR(또는 01)에서 명시적으로 받아들인 트레이드오프다. 지적하지 않았다.

- ADR-010: NLB는 TLS를 종료하지 않고 TCP로 넘기며, TLS 종료는 ALB가 한다. 문서 간 모순 없음(서브넷 이름만 SEC-04).
- ADR-011: ALB → 앱 서버 구간은 HTTP(앱 포트)로 암호화하지 않으며, 출발지는 sg-alb로 제한한다. security.md 2.1과 일치.
- ADR-011 후속 조치(security.md S-05): 모든 SG의 아웃바운드를 `0.0.0.0/0` 전체 허용으로 정했다(sg-rds, sg-redis 포함). 접근 제어는 받는 쪽 인바운드로만 한다.
- ADR-011: sg-rds·sg-redis는 sg-app과 함께 sg-bastion에서도 받는다(FR-04·NFR-14 검증용).
- ADR-005: Bastion SSH 22가 인터넷에 열리는 것을 출발지 제한 조건으로 받아들였다. security.md에서 `/32`로 제한해 조건을 채웠다.
- ADR-009: Secret 파일을 앱 서버 디스크에 평문으로 두고 파일 권한으로 제한한다. RDS 임시 비밀번호는 State에 평문으로 남는다.
- 01 6.1·CON-11(Q-31): Terraform State를 운영자 PC에 암호화 없이 두는 위험을 받아들였다(security.md 2.2와 일치).
- 01 6.1(Q-S-04)·2.2(Q-S-06): admin 도메인도 별도 접근 제한 없이 외부에 공개하고, WAF·DDoS 고급 보호는 범위에서 뺐다.
- ADR-003: ACM DNS 검증, 443 리스너만 둔다. HTTP 80은 리디렉션 없이 거부한다(Q-27과 일치).

## 4. 점검했으나 이상 없음

- **SSH 노출:** 22번 인바운드는 sg-bastion의 `<operator-ip>/32` 하나뿐이고, 프라이빗 서버(sg-app, sg-log)의 22번은 sg-bastion만 출발지로 둔다(P-01, FR-07, NFR-06).
- **SG 참조 사용:** VPC 안을 출발지로 하는 인바운드 규칙(sg-alb ← sg-nlb, sg-app ← sg-alb·sg-bastion, sg-log ← sg-app·sg-bastion, sg-rds·sg-redis ← sg-app·sg-bastion)이 모두 SG 참조로 돼 있고, CIDR은 VPC 밖(운영자 IP, 인터넷)에만 썼다(P-05). CIDR을 SG 참조로 바꿀 수 있는 규칙은 없다.
- **`0.0.0.0/0` 인바운드:** sg-nlb TCP 443 후보 하나 말고는 없다. 이 예외 자체는 FR-02·FR-03(사용자가 인터넷 어디서나 접속)으로 타당하다(결정 미정 문제는 SEC-01).
- **과도한 인바운드 허용:** 앱 서버 간 8080 자기 참조 규칙이 없어 서비스끼리 직접 호출 경로가 열려 있지 않다. Grafana 3000은 sg-bastion에서만 받아 ADR-006의 SSH 터널 방식과 맞다. 로그 서버는 RDS·Redis에 닿지 않는다(5절 검증 포함).
- **HTTP 80:** NLB·ALB 모두 80 리스너와 리디렉션이 없고, 검증 항목(`curl http://` → `000`, `nmap` 결과 443 하나)이 NFR-06 검증 방법과 일치한다.
- **공개 범위:** ALB는 내부용(P-06), RDS "퍼블릭 액세스 가능"은 끔(P-04), 프라이빗 서브넷은 공인 IP 자동 할당을 끔(network.md 2절).
- **ALB TLS 정책:** TLS 1.2 이상·TLS 1.3 지원 정책을 명시하고, Terraform에서 비우면 오래된 기본 정책이 붙는다는 점까지 적었다. `describe-listeners`로 정책 이름을 검증한다(FR-02).
- **S3:** SSE-S3 기본 암호화와 퍼블릭 액세스 차단 4개 설정을 켜고 검증한다(P-09).
- **자격 증명:** 루트 액세스 키 없음·MFA, 코드와 저장소에 키·비밀번호를 쓰지 않는 규칙과 검증(`git grep`)이 NFR-07, FR-11과 일치한다.
