# ios-tuist-skills v0.8 PRD — Reliability & Coexistence

- 대상 저장소: `doulos76/ios-tuist-skills`
- 기준 커밋: `492fd7e` (develop, v0.7.1)
- Implementation owner: Codex — this repo's Claude session only produces spec + plan
- 구현 계획: `docs/superpowers/plans/2026-10-02-ios-tuist-skills-v0.8.md`
- 목표 릴리스: v0.8.0
- 권장 저장 위치: `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design.md`
- 작성 근거: 저장소 직접 검토 + Tuist 공식 문서/`tuist/agent-plugin` 대조 (2026-10-01)

---

## 0. Claude Code 작업 지침 (먼저 읽을 것)

1. **증거 먼저 확인.** 각 워크스트림의 "근거" 항목을 실제 파일에서 다시 확인한다. 이 문서의 기술과 실제 파일 내용이 다르면 **수정하지 말고 멈춰서 차이를 보고**한다.
2. **git flow.** `develop`에서 워크스트림별 `feature/v0.8-<ws-id>` 브랜치를 만든다. 한 브랜치에 여러 워크스트림을 섞지 않는다.
3. **순서.** WS1 → WS2 → WS3 → WS4 → WS5 → WS6 → WS7. WS6은 WS3 완료가 선행 조건이다.
4. **범위 규율.** 이 PRD에 없는 리팩터링, 문구 다듬기, 무관한 manifest 현대화는 하지 않는다.
5. **검증.** 각 워크스트림의 "검증" 명령을 실제로 실행하고 결과를 PR 설명에 붙인다. 실행하지 못한 검증은 "Unverified"로 명시한다.
6. **"검증 필요" 표시 항목**은 구현 전에 공식 문서나 실제 동작으로 확인하고, 확인 결과에 따라 진행 여부를 판단해 보고한다.

---

## 1. 배경

v0.1–v0.7에서 10개 스킬, 11개 fixture, Phase 1 벤치마크가 갖춰졌다. Phase 1 벤치마크와 외부 리뷰 검토에서 다음이 확인되었다.

- 유일한 with-skill 결함(`App -> NetworkingKit` 불필요 엣지)의 원인은 **에이전트의 규칙 위반이 아니라 스킬·fixture·채점 기준 간 명세 모순**이다.
- `version-safety.md`의 감지 절차가 첫 pin에서 멈추고, 사실과 다른 버전 소스(Tuist.swift)를 포함한다.
- fixture 대부분이 Tuist pin을 자기 디렉터리에 갖고 있지 않아, 벤치마크 격리(저장소 밖 복사본 실행)를 하면 fixture 의미가 바뀐다.
- Tuist 공식 플러그인(`tuist/agent-plugin`)의 스킬과 **라우팅·지시가 충돌**한다.

v0.8은 새 스킬을 추가하지 않고 **기존 스킬의 신뢰성과 공식 생태계와의 공존**에 집중한다.

## 2. 목표 / 비목표

### 목표
- G1. 스킬 명세, fixture 기대 결과, 채점 기준을 서로 일치시킨다.
- G2. 버전 감지를 "모든 증거 수집 → 충돌 보고" 방식으로 바꾼다.
- G3. 모든 fixture가 저장소 밖으로 복사되어도 의미가 유지되게 한다.
- G4. Tuist 공식 플러그인과 함께 설치되어도 라우팅과 지시가 명확하게 한다.
- G5. 격리된 벤치마크를 재현 가능하게 실행할 하네스를 제공한다.

### 비목표 (이번 릴리스에서 하지 않음)
- 외부 decision model(Jev 등)의 런타임 통합 — 플러그인 구조와 맞지 않고, 확인된 결함은 명세 모순이라 해결되지 않는다.
- `ios-tuist-adopt` 신규 스킬 — 공식 `migrate` 스킬(Xcode → Tuist 전환)과 중복된다.
- `ios-tuist-ci`의 "Never remove a validation step" 규칙 완화.
- 실제 baseline 재측정 14건 전체 실행 (하네스 제공과 1건 시험 실행까지만 범위).

