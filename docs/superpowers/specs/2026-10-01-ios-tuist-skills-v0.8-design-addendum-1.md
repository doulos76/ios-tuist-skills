# ios-tuist-skills v0.8 PRD — 보완 문서 (Addendum 1)

- 대상 문서: `2026-10-01-ios-tuist-skills-v0.8-prd.md` (이하 "본 PRD")
- 기준 커밋: `492fd7e` (develop, v0.7.1)
- Implementation owner: Codex — this repo's Claude session only produces spec + plan
- 구현 계획: `docs/superpowers/plans/2026-10-02-ios-tuist-skills-v0.8.md` (이 보완 문서를 반영함)
- 작성 근거: Codex 재검증 결과와 Claude 검토의 대조 (2026-10-01)
- 권장 저장 위치: `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design-addendum-1.md`

---

## 0. 적용 규칙 (Claude Code용)

1. **본 PRD를 먼저 읽는다.** 이 문서는 본 PRD를 대체하지 않고, 아래 명시한 부분만 변경·추가한다.
2. **충돌 시 이 문서가 우선한다.** 단, 본 PRD 0절의 작업 지침(증거 먼저 확인, 불일치 시 멈추고 보고, git flow, 범위 규율)은 그대로 적용된다.
3. **[미검증] 표시 항목은 구현 전에 확인한다.** 확인되지 않으면 해당 항목은 구현하지 않고 "Unverified"로 PR에 보고한다.
4. **두 모델(Claude, Codex)의 합의는 검증이 아니다.** 같은 원문을 읽고 내린 결론이므로, 모든 근거는 실제 파일과 명령 결과로 다시 확인한다.

---

## 1. 변경 요약

| # | 대상 | 변경 종류 | 요지 |
|---|------|----------|------|
| A1 | 본 PRD 3절 우선순위 | 변경 | WS5(bootstrap)를 P1 → P0. description 라우팅을 WS4에서 분리해 독립 P0로 명시 |
| A2 | WS2 (version-safety) | 변경 | 단일 버전 목록 → **축별 증거 분류** (Tool / Xcode / Swift / Manifest) |
| A3 | WS2 열린 질문 | 해소 | `Package.swift`는 Tuist 버전 소스에서 제외, Swift 축 증거로 이동 |
| A4 | WS4 (migrate description) | 제약 추가 | 라우팅 문구 추가 시 기존 안전장치 문구 보존 필수 |
| A5 | WS6 (벤치마크) | 구조화 | Phase 0~3 순서 명시. v0.8 범위는 Phase 0~1 |
| A6 | 5절 열린 질문 | 추가 | CI 규칙의 장기 재작성안 기록 (v0.8에서는 변경 금지) |
| A7 | 비목표 | 명확화 | Jev 위치: 런타임 ❌ / 벤치마크 연구 ✅ (v0.8 범위 밖) |

---

## 2. A1 — 우선순위 재정의

본 PRD 3절의 워크스트림 우선순위를 다음으로 교체한다. 작업 순서도 이 표의 순서를 따른다.

| 순서 | 우선순위 | 작업 | 본 PRD 위치 |
|-----|---------|------|-----------|
| 1 | P0 | module SKILL / EXPECTATIONS / rubric 정합화 | WS1 |
| 2 | P0 | version-safety: 전수 수집 + 축별 분류 + Tuist.swift 재분류 | WS2 + 이 문서 A2·A3 |
| 3 | P0 | fixture self-containment | WS3 |
| 4 | P0 | 공식 Tuist 플러그인 공존 정책 (README, 본문 공존 규칙) | WS4 (변경 1·3·4) |
| 5 | P0 | 10개 description에 Use / Do-not-use 추가 | WS4 (변경 1·2) + 이 문서 A4 |
| 6 | P0 | bootstrap `.xcodeproj`/`.xcworkspace` 감지 → 중단 | WS5 |
| 7 | P1 | 격리 벤치마크 하네스 | WS6 + 이 문서 A5 |
| 8 | P1 | Codex native manifest | WS7 |
| 9 | P2 | 반복 측정 N≥3 실제 실행 | v0.8 범위 밖 |
| 10 | P2 | Jev 채점자 비교 실험 | v0.8 범위 밖 |

- 4번과 5번은 같은 WS4 브랜치에서 진행해도 되지만, 커밋은 분리한다.
- cwd 기록(본 PRD WS2 변경 6)은 WS2의 일부로 P0에 포함한다. 별도 P1 항목으로 분리하지 않는다.

---

## 3. A2 — version-safety 증거의 축별 분류

본 PRD WS2 변경 8의 "Tuist Version Evidence" 표를 아래 구조로 교체한다.

### 3.1 분류 원칙

- **Tool Version 축만** effective Tuist version 결정에 사용한다.
- 나머지 축은 **호환성 리스크 보고용**이며, Tuist 버전 결정에 쓰지 않는다.
- 각 증거에는 출처(파일 경로 또는 명령), 값, 그리고 명령의 경우 **실행 디렉터리(cwd)**를 기록한다.

