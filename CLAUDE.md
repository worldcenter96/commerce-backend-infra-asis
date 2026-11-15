## 설계 단계 규칙
- docs/ 문서는 00 → 05 순서로 작성한다. 앞 문서가 Approved 상태가 아니면 다음 문서를 작성하지 않는다.
- 05-implementation-plan.md가 Approved되기 전에는 terraform/ 아래에 코드를 작성하지 않는다.
- 정보가 부족하면 추측하지 말고, 00-context.md의 Open Questions에 추가한 뒤 질문한다.
- 설계 결정 지점마다 대안을 2개 이상 비교하고, 결정은 사람에게 요청한다.
- 모든 설계 항목에 관련 요구사항 ID를 표기한다.