---

## 3. 워크스트림

### WS1 (P0) — module 스킬의 consumer 엣지 명세 정합화

**근거**
- `skills/ios-tuist-module/SKILL.md` 5단계(약 85–88행): "Wire the source target (and other consumers) to depend on the new target."
- 같은 파일 출력 예시(약 156행): "App now depends on NetworkingKit instead of owning the code directly".
- `tests/fixtures/extract-candidate/EXPECTATIONS.md`: "`App` depends on it instead of owning the code."
- 실제 `App/Sources/ExtractCandidateApp.swift`는 `SettingsRow`만 사용. `APIRequestBuilder` 사용처는 `App/Tests/AppTests.swift` 뿐.
- `RUBRIC-SCORES-5-8.md` item 6은 `App -> NetworkingKit`을 scope creep으로 0점 처리.
- Decision Rules의 "Never widen the new target's dependencies…"는 새 target **자신의** 의존성 규칙이며 consumer 엣지를 다루지 않는다.

**변경**
1. 5단계를 다음 취지로 수정: 새 target에 대한 의존 엣지는 **추출된 심볼의 실제 usage site(import 또는 심볼 참조)가 확인된 target에만** 추가한다. source target이라는 이유만으로 추가하지 않는다.
2. Decision Rules에 consumer 엣지 규칙을 별도 항목으로 추가: "Add a dependency edge to the new target only from targets with a verified usage site; record the evidence (file:line) for each added edge in the Output Contract."
3. 테스트만 추출 코드를 쓰는 경우의 처리 명시: 테스트는 코드와 함께 새 target의 테스트 target으로 이동하고, 원래 테스트 target이 비게 되면 사용자에게 보고한다(삭제 여부는 사용자 결정).
4. 출력 예시를 "consumer 엣지 + 근거" 형식으로 교체. 예: `- FeatureX -> NetworkingKit (usage: FeatureX/Sources/Api.swift:12)` 및 `- App: no edge added (no usage site found)`.
5. `extract-candidate/EXPECTATIONS.md`의 networking 기대 결과를 "App에 엣지가 추가되지 않는다(usage site 없음)"로 수정.
6. `references/dependencies.md` 또는 `references/modularization.md`에 consumer 엣지 원칙이 이미 있는지 확인하고, 없으면 한 문단 추가 후 SKILL에서 링크.

**수락 기준**
- SKILL.md, EXPECTATIONS.md, 출력 예시 세 곳 모두 `App -> NetworkingKit`을 기대 결과로 서술하지 않는다.
- Output Contract의 `Dependency Changes` 항목이 엣지별 근거를 요구한다.

**검증**
```bash
grep -rn "App now depends on NetworkingKit\|App\` depends on it" skills/ tests/fixtures/   # 결과 없어야 함
grep -n "usage site" skills/ios-tuist-module/SKILL.md                                      # 1건 이상
./scripts/validate-fixtures-locally.sh extract-candidate   # fixture가 여전히 build/test 되는지 (스크립트 인자 형식은 확인 필요)
```

---

### WS2 (P0) — version-safety 재설계: 증거 수집 → 충돌 보고

**근거**
- `references/version-safety.md` "Detection order": "stopping as soon as a pinned project version is found. Earlier sources win."
- 3번 항목: "`Tuist.swift` (its `Tuist` configuration may declare a compatible version range)" — 공식 `ProjectDescription` 레퍼런스상 `Tuist`/`TuistProject.tuist(...)`는 `compatibleXcodeVersions`, `swiftVersion`, `plugins`, generation/install/cache 옵션만 받는다. Tuist CLI 버전 범위 필드는 없다.
- 4·5번 항목(`Tuist/Package.swift`, `Package.swift`)이 Tuist CLI 버전을 고정하는 근거는 확인되지 않음 (**검증 필요**).

