# ios-tuist-skills v0.9 PRD — Deterministic Core, Portability & Routing Evaluation

- 대상 저장소: `doulos76/ios-tuist-skills`
- 기준 커밋: `0a92010` (develop — v0.8 spec/plan 머지, 구현 전)
- 선행 문서: `2026-10-01-ios-tuist-skills-v0.8-design.md`, `...-v0.8-design-addendum-1.md`
- Implementation owner: Codex — this repo's Claude session only produces spec + plan
- 구현 계획: 아직 없음. v0.8.0 릴리스 후(1절 선행 조건 충족 시) `docs/superpowers/plans/`에 작성한다 (WS-A는 v0.8 WS2의 실제 출력 형식에 의존).
- 사전 확인 메모 (2026-10-02, Claude): 1절의 `d0b1576`은 PR #28(`docs/v0.8-addendum-1`)의 커밋이다. WS-B 근거의 `../../` 링크 수는 PRD의 42개가 아니라 **45개**로 확인됨 (`grep -rhn "\.\./\.\./" skills/ | wc -l`) — 구현 시 재확인할 것. 나머지 WS-A/B/D/F 근거는 일치.
- 목표 릴리스: v0.9.0
- 권장 저장 위치: `docs/superpowers/specs/2026-10-02-ios-tuist-skills-v0.9-design.md`

---

## 0. Claude Code 작업 지침

1. **선행 조건 확인.** 아래 1절의 선행 조건이 충족되지 않았으면 v0.9 작업을 시작하지 말고 상태를 보고한다.
2. **증거 먼저.** 각 워크스트림의 "근거"를 실제 파일·명령으로 다시 확인한다. 이 문서와 다르면 수정하지 말고 멈춰서 보고한다.
3. **[검증 필요] 항목**은 구현 전에 공식 문서나 실제 동작으로 확인한다. 확인되지 않으면 해당 부분은 구현하지 않고 PR에 "Unverified"로 기록한다.
4. **git flow.** `develop`에서 `feature/v0.9-<ws-id>` 브랜치. 워크스트림당 PR 하나.
5. **범위 규율.** 스킬의 판단 규칙(Decision Rules)의 의미를 바꾸지 않는다. v0.9는 같은 규칙을 **더 결정론적으로, 더 이식 가능하게, 더 측정 가능하게** 만드는 릴리스다.
6. **기존 소유 분담 준수.** 저장소의 handoff 문서(`docs/superpowers/plans/*HANDOFF-TO-CODEX*`)에 정의된 Claude/Codex 역할 분담을 따른다.

---

## 1. 선행 조건

- [ ] `docs/v0.8-addendum-1` 브랜치가 `develop`에 머지됨
  - 근거: 2026-10-02 기준 `d0b1576`이 develop에 미머지. develop의 plan에는 addendum 반영이 부분적.
  - **이 항목이 미충족이면 v0.8 구현 자체를 시작하지 말 것을 사용자에게 먼저 알린다.**
- [ ] v0.8.0 릴리스 완료 (WS1–WS5 필수, WS6 하네스 권장)
  - 특히 WS2(4축 증거 분류)와 WS3(fixture 내부 pin)이 완료되어야 v0.9 WS-A가 가능하다.

---

## 2. 배경과 목표

v0.8은 **정확성**(명세 모순, 잘못된 버전 소스, fixture 의존성, 공식 플러그인 충돌)을 고친다. v0.9의 문제의식은 다음과 같다.

- 모든 검사가 산문 지시이므로 LLM이 매번 해석·실행한다 → 결과 변동, 토큰 비용, CI로 검증 불가.
- 스킬이 저장소 루트 파일에 링크로 의존한다 → 스킬 단위 설치 시 동작 불확실.
- 스킬이 **올바르게 선택되는지**를 측정하지 않는다 → v0.8의 description 재작성 효과를 확인할 수 없다.
- 특정 Tuist 버전에 묶인 결함 지식이 SKILL 본문에 박혀 있다 → 시간이 지나면 조용히 틀린다.