### 3.2 축별 증거 소스

```text
Tool Version Evidence (Tuist CLI — effective version 결정에 사용)
-----------------------------------------------------------------
mise.toml / .mise.toml      <ver|none>   PRIMARY 후보 1순위
.tool-versions              <ver|none>   PRIMARY 후보 2순위
CI workflows                <ver|none>   (file path)
Scripts / Makefile          <ver|none>   (file path)
Active (plain)              <ver>        cmd: tuist version          cwd: <path>
Active (mise exec)          <ver|n/a>    cmd: mise exec -- tuist version  cwd: <path>
Effective project version:  <ver | none detected>
Conflicts:                  <list | none>

Xcode Evidence (호환성 리스크 보고용)
-------------------------------------
Tuist.swift compatibleXcodeVersions   <range|none>
.xcode-version                         <ver|none>   [미검증: Tuist 비소비, 프로젝트 의도 증거]
Active                                  <ver>        cmd: xcodebuild -version

Swift Evidence (호환성 리스크 보고용)
-------------------------------------
Tuist.swift swiftVersion               <ver|none>
Package.swift swift-tools-version      <ver|none>
Tuist/Package.swift swift-tools-version<ver|none>
.swift-version                          <ver|none>   [미검증: Tuist 비소비, 프로젝트 의도 증거]
Active                                  <ver>        cmd: swift --version

Manifest Compatibility Evidence
-------------------------------
Existing manifest syntax               <range|unknown>  (근거가 된 API/문법)
```

### 3.3 구현 지침

- 우선순위가 같은 축 안에서 서로 다른 값이 있으면 effective version은 우선순위 규칙대로 정하되, 반드시 `Conflicts`에 기록한다. 충돌을 해소(수정)하지 않는다 — 기존 Mismatch handling 원칙 유지.
- `.xcode-version`, `.swift-version`은 Tuist가 직접 읽는다는 근거가 확인되지 않았다 **[미검증]**. 포함하되 "Tuist 비소비 — 프로젝트 의도를 보여주는 증거"로 표기한다. Tuist 공식 문서에서 소비 근거가 확인되면 표기를 갱신한다.
- 기존 `Tuist Context` 블록은 유지하고, 위 증거 표를 그 앞에 둔다. Context 블록의 `Project Tuist` 값은 `Effective project version`에서 가져온다.
- 각 SKILL.md의 Output Contract 예시가 새 형식과 모순되면 최소한으로 갱신한다.

### 3.4 수락 기준 (본 PRD WS2에 추가)

- `references/version-safety.md`에 4개 축이 구분되어 있다.
- Tool Version 축 외의 증거가 effective version 결정에 쓰인다는 서술이 없다.
- 명령 기반 증거에 cwd 기록이 요구된다.

```bash
grep -n "Xcode Evidence\|Swift Evidence\|Tool Version Evidence\|Manifest Compatibility" references/version-safety.md   # 4건
grep -n "cwd" references/version-safety.md                                                                      # 1건 이상
```

---

## 4. A3 — Package.swift 열린 질문 해소

본 PRD WS2 변경 5와 5절 열린 질문 1을 다음 결정으로 대체한다.

- `Package.swift`, `Tuist/Package.swift`는 **Tuist CLI 버전 소스에서 제거**한다.
- 두 파일의 `// swift-tools-version:` 선언은 **Swift Evidence**로 기록한다 (A2 참조).
- 예외: 저장소 안에서 Package.swift를 Tuist 버전 근거로 쓰는 스킬 본문·fixture·EXPECTATIONS가 발견되면, 수정하지 말고 위치를 보고한다.

```bash
grep -rn "Package.swift" skills/ references/ tests/fixtures/*/EXPECTATIONS.md | grep -i "version"
```

---

## 5. A4 — migrate description 작성 제약

본 PRD WS4 변경 2를 다음 제약과 함께 수행한다.

### 5.1 반드시 보존할 기존 의미

현재 `ios-tuist-migrate` description의 다음 두 제약은 **삭제·약화 금지**:

- 이 저장소에서 프로젝트의 Tuist 버전 pin을 변경할 수 있는 **유일한** 스킬이다.
- **사용자가 목표 버전을 명시한 요청**에서만 동작한다.

### 5.2 추가할 라우팅 의미

- Tuist **버전** 마이그레이션 전용이다.
- 기존 Xcode 프로젝트를 Tuist로 전환하는 용도가 아니다 (Tuist 공식 migrate 워크플로의 영역).
- 목표 버전 없이 "최신으로 정리", "현대화" 같은 모호한 요청에는 쓰지 않는다.

### 5.3 예시 (그대로 복사하지 말고 길이 제한 확인 후 조정)

```yaml
description: >
  Moves an existing Tuist project's pinned Tuist version forward to a
  user-specified target version, updating pin sources and only the
  manifest syntax that version requires. The only skill here permitted
  to change a Tuist version pin, and only on an explicit,
  version-specific request. Not for converting an Xcode project to
  Tuist (use Tuist's official migration workflow), and not for vague
  "update/modernize" requests with no target version.
```