**변경**
1. "Detection order"를 "Evidence collection"으로 교체. 모든 소스를 끝까지 조사하고, 발견된 값을 전부 기록한다.
2. 권위(authority) 우선순위는 명시적 규칙으로 유지: `mise.toml`/`.mise.toml` > `.tool-versions` > CI 워크플로 pin > 스크립트 pin > manifest 문법 증거. 우선순위가 가장 높은 소스가 **effective project version**이다.
3. 우선순위가 낮은 소스가 다른 값을 가지면 **충돌로 보고**한다 (수정하지 않음 — 기존 Mismatch handling 원칙 유지).
4. `Tuist.swift`는 Tuist 버전 소스에서 제거하고 **Xcode/Swift 축 증거**(`compatibleXcodeVersions`, `swiftVersion`)로 재분류한다. 활성 Xcode가 범위 밖이면 리스크로 보고.
5. `Tuist/Package.swift`, `Package.swift`: 실제 Tuist 버전 근거가 되는 사례가 있는지 공식 문서로 확인. 없으면 버전 소스에서 제거, 있으면 근거를 문서에 링크하고 유지.
6. live 명령 실행 규칙 추가: 프로젝트 루트에서 실행하고, mise 사용 프로젝트는 `mise exec -- tuist version`과 일반 `tuist version`을 모두 기록한다(디렉터리별 자동 전환 때문에 결과가 달라질 수 있음 — Phase 1 벤치마크 version-mismatch 비교에서 확인된 현상). 실행 디렉터리도 기록한다.
7. mise 추가 설정 경로(`mise.local.toml`, `.config/mise.toml` 등)를 증거 소스에 포함할지 mise 공식 문서로 확인 후 반영 (**검증 필요**).
8. Tuist Context 블록에 증거 표 추가:
   ```text
   Tuist Version Evidence
   ----------------------
   .mise.toml        <ver|none>   PRIMARY | ⚠ conflict
   .tool-versions    <ver|none>
   CI workflows      <ver|none>   (file path)
   Scripts           <ver|none>   (file path)
   Manifest syntax   <range|none>
   Active (plain)    <ver>        (cwd)
   Active (mise exec)<ver|n/a>
   Effective project version: <ver | none detected>
   ```
9. 이 reference를 인용하는 모든 SKILL.md의 문구가 새 절차와 맞는지 확인 (`grep -rn "version-safety" skills/`). 문구가 "detection order"를 직접 언급하면 갱신.

**수락 기준**
- "stopping as soon as" 문구가 사라지고, 모든 소스를 조사한다는 규칙이 명시된다.
- `Tuist.swift`가 Tuist 버전 소스 목록에 없고, Xcode/Swift 증거로 서술된다.
- `version-mismatch` fixture의 EXPECTATIONS가 새 출력 형식과 모순되지 않는다.

**검증**
```bash
grep -n "stopping as soon as" references/version-safety.md        # 결과 없어야 함
grep -n "compatible version range" references/version-safety.md  # 결과 없어야 함
grep -rln "version-safety" skills/ | xargs grep -n -i "detection order"   # 갱신 누락 확인
```

---

### WS3 (P0) — fixture pin의 자기 완결화 (WS6 선행 조건)

**근거**
- 11개 fixture 중 pin 파일(`.tool-versions`)을 가진 것은 `legacy-tuist`, `modular`, `version-mismatch` 3개뿐.
- 나머지의 Tuist 버전은 `.github/workflows/validate-fixtures.yml` matrix에만 존재.
- `migrate-candidate`는 3.42.2 pin이 fixture 내부에 없음(`Tuist/Config.swift` 문법 증거만 존재). 저장소 밖으로 복사하면 pin 근거가 사라진다.
- 추론: Phase 1에서 with-skill이 migrate 비교 중 "저장소의 실제 CI 설정 수정"을 제안한 것은 fixture 밖에서만 pin을 찾을 수 있었기 때문일 가능성이 높다.