### 목표
- G1. 결정론적으로 계산 가능한 검사는 스킬 번들 스크립트가 수행하고, CI가 그 출력을 검증한다.
- G2. 각 스킬 폴더가 단독으로 설치되어도 필요한 자료를 모두 포함한다.
- G3. 스킬 선택(라우팅)을 반복 측정 가능한 평가 세트로 만든다.
- G4. 버전 특정 지식에 확인 시점을 붙이고 정기 재확인 경로를 만든다.
- G5. 스킬 출력의 핵심 부분을 기계가 읽을 수 있게 한다.

### 비목표
- 스킬 Decision Rules의 의미 변경 (스크립트는 기존 규칙을 구현할 뿐 새 규칙을 만들지 않는다)
- 새 스킬 추가
- 외부 decision model(Jev 등) 통합
- 반복 측정(N≥3) 벤치마크의 실제 대규모 실행 (WS-F에서 fixture 추가와 시험 실행까지만)
- Hook 기반 강제 (WS-G는 조사·결정 문서만)

---

## 3. 워크스트림 요약

| ID | 우선순위 | 작업 | 의존 |
|----|---------|------|------|
| WS-A | P0 | 결정론적 스크립트 번들 + golden test | v0.8 WS2·WS3 |
| WS-B | P0 | 스킬 자기완결성 (reference 동기화 + drift 검사) | — (WS-A와 병행 가능, 머지는 WS-A 이후 권장) |
| WS-C | P0 | 라우팅 평가 세트 | v0.8 WS4 |
| WS-D | P1 | 버전 특정 지식 분리 + 정기 재확인 | WS-B |
| WS-E | P1 | 기계 판독 가능한 Output Contract | WS-A |
| WS-F | P2 | 벤치마크 외부 타당성 (실규모 fixture, cross-agent) | v0.8 WS6 |
| WS-G | P2 | Hook 조사 및 결정 기록 (구현 없음) | — |

---

## 4. 워크스트림 상세

### WS-A (P0) — 결정론적 스크립트 번들 + golden test

**근거**
- 10개 SKILL.md의 검사(버전 증거 수집, consumer 엣지 판단 등)는 모두 산문 지시로만 존재. `skills/*/` 안에 실행 스크립트 없음 (`find skills -type f ! -name SKILL.md ! -name .gitkeep` 결과 없음 — 재확인).
- v0.8 WS1의 결함(불필요한 consumer 엣지)과 WS2의 증거 수집은 모두 파일·명령 결과만으로 판정 가능한 문제다.

**[검증 필요]** Claude Code 플러그인 스킬과 Agent Skills 규격에서 스킬 폴더 내 스크립트를 SKILL.md가 지시해 실행하는 방식이 지원되는지, 경로를 어떻게 참조해야 하는지(스킬 디렉터리 기준 상대경로 / 환경변수) 공식 문서로 확인. Codex에서의 동작도 확인.

**변경**
1. `scripts/collect-version-evidence.sh` (공유 원본 위치는 WS-B 규칙을 따름)
   - 입력: 프로젝트 루트 경로 (기본 cwd)
   - 동작: v0.8 version-safety의 4축 증거를 수집. 파일 증거는 읽기만, 명령 증거는 `tuist version`, `mise exec -- tuist version`(mise 있을 때), `xcodebuild -version`, `swift --version`을 실행하고 cwd 기록.
   - 출력: v0.8 addendum A2의 증거 표 형식(사람용) + `--json` 옵션 시 동일 내용의 JSON(기계용, WS-E와 공유).
   - 원칙: **판단하지 않는다.** effective version은 v0.8에서 정의한 우선순위 규칙대로 계산만 하고, 충돌은 나열만 한다. 어떤 파일도 수정하지 않는다.
   - 의존: bash + 표준 도구만. 정규식 파싱이 어려운 경우 저장소가 이미 쓰는 ruby 사용 가능 (`scripts/validate-fixtures-locally.sh` 관례 확인).
2. `scripts/check-consumer-edges.sh`
   - 입력: 기준 커밋(또는 manifest 이전 사본), 프로젝트 루트
   - 동작: 변경 전후 manifest의 `.target(name:)` / `.project(target:)` 의존 엣지를 비교해 **새로 추가된 엣지**를 찾고, 각 엣지의 consumer target 소스 경로에서 대상 모듈의 `import` 또는 공개 심볼 참조를 검색.
   - 출력: 엣지별 `usage found (file:line)` / `no usage found`. JSON 옵션 포함.
   - 한계 명시: 정적 검색이므로 `@_exported import`, 매크로, 리소스 의존 등은 탐지 못할 수 있음 → 출력에 "no usage found ≠ 의존 불필요 확정"을 표기하고, 스킬은 이 경우 **보고**하도록 지시(자동 삭제 금지).
