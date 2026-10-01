# ios-tuist-skills CI 속도 개선 PRD

- 대상 저장소: `doulos76/ios-tuist-skills`
- 대상 파일: `.github/workflows/validate-fixtures.yml`
- 기준 커밋: `0a92010` (develop)
- 관련 브랜치: `origin/ci/reduce-duplicate-runs` (`949314a`, 미머지)
- Implementation owner: Codex — this repo's Claude session only produces spec + plan (CI-0 측정은 읽기 전용이라 Claude가 수행함 → `docs/superpowers/ci/2026-10-baseline.md`)
- 기준 측정 결과 요약 (2026-10-02): 병목은 컴파일이 아니라 **job 시작 전 대기열**(평균 13.6분 vs 실행 평균 4.9분). 상세·우선순위 조정 의견은 baseline 문서 §5.
- 권장 저장 위치: `docs/superpowers/specs/2026-10-02-ci-speedup-design.md`
- 적용 시점: v0.8 구현 **이전**에 CI-0, CI-1을 먼저 적용 권장 (v0.8/v0.9가 PR을 많이 만들기 때문)

---

## 0. Claude Code 작업 지침

1. **측정 먼저.** CI-0의 기준 측정 없이 최적화를 머지하지 않는다. 모든 PR에 변경 전후 소요 시간을 첨부한다.
2. **검증 범위를 줄이지 않는다.** 이 문서의 모든 변경은 "같은 검증을 덜 중복해서, 필요한 곳에만" 실행하는 것이다. fixture가 바뀌었을 때 그 fixture의 generate/build/test가 빠지는 변경은 금지. (저장소의 `ios-tuist-ci` 원칙 "Never remove a validation step"과 같은 기준을 이 저장소 CI에도 적용한다.)
3. **브랜치 보호 규칙은 직접 바꾸지 않는다.** required status check 변경이 필요하면 사용자에게 정확한 변경 내용을 요청한다 (v0.8 handoff 문서의 원칙과 동일).
4. **[검증 필요] 항목**은 실제 실행이나 공식 문서로 확인 후 진행. 미확인 시 PR에 "Unverified"로 기록.
5. git flow: `develop`에서 `ci/<id>` 브랜치, 항목당 PR 하나.

---

## 1. 현황 분석 [워크플로 파일 직접 확인]

| # | 현상 | 영향 |
|---|------|------|
| F1 | `push`가 모든 브랜치에서 실행되고 `pull_request`도 실행됨 | PR 브랜치에 push할 때마다 macOS 10 job이 **두 번** 실행 |
| F2 | 경로 필터 없음 | 문서·SKILL.md만 바꾼 PR에도 10개 fixture 전체 build/test. 최근 커밋 15개 중 대부분이 `docs:`/`chore:` |
| F3 | SKILL.md·references 변경은 fixture 빌드 결과에 영향이 없음 | fixture는 정적인 Tuist 프로젝트. 스킬 문서가 바뀌어도 fixture의 generate/build/test 결과는 동일 |
| F4 | `Build` 단계(`generic/platform=iOS Simulator`)와 `Test` 단계(`id=$SIMULATOR_ID`)의 destination이 다름 | 같은 코드를 두 번 컴파일할 가능성 높음 **[추정 — CI-0 측정으로 확인]** |
| F5 | 모든 fixture의 `test_schemes`에 `App`이 포함됨 | `xcodebuild test -scheme App`이 App을 빌드하므로 별도 `Build` 단계는 중복 **[추정 — 확인 필요]** |
| F6 | 시뮬레이터 부팅이 첫 `xcodebuild test` 안에서 일어남 | 부팅 시간이 직렬로 더해짐 |
| F7 | macOS job 10개 동시 요청 | 계정의 macOS 동시 실행 한도에 따라 대기열 발생 가능 **[검증 필요: 현재 플랜의 macOS 동시 실행 한도]** |
| F8 | 외부 패키지를 쓰는 fixture 없음 | `tuist install`/`fetch`는 빠름. SPM 캐시는 효과 없음 → 하지 않음 |
| F9 | `mise-action`에 `cache: true` 이미 설정 | Tuist 바이너리 설치는 캐시됨 |
| F10 | v0.8/v0.9에서 추가될 검사(pin 정합성, golden test, 리소스 동기화)가 있음 | macOS job에 붙이면 비용 증가 |

참고: `ci/reduce-duplicate-runs` 브랜치가 F1을 이미 해결함 (push를 `main`/`develop`로 제한, PR에서 이전 실행 취소하는 `concurrency`). 미머지 상태.

---

## 2. 목표 / 비목표