**변경**
1. `new-project`(빈 디렉터리가 시나리오 자체)를 제외한 모든 fixture에 `.tool-versions`를 추가한다. 기존 fixture의 관례(`.tool-versions`)를 따른다. 값은 CI matrix의 해당 fixture 값과 동일하게.
2. `ci-gaps` fixture는 내장 워크플로가 있으므로, 그 안의 Tuist pin과 새 `.tool-versions` 값이 시나리오 의도를 깨지 않는지 EXPECTATIONS를 읽고 판단한다. 시나리오가 "pin 불일치"를 의도한다면 그 의도를 보존하고 보고.
3. CI에 정합성 검사 단계 추가: fixture의 `.tool-versions` tuist 값 == matrix 값. 불일치 시 실패.
4. `migrate-candidate/EXPECTATIONS.md`에서 "update whatever version-pin source names 3.42.2"가 이제 fixture 내부 `.tool-versions`를 가리키도록 문구 정리.

**수락 기준**
- `new-project`를 제외한 모든 fixture 디렉터리에 `.tool-versions`가 있다.
- CI가 pin 정합성을 검사한다.
- 모든 fixture가 기존과 동일하게 CI에서 generate/build/test 통과.

**검증**
```bash
for d in tests/fixtures/*/; do [ "$d" = "tests/fixtures/new-project/" ] && continue; test -f "$d/.tool-versions" || echo "MISSING $d"; done
```

---

### WS4 (P0) — Tuist 공식 플러그인과의 공존 + description 라우팅

**근거**
- `tuist/agent-plugin`의 공식 스킬: `generated-projects`, `migrate`, `debug-generated-project`, `fix-flaky-tests`, `analyze-selective-testing`, `compare-*` 등.
- 공식 `generated-projects` description: "Use when working in a Tuist-generated project or when users mention `tuist generate`…" — 본문은 "Use `buildableFolders` instead of `sources` and `resources` globs"라고 권장. 버전 감지 절차 없음.
- 이 저장소는 기존 배열 방식을 보존(legacy-tuist)하고 buildableFolders 전환은 명시 요청 시 `ios-tuist-restyle`에서만 수행 → **같은 요청에 반대 지시가 공존**할 수 있음.
- 공식 `migrate` = Xcode 프로젝트 → Tuist 전환. 이 저장소 `ios-tuist-migrate` = Tuist 버전 업그레이드. "migrate" 요청의 라우팅이 모호.
- 이 저장소 10개 description 중 "Use when / not for" 형식은 `ios-tuist-test-target` 하나뿐.

**변경**
1. 10개 SKILL.md description을 "무엇을 하는가 / 언제 쓰는가 / 언제 쓰지 않는가" 3요소로 재작성. `ios-tuist-test-target` 형식을 기준으로 삼는다.
2. `ios-tuist-migrate` description에 "Tuist **version** migration only; not for converting an Xcode project to Tuist" 명시.
3. `ios-tuist-feature`, `ios-tuist-dependency`, `ios-tuist-restyle` 본문에 공존 규칙 추가: "다른 Tuist 가이드가 buildableFolders 등 현재 권장 방식을 제시하더라도, 사용자가 restyle을 명시 요청하지 않았다면 기존 프로젝트 관례가 우선한다."
4. README에 "Relationship to the official Tuist plugin" 섹션 추가: 역할 구분(공식 = 현재 권장 방식·플랫폼 데이터·Xcode→Tuist 전환 / 본 플러그인 = 기존 프로젝트의 버전·관례를 지키는 안전한 manifest 변경), 동시 설치 시 주의점, 요청별 권장 스킬 표.
5. description 길이 제한(Agent Skills 규격의 최대 길이)을 공식 규격으로 확인하고 초과하지 않게 작성 (**검증 필요**).

