# CI baseline — Validate fixtures (CI-0)

- 측정일: 2026-10-02 (데이터는 2026-09-26 ~ 2026-10-01 실행)
- 대상: `.github/workflows/validate-fixtures.yml` (기준 `0a92010`, `ci/reduce-duplicate-runs` **적용 전**)
- 방법: `gh run list` / `gh run view --json jobs` (job·step 단위 timestamp). 성공한 job만 집계.
- 표본: 성공 run 6개(PR 3, push 3), job 60개. **N이 작으므로 경향 파악용이며 통계적 결론이 아니다.**

## 1. 사실 (측정값)

| 지표 | 평균 | 중앙값 | 최대 |
|---|---|---|---|
| job 실행 시간 (started → completed) | 293 s (4.9분) | 256 s | 654 s |
| run 생성 → job 시작 대기 | **814 s (13.6분)** | 696 s | **2249 s (37.5분)** |

run 전체 시간(생성 → 마지막 job 완료, 대기 포함, `gh run list` createdAt~updatedAt):

| run | 이벤트 | 분 |
|---|---|---|
| 36883011095 / 36883028362 (같은 커밋 쌍) | push / pull_request | 15.1 / 25.0 |
| 36883433587 / 36883440985 (같은 커밋 쌍, 동시 실행) | push / pull_request | 40.6 / 42.4 |
| 36887896322 (`ci/reduce-duplicate-runs`, 단독) | pull_request | 22.0 |
| 36212517330 (main push, 2026-09-26) | push | 11.6 |

Step 평균 (60 job):

| step | 평균 s |
|---|---|
| **Test** | **242** |
| Build | 29 |
| Verify Tuist pin | 6 |
| Install fixture-pinned Tuist | 3 |
| checkout / setup / complete (합) | ~9 |
| Generate project | 1 |
| Resolve dependencies | <1 |

fixture별 평균 job 시간 (s, n=6): architecture-smells 459, modular 370, legacy-tuist 346, restyle-candidate 339, version-mismatch 271, scaffold-candidate 250, test-target-candidate 244, ci-gaps 236, extract-candidate 228, migrate-candidate 190.

중복 실행: 조회한 최근 run 14개 중 **같은 커밋에 push·pull_request 두 run이 생긴 쌍이 4건**. 같은 커밋 쌍이 동시에 돌면 각각 40분대(위 표)로, 쌍이 아닌 단독 run(15~25분)의 약 2배였다.