### 5.4 수락 기준

```bash
awk '/^description:/,/^---/' skills/ios-tuist-migrate/SKILL.md | grep -c -i "only skill\|explicit"   # 2 이상
awk '/^description:/,/^---/' skills/ios-tuist-migrate/SKILL.md | grep -i "xcode project"           # 1건 이상
```

### 5.5 다른 9개 description에도 동일 원칙 적용

라우팅 문구를 추가할 때 기존 description의 **금지·제한 문구**(예: restyle의 "Never sweeps a whole project", scaffold의 "Never runs tuist scaffold against the real project tree", architecture-review의 "never edits code or manifests")는 보존한다. 길이 제한 때문에 줄여야 한다면 라우팅 문구보다 기존 제한 문구를 우선 남긴다.

---

## 6. A5 — 벤치마크 v2 단계 정의

본 PRD WS6을 다음 단계 구조 안에 위치시킨다.

| Phase | 내용 | v0.8 범위 | 선행 조건 |
|-------|------|----------|----------|
| 0 | Fixture self-containment | ✅ (WS3) | — |
| 1 | Isolation 하네스 + 1건 시험 실행 | ✅ (WS6) | Phase 0 |
| 2 | 반복 측정 (릴리스 평가 N≥3, 모델 버전 기록) | ❌ 절차 문서화만 | Phase 1 |
| 3 | Blind scoring + 결정론적 지표 우선 | ❌ 원칙 문서화만 | Phase 2 |

추가 수락 기준 (WS6):

- Phase 1 시험 실행 시, 복사된 fixture 안에서 version-safety 증거 표가 **fixture 내부 pin만으로** 채워지는지 확인한다. 저장소 루트의 CI matrix를 증거로 인용하면 Phase 0이 미완료된 것으로 보고 실패 처리한다.

---

## 7. A6 — CI 규칙 장기 재작성안 (기록만)

- **v0.8에서 `ios-tuist-ci`의 "Never remove a validation step (build, test, lint) to make CI faster." 문구는 변경하지 않는다.**
- 본 PRD 5절 열린 질문에 다음을 추가한다:

> 5. (v0.9+ 후보) selective testing·sharding을 다룰 때, 규칙을 "사용자가 동등한 근거를 갖춘 대체 전략을 명시적으로 승인하지 않는 한 요구되는 검증 범위를 줄이지 않는다"로 재작성할지. 재작성 시 "동등한 근거"의 판정 기준(예: 기준 브랜치 대비 실행된 테스트 집합 비교, 전체 실행 주기 보장)을 함께 정의해야 한다. 정의 없이 문구만 완화하면 에이전트의 자가 판정 경로가 생긴다.

---

## 8. A7 — 비목표 명확화

본 PRD 2절 비목표에 다음을 추가·명확화한다.

- Jev 등 외부 decision model은 **런타임 통합하지 않는다**. 이유: (1) Markdown 스킬 플러그인 구조상 스킬 선택 앞단에 외부 라우터를 둘 수 없음, (2) 확인된 결함은 모호한 판단이 아니라 명세 모순이므로 decision model로 해결되지 않음.
- 향후 위치는 **벤치마크 연구(Phase 3 이후)**: Claude 채점자 vs Jev Score vs 결정론적 지표의 상관 비교. v0.8에서는 문서화도 요구하지 않는다.

---

## 9. 미검증 항목 목록 (구현 전 확인)

| 항목 | 관련 | 확인 방법 | 미확인 시 처리 |
|------|------|----------|-------------|
| `.xcode-version` / `.swift-version`를 Tuist가 소비하는지 | A2 | Tuist 공식 문서 검색 | "Tuist 비소비" 표기 유지 |
| Agent Skills description 최대 길이 | A4 | Agent Skills 공식 규격 | 기존 최장 description 길이를 상한으로 사용 |
| `tuist init`의 기존 프로젝트 통합 지원 여부 | WS5 | Tuist CLI 문서 / `tuist init --help` | bootstrap 안내 문구에서 언급하지 않음 (공식 migrate 스킬만 안내) |
| Codex 공식 plugin 규격 (`.codex-plugin`, `.agents/plugins`) | WS7 | Codex 공식 문서 | WS7 보류, v0.8.x로 이월 |

---

## 10. 릴리스 체크리스트 추가 항목

본 PRD 4절 체크리스트에 추가:

- [ ] 이 보완 문서의 A1 순서대로 병합되었는지 확인
- [ ] 9절 미검증 항목별 확인 결과(확인됨 / 미확인-처리 방식)를 PR 또는 CHANGELOG에 기록
- [ ] `CHANGELOG.md`에 version-safety 출력 형식 변경(축별 증거 표)을 **breaking change 성격**으로 명시 — 스킬 출력에 의존하는 사용자 워크플로가 있을 수 있음