**수락 기준**
- 10개 description 모두 "not for / Do not use" 성격의 문장을 포함한다.
- README에 공식 플러그인과의 관계 섹션이 있다.
- 기존 Non-goals("does not replace Tuist's official…")와 모순되지 않는다.

**검증**
```bash
for f in skills/*/SKILL.md; do awk '/^description:/,/^---/' "$f" | grep -qi "not for\|do not use" || echo "NO-NEGATIVE $f"; done
```
- 수동 확인: Claude Code에 본 플러그인과 공식 `tuist` 플러그인을 함께 설치한 상태에서 다음 요청의 스킬 선택을 기록한다 — "migrate this project from Tuist 3 to 4", "migrate this Xcode project to Tuist", "add LoginFeature".

---

### WS5 (P1) — bootstrap의 기존 Xcode 프로젝트 감지

**근거**
- `skills/ios-tuist-bootstrap/SKILL.md` Core Rule/Preconditions는 대상 경로의 `Project.swift`, `Tuist.swift`, `Workspace.swift`만 확인. `.xcodeproj`, `.xcworkspace`, 기존 소스 트리는 확인하지 않음.

**변경**
1. Preconditions 1번에 추가: 대상 경로(및 1단계 하위 디렉터리)에 `*.xcodeproj` 또는 `*.xcworkspace`가 있으면 **중단**하고, 기존 Xcode 프로젝트임을 보고하며 Xcode→Tuist 전환은 공식 Tuist `migrate` 스킬의 영역임을 안내한다.
2. Non-Trigger Conditions에 같은 내용 추가.
3. 신규 스킬(`ios-tuist-adopt`)은 만들지 않는다.
4. 선택: `tests/fixtures/existing-xcode/` 수동 시나리오(EXPECTATIONS만, CI matrix 미포함)를 추가해 거절 동작을 문서화.

**수락 기준**
- bootstrap SKILL.md가 `.xcodeproj`/`.xcworkspace` 존재 시 중단을 명시한다.

**검증**
```bash
grep -n "xcodeproj" skills/ios-tuist-bootstrap/SKILL.md   # 1건 이상
```

---

### WS6 (P1) — 격리 벤치마크 하네스 (WS3 이후)

**근거**
- `AGGREGATE-SUMMARY.md`: baseline 14건 오염, N=1, 실제 baseline 재측정은 3/14에서 중단. "no `--plugin-dir`"만으로는 격리 불충분 — 세션이 저장소의 `skills/`, `references/`, 프로젝트 메모리를 탐색해 읽음.
- `scripts/benchmark-prep-run.sh`에 `/Users/dave/Documents/GitHub/ios-tuist-skills` 절대 경로 하드코딩.

**변경**
1. `scripts/benchmark-isolated-run.sh` 신설:
   - fixture를 `mktemp -d` 아래로 복사하고 그 안에서 `git init` + 초기 커밋 (diff 측정용).
   - 복사본 상위 경로에 이 저장소의 `skills/`, `references/`, `CLAUDE.md`가 없음을 확인하고, 있으면 실패.
   - 조건 인자: `baseline` | `with-skill`. with-skill은 플러그인 경로를 인자/환경변수로 받는다(하드코딩 금지).
   - 실행 후 결정론적 지표 수집: `git diff --stat`, 변경 파일 수, manifest의 dependency 엣지 전후 비교, `tuist generate`/build/test 성공 여부.
   - 결과를 `docs/superpowers/benchmarks/<date>-<name>/raw/<fixture>-<condition>-run<N>.md`로 저장.