3. SKILL.md 연결
   - 버전 안전 절차가 있는 모든 스킬: "Tuist Context를 수립할 때 `collect-version-evidence.sh`를 실행하고 그 출력을 근거로 삼는다. 스크립트를 실행할 수 없으면 기존 수동 절차를 따르고 그 사실을 보고한다."
   - `ios-tuist-module`, `ios-tuist-dependency`: 변경 후 `check-consumer-edges.sh` 실행, 결과를 Output Contract의 Dependency Changes에 포함.
   - 산문 절차는 **삭제하지 않고 fallback으로 유지**한다 (스크립트 미지원 환경 대비).
4. Golden test
   - `tests/golden/version-evidence/<fixture>.expected.json`: 각 fixture에서 파일 기반 증거 부분의 기대 출력. 명령 기반 값(active 버전 등)은 환경 의존이므로 비교에서 제외하거나 CI matrix 값으로 치환.
   - `tests/golden/consumer-edges/`: `extract-candidate`에 대해 (a) App에 엣지를 추가한 사본 → `no usage found` 기대, (b) usage가 있는 target에 엣지 추가 → `usage found` 기대.
   - `scripts/run-golden-tests.sh` + CI job 추가.

**수락 기준**
- 두 스크립트가 존재하고, 어떤 파일도 수정하지 않음(실행 전후 `git status` 동일)이 테스트로 확인된다.
- 모든 pin 보유 fixture에 대해 version-evidence golden test가 CI에서 통과한다.
- consumer-edge golden test 두 케이스가 통과한다.
- 관련 SKILL.md가 스크립트 실행과 fallback을 모두 서술한다.

**검증**
```bash
./scripts/run-golden-tests.sh
for d in tests/fixtures/*/; do (cd "$d" && git status --porcelain) ; done   # 스크립트 실행 후 변경 없음
grep -rln "collect-version-evidence" skills/ | wc -l   # 버전 안전 절차 보유 스킬 수와 일치
```

---

### WS-B (P0) — 스킬 자기완결성

**근거**
- 10개 SKILL.md 전부가 `../../references/` 또는 `../../templates/`를 링크 (총 42개, `grep -rhn "\.\./\.\./" skills/ | wc -l`로 재확인).
- 각 `skills/*/references/`는 `.gitkeep`만 있는 빈 폴더.
- `ios-tuist-feature` 등 일부 스킬의 Output Contract가 "Same structure as `ios-tuist-bootstrap`"으로 다른 스킬 파일을 참조.

**[검증 필요]** 스킬 폴더 단위 설치 경로(claude.ai 스킬 업로드, Codex skills 디렉터리, 스킬 단위 설치 도구)에서 상위 경로 링크가 실제로 깨지는지 최소 1개 경로에서 직접 확인. 확인 결과를 PR에 기록. 깨지지 않는 것으로 확인되더라도 아래 변경은 진행한다(플러그인 외 배포 경로 대비).

**변경**
1. **원본은 하나로 유지**: 루트 `references/`, `templates/`, (WS-A) `scripts/`가 원본.
2. `scripts/sync-skill-resources.sh`: 각 스킬이 실제로 링크하는 파일만 해당 스킬 폴더로 복사.
   - references → `skills/<skill>/references/`
   - templates → `skills/ios-tuist-bootstrap/templates/` (bootstrap만 사용하는지 재확인)
   - WS-A 스크립트 → 사용하는 스킬의 `skills/<skill>/scripts/`
   - SKILL.md 링크를 `../../references/x.md` → `references/x.md`로 재작성.
   - 복사본 첫 줄(마크다운은 주석, 스크립트는 `#` 주석)에 "GENERATED — edit the root original" 표기.