### 목표
- 문서·스킬 텍스트만 바뀐 PR: **macOS job 0개**, 수 분 이내 완료
- 특정 fixture만 바뀐 PR: **해당 fixture만** macOS 검증
- fixture 1개 검증 시간 단축 (중복 컴파일 제거)
- `main`/`develop` 머지 커밋과 정기 실행에서는 **전체 matrix 유지**

### 비목표
- 검증 항목 삭제, 테스트 스킵, fixture 축소
- self-hosted runner 재도입 (v0.6 handoff 기준으로 GitHub-hosted로 전환한 결정 유지)
- Tuist cache/원격 캐시 도입 (fixture 규모가 작아 이득 대비 복잡도 큼 — 측정 결과 필요 시 별도 검토)

---

## 3. 작업 항목

| ID | 우선순위 | 작업 | 기대 효과 |
|----|---------|------|----------|
| CI-0 | P0 | 기준 측정 | 이후 판단의 근거 |
| CI-1 | P0 | `ci/reduce-duplicate-runs` 머지 | 중복 실행 제거 (F1) |
| CI-2 | P0 | 변경 경로 기반 fixture 선택 + 집계 job | 문서 PR에서 macOS 0개 (F2, F3) |
| CI-3 | P1 | fixture 내부 중복 컴파일 제거 | job당 시간 단축 (F4, F5, F6) |
| CI-4 | P1 | 비macOS 검사는 ubuntu로 | macOS 비용 증가 방지 (F10) |
| CI-5 | P2 | 정기 전체 실행 | 경로 필터로 생길 수 있는 사각지대 보완 |
| CI-6 | P2 | 동시 실행 한도 대응 (측정 결과에 따라) | 대기열 감소 (F7) |

---

### CI-0 (P0) — 기준 측정

**변경**
1. 최근 성공 실행 5회 이상의 run 단위·job 단위·step 단위 소요 시간을 수집한다.
   ```bash
   gh run list --workflow "Validate fixtures" --limit 10 --json databaseId,event,headBranch,conclusion,createdAt,updatedAt
   gh run view <run-id> --json jobs --jq '.jobs[] | {name, startedAt, completedAt, steps: [.steps[] | {name, startedAt, completedAt}]}'
   ```
2. 다음을 표로 정리해 `docs/superpowers/ci/2026-10-baseline.md`에 기록:
   - run 전체 시간(대기 포함), job 대기 시간(queued → started)
   - step별 평균: mise 설치 / resolve / generate / Build / Test(scheme별)
   - 한 PR에서 같은 커밋에 대해 push·pull_request 두 run이 생긴 사례 수
3. F4·F5 확인: 한 fixture에 대해 `Test` 단계 로그에서 App 타깃이 다시 컴파일되는지(`CompileSwift` 라인 존재 여부) 확인.

**수락 기준**: baseline 문서가 존재하고, F4·F5·F7의 [추정]/[검증 필요]가 측정 결과로 갱신됨.

---

### CI-1 (P0) — 중복 실행 제거 브랜치 머지

**변경**
- `origin/ci/reduce-duplicate-runs`를 최신 develop 기준으로 확인 후 PR → 머지.
- 확인 사항: `concurrency.group`이 PR 번호 기준으로 묶이고, `main`/`develop` push는 취소되지 않는 설정인지 (현재 브랜치 내용상 그렇게 되어 있음 — 재확인).

**수락 기준**: PR 브랜치 push 시 `pull_request` 이벤트 run만 생성됨. 같은 PR에 연속 push 시 이전 run이 취소됨.

---

### CI-2 (P0) — 변경 경로 기반 fixture 선택 + 집계 job

**설계**

```text
changes (ubuntu)            → 어떤 fixture를 검증할지 JSON matrix 계산
validate (macos, matrix)    → 선택된 fixture만 실행 (0개면 job 자체 skip)
fixtures-ok (ubuntu, always)→ validate 결과 집계. 이것만 required check로 사용
```

**선택 규칙** (`scripts/ci-select-fixtures.sh`, 출력: matrix JSON)

| 변경된 경로 | 선택 |
|------------|------|
| `tests/fixtures/<name>/**` | 해당 fixture |
| `.github/workflows/validate-fixtures.yml` | 전체 |
| `scripts/validate-fixtures-locally.sh`, `scripts/ci-select-fixtures.sh` 및 CI가 호출하는 스크립트 | 전체 |
| fixture 공용 설정(있다면, 예: matrix 정의 파일) | 전체 |
| 그 외 (`skills/**`, `references/**`, `docs/**`, `README.md`, `CHANGELOG.md`, `.claude-plugin/**` 등) | 없음 |
| `push` to `main`/`develop`, `workflow_dispatch`, `schedule` | **항상 전체** |