2. `benchmark-prep-run.sh`의 하드코딩 경로를 인자/환경변수로 교체.
3. `EXECUTION-GUIDE.md`에 격리 실행 절차와 반복 측정 정책 추가 (PR 스모크 N=1, 릴리스 평가 N≥3, 모델 버전 기록).
4. 채점 관련 원칙만 문서화(이번 범위에서 구현하지 않음): 채점자에게 조건(baseline/with-skill) 비공개, 결정론적 지표를 LLM 채점보다 우선.

**수락 기준**
- 하네스로 `extract-candidate`(networking) 1건을 baseline/with-skill 각 1회 실행해, 저장소 밖 경로에서 실행되었음과 지표가 기록됨을 보여준다.
- 저장소 내 스크립트에 사용자 절대 경로가 남아 있지 않다.

**검증**
```bash
grep -rn "/Users/" scripts/   # 결과 없어야 함
```

---

### WS7 (P2) — Codex 정식 manifest

**근거**
- README(v0.7.1)는 `.claude-plugin/marketplace.json`을 Codex에서도 사용한다고 안내. 이는 Codex가 `.claude-plugin/marketplace.json`을 스캔해 가져오는 동작에 의존하며, 이 동작은 `openai/codex` 이슈 #19372에서 문제 제기됨.
- 다른 공개 저장소들은 Codex용으로 `.agents/plugins/marketplace.json` + `.codex-plugin/plugin.json`을 사용.

**변경**
1. 현재 Codex 공식 문서로 plugin/marketplace 규격을 확인 (**검증 필요** — 필드 구성은 이 PRD에서 단정하지 않음).
2. 규격 확인 후 `.agents/plugins/marketplace.json`, `.codex-plugin/plugin.json` 추가. 메타데이터는 `.claude-plugin/plugin.json`을 원본으로 하고 생성 스크립트로 동기화(`scripts/sync-codex-manifest.*`).
3. CI에 원본-생성본 동기화 검사 추가.

**수락 기준**
- Codex CLI에서 `codex plugin marketplace add doulos76/ios-tuist-skills` 후 설치·활성화 확인 결과를 PR에 첨부.

---

## 4. 릴리스 체크리스트

- [ ] WS1–WS5 병합 (WS6, WS7은 준비되면 포함, 아니면 v0.8.x)
- [ ] `CHANGELOG.md`에 워크스트림별 항목 기록 (특히 WS1의 원인 재진단: "spec contradiction, not rule violation")
- [ ] `.claude-plugin/plugin.json` version → `0.8.0`
- [ ] `AGGREGATE-SUMMARY.md`에 "WS1로 extract-candidate-networking의 기대 결과가 정정되었음" 각주 추가 (기존 점수는 수정하지 않음)
- [ ] 전체 fixture CI 통과

## 5. 열린 질문

1. `Package.swift` / `Tuist/Package.swift`를 Tuist 버전 근거로 볼 공식 근거가 있는가? (WS2-5)
2. Agent Skills description 최대 길이와, 공식 플러그인과 동시 설치 시 Claude Code의 스킬 선택 동작 (WS4)
3. `ci-gaps` fixture가 pin 불일치를 시나리오로 의도하는가? (WS3-2)
4. 원래 테스트 target이 비게 되는 경우의 기본 동작 — 보고만 할지, 삭제 제안할지 (WS1-3)

## 6. 참고

- 저장소: `references/version-safety.md`, `skills/ios-tuist-module/SKILL.md`, `skills/ios-tuist-bootstrap/SKILL.md`, `tests/fixtures/extract-candidate/`, `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/`
- Tuist `ProjectDescription` 레퍼런스: https://docs.tuist.dev/en/references/project-description/enums/tuistproject
- Tuist 공식 agent plugin: https://github.com/tuist/agent-plugin
- Tuist MCP 가이드(스킬과 MCP 혼용 비권장): https://docs.tuist.dev/en/guides/features/agentic-coding/mcp
- Codex의 Claude marketplace 자동 가져오기 이슈: https://github.com/openai/codex/issues/19372
