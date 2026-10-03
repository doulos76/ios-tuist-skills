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