**구현 지침**
1. matrix 정의를 워크플로 안의 `include` 목록에서 `tests/fixtures/ci-matrix.json`(fixture, tuist, workspace, resolve_cmd, test_schemes)으로 옮긴다. `changes` job이 이 파일을 읽어 필터링 후 `fromJSON`으로 `validate`에 전달.
   - **v0.8 WS3 조율 필요**: WS3의 `scripts/check-fixture-pins.sh`가 워크플로 yml의 matrix를 읽도록 계획되어 있으면, 이 JSON을 읽도록 함께 수정한다. WS3가 먼저 머지되었는지 확인하고 순서를 맞춘다.
2. 변경 경로 계산은 서드파티 action 없이 `git diff --name-only <base>...<head>`로 구현 (PR: `github.event.pull_request.base.sha`, push: `github.event.before`). checkout 시 `fetch-depth: 0` 또는 필요한 깊이 지정.
3. 선택 결과가 비면 `validate` job은 `if: needs.changes.outputs.has_fixtures == 'true'`로 skip.
4. `fixtures-ok` job: `if: always()`, `needs: [changes, validate]`. `validate`가 `success` 또는 `skipped`이면 성공, `failure`/`cancelled`면 실패. 이것이 유일한 required check가 되도록 설계.
5. 선택 근거(어떤 경로 때문에 어떤 fixture가 선택되었는지)를 `$GITHUB_STEP_SUMMARY`에 출력.

**사용자에게 요청할 것 (Claude Code가 직접 하지 않음)**
- 브랜치 보호 규칙의 required checks를 현재 10개 fixture job 이름에서 `fixtures-ok` 하나로 변경. 변경하지 않으면 문서 PR에서 skip된 required check 때문에 머지가 막힐 수 있다.

**수락 기준**
- 문서만 바꾼 테스트 PR: macOS job 0개, `fixtures-ok` 성공.
- fixture 1개를 바꾼 테스트 PR: 해당 fixture job 1개만 실행.
- 워크플로 파일을 바꾼 테스트 PR: 전체 실행.
- `develop` push: 전체 실행.
- 선택 스크립트 단위 테스트 (경로 목록 → 기대 matrix) 존재.

---

### CI-3 (P1) — fixture 내부 중복 컴파일 제거

**전제**: CI-0에서 F4·F5(중복 컴파일)가 확인된 경우에만 진행. 확인되지 않으면 이 항목은 보류하고 측정 결과를 보고.

**변경**
1. 별도 `Build` 단계(`generic/platform=iOS Simulator`)를 제거하고, 각 scheme에 대해 같은 destination으로:
   ```bash
   xcodebuild build-for-testing -workspace ... -scheme "$scheme" -destination "id=$SIMULATOR_ID"
   xcodebuild test-without-building -workspace ... -scheme "$scheme" -destination "id=$SIMULATOR_ID"
   ```
   - 첫 scheme(`App`)의 `build-for-testing`이 App 빌드 검증을 겸한다. **이를 PR 설명에 명시**하고, App scheme의 build action이 App 타깃을 포함하는지 fixture별로 확인 (`xcodebuild -list` 또는 생성된 scheme 파일).
   - 같은 job 안에서 DerivedData를 공유하므로 두 번째 scheme부터는 증분 빌드.
2. 시뮬레이터 사전 부팅: `Resolve dependencies` 이전 단계에서 시뮬레이터를 선택해 `xcrun simctl boot`을 백그라운드로 시작하고, 테스트 직전에 `xcrun simctl bootstatus <id> -b`로 대기.
3. 시뮬레이터 선택 로직(현재 ruby 인라인)을 `scripts/ci-pick-simulator.sh`로 분리해 재사용.

**수락 기준**
- 모든 fixture에서 이전과 같은 scheme의 테스트가 실행되고 통과 (테스트 개수 비교 — 로그의 `Executed N tests` 또는 xcresult 요약).
- CI-0 대비 fixture job 평균 시간 감소를 PR에 첨부.
- App 빌드 실패를 의도적으로 만든 임시 커밋에서 job이 실패함을 1회 확인 (검증 범위 유지 확인).

---

### CI-4 (P1) — 비macOS 검사는 ubuntu로

**대상** (v0.8/v0.9에서 추가 예정)
- v0.8 WS3: `check-fixture-pins.sh`
- v0.9 WS-A: golden test 중 파일 기반 증거 부분
- v0.9 WS-B: 스킬 리소스 동기화 drift 검사, 상대 링크 lint
- v0.9 WS-C: `cases.yaml` 스키마 검사
- (선택) SKILL.md frontmatter·description 형식 lint