3. 스킬 간 참조 제거: "Same structure as `ios-tuist-bootstrap`" 같은 문구를 해당 구조의 실제 내용으로 치환 (원본 문구는 공유 reference `references/output-contract.md`로 추출 후 동기화하는 방식 권장).
4. CI `check-skill-resources` job: 동기화 스크립트를 실행한 결과가 커밋된 상태와 다르면 실패 (drift 검사).
5. `skills/*/` 밖을 가리키는 상대 링크가 남아 있으면 실패하는 lint 추가.

**수락 기준**
```bash
grep -rn "\.\./\.\./" skills/          # 결과 없음
grep -rn "Same structure as" skills/   # 결과 없음
./scripts/sync-skill-resources.sh && git diff --exit-code   # drift 없음
```
- 아무 스킬 폴더 하나를 임시 디렉터리로 단독 복사했을 때, SKILL.md의 모든 상대 링크가 그 폴더 안에서 해소된다 (링크 검사 스크립트로 확인).

---

### WS-C (P0) — 라우팅 평가 세트

**근거**
- 기존 벤치마크(2026-09-20)는 "스킬이 선택된 뒤의 수행 품질"만 측정. 올바른 스킬 선택 여부는 측정하지 않음.
- v0.8 WS4에서 description 10개를 재작성하므로, 그 효과와 회귀를 확인할 수단이 필요.
- 공식 Tuist 플러그인(`tuist/agent-plugin`)과의 동시 설치 시 라우팅 충돌 가능성 (v0.8 PRD WS4 근거 참조).

**[검증 필요]**
- headless 실행(`claude -p` 등)에서 **어떤 스킬이 활성화되었는지 관측하는 방법**(출력 로그, 스트리밍 JSON 이벤트 등)을 공식 문서로 확인. 관측 방법이 없으면 대안으로 각 SKILL.md 첫 동작에 고유 마커 출력을 지시하는 방식은 **채택하지 않는다**(평가용 변경이 실제 동작을 바꾸므로). 이 경우 WS-C는 세트 작성과 수동 실행 절차까지만 진행하고 보고.
- Codex에서 동일 관측이 가능한지 확인.

**변경**
1. `tests/routing/cases.yaml` — 30~50개 케이스. 각 항목: `id`, `prompt`, `fixture`(실행 디렉터리), `expected_skill`(또는 `none`), `category`, `note`.
   - 카테고리별 최소 수:
     - 각 스킬 positive: 스킬당 2개 이상 (20+)
     - negative(어떤 스킬도 쓰면 안 됨 / 다른 스킬이어야 함): 8개 이상
     - 인접 스킬 혼동 (feature vs module, dependency vs module, migrate vs restyle 등): 6개 이상
     - 공식 Tuist 스킬 충돌 ("migrate this Xcode project to Tuist", "tuist generate가 실패해" 등): 5개 이상 — 기대값은 `none`(본 플러그인 스킬 미선택) 또는 명시된 본 플러그인 스킬
     - 모호한 요청 ("Tuist 최신으로 정리해줘" 등 → migrate가 선택되면 안 됨): 3개 이상
   - 프롬프트는 한국어·영어 혼합 (실사용 반영).
2. `scripts/run-routing-eval.sh`
   - 조건: `plugin-only` / `plugin+official`(공식 Tuist 플러그인 동시 설치) / `none`(대조군).
   - 각 케이스를 fixture 복사본에서 실행(v0.8 WS6 격리 하네스 재사용), 선택된 스킬 기록.
   - **편집이 일어나지 않도록** 실행 권한을 읽기 전용으로 제한하거나, 첫 스킬 선택 관측 후 중단하는 방식 사용(관측 방법 확인 결과에 따름).
   - 결과: `docs/superpowers/benchmarks/<date>-routing/results.json` + 요약 표 (정확도, 스킬별 precision/recall, 혼동 행렬).
3. 기준선 측정: v0.8 description(재작성 후) 기준 1회 실행 결과를 기록. 이후 description 변경 PR에서는 이 평가를 재실행하고 결과 차이를 PR에 첨부하는 규칙을 `CONTRIBUTING` 또는 README 개발 섹션에 추가.

**수락 기준**
- `cases.yaml`이 위 카테고리별 최소 수를 충족 (스키마 검사 스크립트로 확인).
- 관측 방법이 확인된 경우: 3개 조건 중 최소 `plugin-only`의 1회 결과가 기록됨.
- 관측 방법이 확인되지 않은 경우: 그 사실과 수동 실행 절차가 문서화됨.

