# ADR-013. 비밀값 전달: Secret 파일, RDS 관리형 비밀번호, Redis 인증 토큰 없음

| 항목 | 값 |
|---|---|
| 상태 | Accepted (2026-11-15) |
| 대체 대상 | [ADR-009](ADR-009-secrets.md) |
| 결정 지점 | D-09 |
| 날짜 | 2026-11-15 |
| 결정자 | 박가온누리 |
| 근거 문서 | [ai-log](../../ai-log/ai-decisions.md) 2026-11-15 "05 2단계(network 모듈) 구현 중 질문", [04-design/security.md](../04-design/security.md) v1.3 S-10·S-11, [04-design/data.md](../04-design/data.md) v1.3 2·3절 |

## 맥락

- ADR-009는 비밀값을 앱 서버 안의 Secret 파일에 두고, Terraform 구축 단계에서는 넣지 않기로 했다. 다만 RDS 마스터 비밀번호와 Redis 인증 토큰은 만들 때 필요해서, 임시 값을 변수로 넘기고 구축 뒤 운영자가 바꾸는 예외를 뒀다.
- 이 예외 때문에 임시 값이 State에 평문으로 남고(05 R-18), 바꾼 뒤 `plan`이 차이를 보이지 않게 변경 감지에서 빼야 했다(ADR-009 단점).
- 2026-11-15 결정자가 RDS는 RDS가 제공하는 비밀번호를 쓰고, Redis 인증 토큰은 쓰지 않기로 정했다. 확인 질문에서 "RDS 관리형 비밀번호"와 "토큰 없음, TLS 유지"를 골랐다.
- 05 AI-08에 따라 ADR-009를 고치지 않고 이 ADR로 대체한다.

## 결정

1. **비밀값은 앱 서버 안의 Secret 파일에 둔다.** Terraform 구축 단계에서 Secret 파일을 넣지 않는다(ADR-009와 같음, DR-11). 넣는 방법은 Terraform 범위 밖이다.
2. **RDS 마스터 비밀번호는 RDS 관리형 비밀번호를 쓴다.** Terraform에서 `manage_master_user_password = true`로 만든다. RDS가 비밀번호를 만들어 AWS Secrets Manager의 시크릿에 둔다. Terraform 코드, 변수, State에는 비밀번호가 들어가지 않는다. 운영자는 구축 뒤 Secrets Manager에서 값을 읽어 Secret 파일에 넣는다.
3. **ElastiCache Redis 인증 토큰은 쓰지 않는다.** 전송 중 암호화(TLS)는 그대로 켠다(K-03). Redis 접근은 보안 그룹(sg-redis ← sg-app, sg-bastion)으로만 제한한다.

## 검토한 대안

**RDS 마스터 비밀번호**

| 대안 | 내용 | 결과 |
|---|---|---|
| A. ADR-009 유지 | 임시 비밀번호를 sensitive 변수로 넘기고 구축 뒤 바꾼다. State에 평문으로 남는다 | 기각 |
| B. Terraform 무작위 생성 | `random_password`로 만든다. 변수 입력은 없지만 State에 평문으로 남고, hashicorp/random 프로바이더가 늘어난다 | 기각 |
| C. RDS 관리형 비밀번호 | RDS가 만들어 Secrets Manager에 둔다. State에 남지 않는다 | **채택** |

**Redis 인증 토큰**

| 대안 | 내용 | 결과 |
|---|---|---|
| A. 임시 토큰 사용(ADR-009, S-11) | 임시 토큰을 변수로 넘기고 구축 뒤 바꾼다 | 기각 |
| B. 토큰 없음, TLS 유지 | 인증은 SG로만, 전송은 TLS | **채택** |
| C. 토큰 없음, TLS도 끔 | K-03도 바꾼다. 구간이 평문이 된다 | 기각 |

> 02 D-09에서 비교한 대안이 아니다. 결정자 지정과 확인 질문으로 정했다.

## 결과

**장점**
- RDS 비밀번호와 Redis 토큰이 Terraform 변수와 State에 남지 않는다(05 R-18의 비밀값 부분이 없어진다).
- 운영자가 RDS 비밀번호·Redis 토큰을 임시 값에서 바꾸는 작업(05 9-c)과 변경 감지 제외 설정이 필요 없다.
- 운영자가 넣을 비밀값 변수가 없다.

**단점**
- Secrets Manager 시크릿 1개 요금이 생긴다(월 약 $0.40, 추정치). 03의 구성 요소에 Secrets Manager가 추가된다. 시크릿은 RDS가 만들고 지우며 Terraform 코드에는 시크릿 리소스가 없다.
- RDS 관리형 비밀번호는 Secrets Manager가 자동으로 교체한다(기본 7일로 알고 있음, 확인 필요). 교체되면 앱 서버 Secret 파일의 값과 달라져 DB 접속이 실패한다. 교체를 끄거나 주기를 늘릴 수 있는지는 확인하지 못했다(05 R-21).
- Terraform을 실행하는 IAM 사용자에게 Secrets Manager·KMS 권한이 필요할 수 있다(확인 필요, 05 R-21). IAM 사용자는 Terraform 밖에서 관리한다(K-04).
- Redis는 인증 없이 SG만으로 접근을 막는다. sg-app이나 sg-bastion이 붙은 곳에서는 누구나 Redis에 접속할 수 있다.
- Secret 파일은 서버 디스크에 평문으로 남고, 서버 3대에 같은 값을 맞춰 둬야 한다(ADR-009와 같음, CON-14).

## 후속 조치

- 6단계(data 모듈) 시작 전에 확인한다(05 R-21).
  1. 관리형 비밀번호의 자동 교체 주기와 끌 수 있는지
  2. Terraform 실행 IAM 사용자에게 필요한 Secrets Manager·KMS 권한
- Secret 파일의 위치·권한과 넣는 방법은 Terraform 범위 밖에서 정한다(DR-11, 03 X-04).

## 관련 요구사항

FR-04, FR-11, NFR-06, NFR-13, CON-11