**변경**
- 별도 워크플로 `lint.yml` (`runs-on: ubuntu-latest`)로 모은다. 이 워크플로는 경로 필터 없이 모든 PR에서 실행해도 비용이 작다.
- Tuist/Xcode가 필요한 검사만 macOS에 둔다. golden test 중 명령 기반 증거(실제 `tuist version` 등)가 필요한 부분은 해당 fixture의 macOS job 안에서 실행.
- 이 항목은 v0.8/v0.9 PRD의 해당 워크스트림 구현 시 **이 원칙을 따르도록** 각 PR에서 적용한다. 별도 선행 작업은 `lint.yml` 골격 생성뿐.

**수락 기준**: `lint.yml`이 존재하고, 새로 추가된 비macOS 검사가 macOS job에 들어가 있지 않음.

---

### CI-5 (P2) — 정기 전체 실행

**변경**
- `validate-fixtures.yml`에 `schedule`(예: 주 1회) 추가 → 항상 전체 matrix.
- 경로 선택 규칙의 사각지대(예: 선택 규칙에 누락된 공용 파일) 탐지 목적.
- v0.9 WS-D(최신 Tuist로 known-issues 재확인)의 정기 job과는 **별도 워크플로**로 유지 (실패 의미가 다름: 이쪽은 회귀, WS-D는 외부 변화 감지).

**수락 기준**: `workflow_dispatch`로 schedule 경로를 1회 수동 실행해 전체 matrix 실행 확인.

---

### CI-6 (P2) — 동시 실행 한도 대응 (측정 결과에 따라)

**전제**: CI-0에서 job 대기 시간이 의미 있게 큰 경우에만.

**선택지** (측정 후 하나를 고르고 근거 기록)
- (a) 그대로 유지: CI-2 적용 후 PR 대부분이 0~2개 job만 돌면 대기 문제는 `main`/`develop`/정기 실행에만 남음.
- (b) 작은 fixture 묶기: 같은 Tuist 버전·소요 시간이 짧은 fixture 2~3개를 한 job에서 순차 실행 → job 수 감소, job당 고정 비용(checkout, mise, 시뮬레이터 부팅) 절감. 단 하나가 실패해도 나머지는 계속 실행하도록(`set +e` 후 결과 집계) 하고, 실패 fixture 이름을 summary에 출력.
- (c) `max-parallel` 조정: 한도 초과로 인한 대기열이 다른 워크플로를 막는 경우.

**수락 기준**: 선택 근거와 전후 측정이 문서화됨.

---

## 4. 순서와 의존

```text
CI-0 측정 ──┬─> CI-1 머지 (즉시 가능, 측정과 병행 가능)
            ├─> CI-2 경로 선택 + fixtures-ok  ──> [사용자] required check 변경
            │        └─ v0.8 WS3와 matrix 위치 조율
            ├─> CI-3 (F4·F5 확인 시)
            └─> CI-6 (대기 시간 큰 경우)
CI-4: lint.yml 골격 먼저, 이후 v0.8/v0.9 각 PR에서 적용
CI-5: CI-2 이후
```

## 5. 위험과 대응

| 위험 | 대응 |
|------|------|
| 경로 선택 규칙 누락으로 깨진 fixture가 PR에서 통과 | `main`/`develop` push와 주간 schedule은 항상 전체 실행 (CI-2, CI-5) |
| required check 미변경으로 문서 PR 머지 불가 | CI-2 PR 설명 최상단에 사용자 조치 사항 명시 |
| CI-3로 App 단독 빌드 검증이 약해짐 | 의도적 실패 커밋으로 1회 확인 + `build-for-testing`이 App 빌드를 포함함을 fixture별 확인 |
| matrix를 JSON으로 옮기며 v0.8 WS3 스크립트와 충돌 | CI-2 착수 전 WS3 머지 여부 확인, 같은 PR 또는 연속 PR로 조율 |

## 6. 열린 질문

1. 현재 계정 플랜의 macOS 동시 실행 한도와 분당 비용 (공개 저장소 여부 포함) — CI-6 판단 근거.
2. 실제 병목이 컴파일인지, 대기열인지, 시뮬레이터인지 — CI-0 결과로 결정. 결과에 따라 CI-3/CI-6의 우선순위를 조정한다.
3. `skills/**` 변경 시에도 fixture 검증이 필요한 경우가 생기는가 — v0.9 WS-A에서 스크립트가 스킬 폴더로 동기화되면, 그 스크립트를 CI가 호출하는 경우 선택 규칙에 해당 경로를 "전체"로 추가해야 한다.