---

### WS-D (P1) — 버전 특정 지식 분리 + 정기 재확인

**근거**
- `skills/ios-tuist-restyle/SKILL.md`에 Tuist 4.62.0, 4.100.0, 4.133.1, 4.206.0 및 이슈 #8547 등 버전 특정 결함 지식이 본문에 직접 포함 (`grep -n "4\.[0-9]*\.[0-9]*\|#[0-9]\{4,\}" skills/ios-tuist-restyle/SKILL.md`로 재확인).
- 다른 스킬(test-target, scaffold)에도 4.206.0 기준 서술 존재.

**변경**
1. `references/tuist-known-issues.md` 신설. 항목 형식:
   ```text
   ### <짧은 제목>
   - Affects: <버전 범위>
   - Fixed in: <버전 | unknown>
   - Source: <이슈/PR 링크 또는 저장소 내 재현 fixture>
   - Last verified: <Tuist 버전> on <YYYY-MM-DD>
   - Skill impact: <어느 스킬의 어떤 규칙이 이 항목에 의존하는가>
   ```
2. restyle 등 SKILL.md 본문의 버전 특정 서술을 이 파일로 옮기고, 본문은 "known-issues의 <항목>에 해당하면 …" 형태의 규칙만 남긴다. **규칙의 의미는 바꾸지 않는다.**
3. 정기 재확인 CI (예: 월 1회 `schedule`):
   - 최신 Tuist 릴리스로 restyle 관련 fixture의 generate/build를 실행.
   - 결과가 known-issues의 기대(재현됨/안 됨)와 달라지면 이슈를 생성하거나 job 실패로 알림. 자동 수정은 하지 않는다.
   - **[검증 필요]** "최신 Tuist 버전"을 CI에서 얻는 방법(mise latest 등) 확인.
4. WS-B 동기화 대상에 `tuist-known-issues.md` 포함.

**수락 기준**
- restyle SKILL.md 본문에 특정 패치 버전 번호가 남아 있지 않거나, 남아 있다면 known-issues 항목 링크와 함께 있음.
- known-issues 모든 항목에 `Last verified`가 있음.
- 정기 job 정의가 존재하고 수동 트리거(`workflow_dispatch`)로 1회 실행 결과가 기록됨.

---

### WS-E (P1) — 기계 판독 가능한 Output Contract

**근거**
- 10개 스킬 모두 Output Contract를 자유 텍스트로 정의. 벤치마크 채점은 LLM grader가 텍스트를 읽어 판단(2026-09-20 벤치마크).
- v0.8 addendum A5의 Phase 3(결정론적 지표 우선)를 위해서는 기계가 읽을 수 있는 출력이 필요.

**변경**
1. 모든 스킬의 Output Contract 끝에 고정 형식 블록 추가 (사람용 텍스트는 유지):
   ````text
   ```ios-tuist-result
   skill: <name>
   outcome: completed | refused | blocked | partial
   version_evidence: <collect-version-evidence.sh --json 요약 또는 "unavailable">
   files_changed: [<path>, ...]
   dependency_edges_added: [{from, to, usage: "<file:line>" | "none-found"}]
   dependency_edges_removed: [...]
   validation: {generate: pass|fail|not-run, build: ..., test: ...}
   unverified: [<항목>, ...]
   ```
   ````
   - 필드 정의는 `references/output-contract.md` 한 곳에 두고 WS-B로 동기화.
2. `scripts/parse-skill-result.sh`(또는 ruby): 에이전트 출력에서 블록을 추출해 JSON으로 변환. WS-C, 벤치마크 하네스, golden test가 공유.
3. 벤치마크 하네스(v0.8 WS6)가 이 블록을 파싱해 결정론적 지표(변경 파일 수, 추가 엣지 수, usage 없는 엣지 수, 검증 결과)를 자동 기록하도록 연결.

**수락 기준**
- 10개 SKILL.md가 모두 `ios-tuist-result` 블록을 요구.
- 파서가 저장소의 벤치마크 raw 결과 중 최소 1건(새 형식으로 재실행한 결과)을 파싱해 JSON을 생성.
- 블록 누락 시 파서가 명확한 오류를 반환.