추가 관측: `develop`으로 PR이 머지되면 `push` 이벤트로 **전체 10 job**이 다시 돈다(#26 머지 후 24분 이상 진행). 이 run이 같은 시간대의 PR run과 러너를 두고 경쟁했다 (#27의 job이 pending이던 시점과 겹침).

## 2. F4 / F5 / F6 확인 (job 1개 로그, **n=1**: `extract-candidate`, run 36887896322)

| 항목 | 관측 | 판정 |
|---|---|---|
| F4 (Build·Test destination 차이 → 이중 컴파일) | Build 단계: App을 `arm64`와 `x86_64` 둘 다 `SwiftDriver`/`SwiftCompile`. Test 단계: App을 `arm64`로 **다시** `SwiftDriver` + `AppTests` 컴파일 | **확인됨 (이 job 한정)** — 다만 컴파일 자체는 수 초 규모 |
| F5 (`test_schemes`에 App 포함 → 별도 Build 중복) | Test 단계가 `App` 타깃을 다시 빌드함 (위와 동일) | **확인됨 (이 job 한정)**. 제거 시 절감 상한은 Build 단계 평균 29 s |
| F6 (시뮬레이터 부팅이 Test 안에서 직렬) | Test 단계 안에서 컴파일은 16:03:27 경 끝나고 `Test Suite 'All tests' started`는 16:05:46 — **약 139초 공백**. xcodebuild가 `IDETestOperationsObserverDebug: 148.393 elapsed`를 출력 | **강하게 시사됨** (시뮬레이터 부팅·테스트 호스트 기동이 Test 단계 242 s의 대부분). 원인 단정은 아님 — 다른 fixture 로그로 재확인 필요 |

## 3. 추정 / 미확인

- **[추정]** 대기 시간이 큰 이유는 macOS 동시 실행 슬롯이 한정돼 10 job이 여러 파도로 나뉘어 시작되기 때문. 근거: 단독 run(36887896322)에서도 job 시작이 4.3분 ~ 17.8분에 걸쳐 분포. 슬롯 개수와 플랜 한도는 **미확인 [검증 필요: GitHub 공식 문서의 해당 플랜 macOS 동시 실행 한도]**.
- **[미확인]** 저장소가 public인지 여부와 과금 상태 (README 커밋 메시지는 public을 시사하나 이 측정에서 확인하지 않음).
- 위 F6 해석(부팅이 병목)은 n=1.

## 4. PRD 항목에 대한 시사점

| PRD 항목 | 측정이 말하는 것 |
|---|---|
| CI-1 중복 제거 | 효과 큼: 동시 쌍이 서로의 대기를 2배로 만들었음 |
| CI-2 경로 기반 선택 | **가장 큰 효과 기대**: 평균 대기(13.6분)가 실행(4.9분)의 약 3배이므로 job 수를 줄이는 것이 지배적. `develop` push 전체 실행은 유지되므로 그 경쟁은 남음 |
| CI-3 중복 컴파일 제거 | Build 단계 병합의 상한 ≈ 29 s/job. **시뮬레이터 사전 부팅(CI-3 변경 2)이 job당 최대 ~2분으로 더 클 가능성** — 먼저 다른 fixture에서 F6 재확인 후 판단 |
| CI-6 동시 한도 대응 | CI-2 이후 재측정해서 판단 (선택지 (a) 가능성 높음) |

## 5. 재측정 계획

- `ci/reduce-duplicate-runs` 병합 후 PR run 3건 이상으로 같은 표를 다시 채워 CI-1의 전후를 비교한다 (이 문서는 "전" 기준).
- CI-2 적용 후: 문서 전용 PR(macOS 0 job)과 fixture 1개 PR의 run 시간을 기록.

## 7. CI-3 근거 — F6 재확인 (n=4)

출처: `develop` push run 36931777728 (2026-10-01, 전체 매트릭스). 각 job의 Test 스텝 로그에서 마지막 컴파일·서명 로그(`Validate …App.app`)와 앱 프로세스 첫 로그(`load_eligibility_plist`) 사이의 무로그 구간을 계산했다.

| job | 무로그 구간 | Test 스텝 전체 | 비고 |
|---|---|---|---|
| modular (`App` 스킴) | 57 s | 63 s | |
| architecture-smells (`App` 스킴) | 106 s | 123 s | |
| extract-candidate | 338 s | 345 s | 이전 측정(run 36887896322)은 139 s — 편차 큼 |
| migrate-candidate | 402 s | 413 s | Tuist 3.42.2 |

- **확인됨**: 4개 job 모두 무로그 구간이 30 s를 넘고, 테스트 실행 자체는 1 s 미만. 같은 job의 두 번째 스킴은 구간이 짧다(약 35~70 s로 `IDETestOperationsObserverDebug` elapsed 기준 읽음).
- **확인됨**: Test 스텝이 `App` 타깃을 다시 컴파일·서명한다(F5, 위 job에서도 CodeSign 로그 존재).
- **추정**: 구간의 정체는 시뮬레이터 부팅·앱 설치 대기. 로그에 "Booting"이 명시되지 않아 직접 증명은 못 했다. 편차(57~402 s)의 원인은 미확인(러너 부하 가능성).
- **판정**: 계획서 Task 3의 게이트(30 s 미만이면 변경 2 생략)를 넘으므로 사전 부팅(변경 2)을 진행한다. 효과는 구현 후 `scripts/ci-measure.py` 전/후 Test 스텝 평균으로 판정하고, 노이즈 수준이면 되돌린다.

## 8. CI-3 결과 — 이득 없음, 되돌림

PR #34(사전 부팅 + `build-for-testing`/`test-without-building`)를 전체 매트릭스로 측정했다. 이전: run 36931777728, 이후: run 37089898049. validate 잡 10개만 비교(`changes`·`fixtures-ok`를 섞으면 평균이 왜곡됨).

| | 이전 | 이후 |
|---|---|---|
| 잡 시간 평균 | 312 s | 323 s |
| 중앙값 | 311 s | 312 s |
| 최대 | 506 s | 529 s |

- **확인됨**: 테스트 개수(`Executed N tests`)는 10개 fixture 모두 동일.
- **확인됨**: `Pre-boot simulator` 스텝이 평균 42 s 소요, `Resolve dependencies` 0→47 s, `Generate project` 2→34 s로 증가. `Build and test` 164 s는 이전 Test 263 s + Build 28 s보다 짧지만 증가분이 상쇄.
- **추정**: 부팅이 같은 러너의 CPU·IO를 두고 resolve/generate와 경쟁. 무로그 구간(§7)의 원인이 시뮬레이터 부팅이라는 가설은 이 측정으로 뒷받침되지 않음.
- **한계**: 각 n=10, 실행 1회. 노이즈 폭(§7에서 같은 구간이 57~402 s)이 개선 폭보다 큼.
- **미실시**: 의도적 컴파일 에러 실패 확인(되돌림으로 불필요해짐).
- **결정**: 계획서 기준("노이즈 수준이면 되돌린다")에 따라 두 변경을 함께 되돌림. 무로그 구간의 원인 규명은 CI-3 후속 과제로 남김.

## 9. CI-6 결정 — 동시 실행 한도 (옵션 (a): 현상 유지)

측정: `validate-fixtures.yml` 성공 run 24건(2026-09 ~ 10-03) 중 CI-2 이후(PR #30 병합 뒤) 8건. wall = run 생성~종료, max_queue = run 생성~가장 늦게 시작한 job.

| 종류 (CI-2 이후) | run | wall | max_queue |
|---|---|---|---|
| 문서 전용 PR | 2건 (36934682516, 37089640584) | 14~15 s | 8~10 s |
| fixture 1개 PR | 1건 (36934687537) | 368 s | 109 s |
| 워크플로 수정 PR(전체 10 job) | 2건 (37089898049, 37091414875) | 934~1363 s | 719~827 s |
| `develop` push(전체 10 job) | 3건 (36934655351, 37089750558, 37091208696) | 755~943 s | 379~566 s |

- **확인됨**: 문서·스킬만 바꾸는 PR은 몇 초 만에 끝난다. 전체 10 job은 `develop` push와 워크플로·CI 스크립트를 고치는 PR에서만 돈다. CI-2 이전에는 거의 모든 run이 10 job이었다(wall 905~2541 s).
- **확인됨 (GitHub 문서, https://docs.github.com/en/actions/reference/limits, 2026-10-03 조회)**: 표준 GitHub-hosted 러너의 최대 동시 macOS job은 Free·Pro·Team 플랜 5개, Enterprise 50개. 10 job 매트릭스는 5개씩 두 파도로 나뉘므로 max_queue가 job 1개 시간(~5분)의 배수로 나타나는 것과 일치한다.
- **미확인**: 이 저장소 계정의 플랜(위 표의 어느 행인지). 한도가 5개라는 것은 Free·Pro·Team일 때만 해당한다.
- **한계**: fixture 1개 PR은 n=1(계획서 기준 ≥3 미달). 전체 10 job run의 wall은 같은 시간대 다른 저장소의 macOS 사용량에도 영향을 받을 수 있어 분리하지 못했다.

**결정: (a) 현상 유지.** 근거: 계획서 (a)의 조건 — 평소 PR이 macOS job을 2개 넘게 쓰지 않고, 남은 대기가 `develop` push와 워크플로 수정 PR에만 있다 — 을 위 표가 충족한다. (b) fixture 묶기는 (a)가 실패할 때만 의미 있고, 사전 부팅 실험(§8)에서 job 고정 비용 중 일부를 줄이는 시도가 이득이 없었다. (c) `max-parallel` 조정은 전체 run이 다른 워크플로를 굶길 때만 필요한데, 이 저장소의 다른 macOS 워크플로가 없어 해당 없음.

**재검토 조건:** 주간 `schedule` 전체 실행(Task 4)을 켠 뒤에도 PR의 `fixtures-ok` 대기가 자주 10분을 넘거나, fixture 수가 늘어 한 파도가 3개 이상이 되면 (b)를 다시 본다. (b)는 실패 격리·요약 요구가 있으므로 별도 계획이 필요하다.