---

### WS-F (P2) — 벤치마크 외부 타당성

**근거**
- 현 fixture 11개는 모두 1~2개 target 규모의 소형 프로젝트.
- 저장소 handoff 문서상 구현은 Codex가 담당하나, 벤치마크는 Claude로만 수행.

**변경**
1. 실규모 fixture 1개 추가 (`tests/fixtures/large-graph/`): target 15개 이상, 외부 패키지 3개 이상, 계층형 의존(app → feature → domain → core), 기존 관례가 일부 비표준인 상태 포함. **실제 회사 코드를 사용하지 않는다** — 합성 프로젝트로 작성.
2. 이 fixture에 대한 시나리오 3개 이상 (module 추출, dependency 추가, architecture-review) + EXPECTATIONS.
3. Cross-agent: v0.8 격리 하네스와 WS-C 라우팅 평가를 Codex로도 실행할 수 있도록 하네스에 agent 선택 인자 추가. **[검증 필요]** Codex headless 실행·관측 방법.
4. 결과는 시험 실행 1회까지만 이번 범위. 반복 측정은 별도 릴리스.

**수락 기준**
- `large-graph` fixture가 CI에서 generate/build/test 통과.
- 하네스가 `--agent claude|codex` 인자를 받는다 (codex 경로는 검증 결과에 따라 "unsupported"로 명시 가능).

---

### WS-G (P2) — Hook 조사 및 결정 기록 (구현 없음)

**배경**
- 플러그인 hook으로 pin 파일 직접 수정 차단, manifest 수정 후 자동 검증 등을 강제할 수 있다.
- 그러나 hook은 플러그인이 설치된 동안 모든 작업에 적용되어 정상 작업을 방해할 수 있고, 다른 에이전트에서의 지원 범위가 다를 수 있다.

**변경**
1. `docs/superpowers/specs/<date>-hooks-decision.md` 작성:
   - Claude Code 플러그인 hook의 현재 지원 이벤트와 범위 **[검증 필요]**
   - Codex의 hook 지원 범위 **[검증 필요]**
   - 후보: (a) `.mise.toml`/`.tool-versions` 수정 시 경고, (b) manifest 수정 후 `check-consumer-edges.sh` 실행 안내
   - 각 후보의 이득, 오탐·방해 위험, 크로스 에이전트 일관성
   - 결론: 채택 / 보류 / 기각과 이유
2. 이번 릴리스에서 hook 구현은 하지 않는다.

---

## 5. 릴리스 체크리스트

- [ ] 1절 선행 조건 충족 확인
- [ ] WS-A, WS-B, WS-C 머지 (P0)
- [ ] WS-D, WS-E는 준비되면 포함, 아니면 v0.9.x
- [ ] `CHANGELOG.md` 기록. 특히:
  - Output Contract 블록 추가(WS-E)는 출력 형식 변경
  - 스킬 폴더 구조 변경(WS-B)은 스킬 단위 배포 사용자에게 영향
- [ ] `.claude-plugin/plugin.json` version → `0.9.0` (v0.8 WS7의 Codex manifest가 있다면 동기화)
- [ ] 각 워크스트림의 [검증 필요] 항목 확인 결과를 PR 또는 CHANGELOG에 기록
- [ ] WS-C 라우팅 평가 기준선 결과를 README 또는 benchmarks 문서에 링크

## 6. 열린 질문

1. 스크립트의 정본 위치: 루트 `scripts/`(동기화) vs 스킬별 독자 보유. 본 PRD는 루트 원본 + 동기화를 기본으로 함.
2. golden test에서 명령 기반 증거(active 버전 등)를 어떻게 다룰지: 제외 vs CI matrix 값 치환.
3. 라우팅 평가의 합격선(예: 전체 정확도, negative 오선택 0건 등)을 기준선 측정 후 정할지.
4. `ios-tuist-result` 블록 필드가 Codex 출력에서도 안정적으로 생성되는지 — WS-F cross-agent 결과로 판단.

## 7. 참고

- v0.8 spec / addendum / plan (`docs/superpowers/specs/`, `docs/superpowers/plans/`)
- 2026-09-20 벤치마크 (`docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/`)
- Tuist 공식 agent plugin: https://github.com/tuist/agent-plugin
