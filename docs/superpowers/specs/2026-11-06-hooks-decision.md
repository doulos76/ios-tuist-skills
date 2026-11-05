# Hook 도입 결정 기록 (v0.9 WS-G)

- 작성일: 2026-11-06 (공식 문서 확인일 동일)
- 범위: 조사와 결정만. 이번 릴리스에서 hook은 구현하지 않는다 (PRD WS-G 변경 2).
- 표기: **[확인]** = 공식 문서에서 확인, **[Unverified]** = 확인하지 못함, **[추정]** = 확인된 사실로부터의 추론.

## 1. 조사 결과

### 1.1 Claude Code

출처: [Hooks reference](https://code.claude.com/docs/en/hooks), [Plugin manifest reference](https://code.claude.com/docs/en/plugins-reference) (2026-11-06 조회; hooks 페이지는 앞 100,000자/286,092자만 읽음).

- **[확인]** 이벤트 33종 (`PreToolUse`, `PostToolUse`, `FileChanged`, `SessionStart`, `Stop` 등).
- **[확인]** `PreToolUse` 차단: exit code 2(stderr가 사유) 또는 `hookSpecificOutput.permissionDecision`의 `allow|deny|ask|defer`. exit 0에 출력이 없으면 결정 없음(기존 권한 흐름).
- **[확인]** matcher는 `tool_name`에 대해 동작한다. 문자·숫자·`_`·`-`·공백·`,`·`|`만 있으면 정확 일치 또는 목록(`Edit|Write`), 그 외 문자가 있으면 JS 정규식. 인자 기준 필터는 별도 `if` 필드(예: `Bash(git *)`).
- **[확인]** 플러그인은 `hooks/hooks.json`(최상위 `hooks` 래퍼 필요) 또는 `plugin.json`의 `hooks` 필드로 hook을 싣는다. 둘은 함께 로드·병합된다. 스크립트는 `${CLAUDE_PLUGIN_ROOT}`로 참조한다.
- **[확인]** 범위: 위치 표에 "When plugin is enabled", 사용자·프로젝트 hook과 병합. **[Unverified]** "모든 세션에 적용"이라는 문구 자체는 문서에 없다. 다만 matcher가 스킬 활성 여부를 구분하는 필드가 없으므로 **[추정]** 플러그인이 켜져 있으면 스킬과 무관하게 실행된다.
- **[확인]** 성공(exit 0) 시 stderr는 Claude에 보이지 않는다. `PostToolUse` 경고를 Claude에 전달하려면 exit 2(도구는 이미 실행됨) 또는 `additionalContext`를 쓴다.
- **[Unverified]** `Edit`/`Write`의 `tool_input.file_path` 필드 스키마. 읽은 범위에서는 MCP 예시에만 나온다. 구현 전에 실제 입력을 덤프해 확인해야 한다.
- **[Unverified]** `Bash`로 하는 파일 수정(`sed -i`, 리다이렉트)은 `Edit|Write` matcher로 잡히지 않는다 **[추정]**.

### 1.2 Codex

출처: [Codex hooks](https://developers.openai.com/codex/hooks) (308로 `learn.chatgpt.com/docs/hooks`에 리다이렉트되어 그곳을 읽음, 2026-11-06). 로컬 확인: `codex-cli 0.166.0`, `codex features list`에서 `hooks stable true`, `plugin_hooks removed false`.

- **[확인]** 이벤트: SessionStart, SessionEnd, PreToolUse, PermissionRequest, PostToolUse, PreCompact, PostCompact, UserPromptSubmit, SubagentStart, SubagentStop, Stop, Interrupt, PreModelRequest, PostModelRequest.
- **[확인]** PreToolUse/PostToolUse는 shell, `apply_patch`, MCP, 기타 로컬 function tool을 포함한다. `Edit`/`Write` matcher는 `apply_patch`의 별칭이고, hook 입력의 `tool_name`은 `apply_patch`로 온다. `tool_input.command`가 patch 텍스트를 담는다 **[확인: Bash와 apply_patch가 `tool_input.command` 사용]**.
- **[확인]** 차단: `permissionDecision: "deny"` JSON 또는 exit code 2. `ask`는 "parsed but not supported yet".
- **[확인]** 비관리형 hook은 검토·신뢰(`/hooks`, 해시 기준) 전에는 실행되지 않는다. 변경되면 다시 검토 대상이 된다. `--dangerously-bypass-hook-trust`로 우회 가능.
- **[확인]** 플러그인 hook: 기본 위치 `hooks/hooks.json`, 매니페스트는 `.codex-plugin/plugin.json`의 `hooks` 항목. 같은 이벤트 스키마이며 신뢰 검토 필요.
- **[확인]** 문서의 한계 서술: "Treat tool hooks as a useful guardrail, not a complete enforcement boundary."
- **[Unverified]** 이 저장소는 `.claude-plugin/`만 있고 `.codex-plugin/`이 없다. 이전 조사(메모리, Codex 0.160.0)로는 Codex가 `.claude-plugin/`만으로 설치되지만, 그 경우 `hooks/hooks.json`이 로드되는지는 확인하지 못했다.
- **[Unverified]** 플러그인 hook이 신뢰 검토를 거치는 UX(설치 직후 첫 세션에서 사용자가 `/hooks`를 열어야 하는지).

## 2. 후보 평가

현재 증거: 이번 WS-F 시험(2026-11-05, 6개 실행)에서 `.tool-versions`, `Tuist/`, `Packages/` 변경은 0건이었고, 소비 엣지는 모두 올바른 타깃에만 추가되었다. 즉 두 후보가 막으려는 실패가 관찰되지 않았다.

### (a) pin 파일(`.mise.toml`, `.tool-versions`, `.tuist-version`) 수정 시 경고

| 항목 | 평가 |
|---|---|
| 이득 | `ios-tuist-migrate` 밖에서의 pin 변경을 즉시 알린다. 스킬 규칙("migrate만 pin 변경 가능")의 기계적 보강. |
| 오탐·방해 | 플러그인이 켜진 모든 세션·모든 프로젝트에서 실행된다. 사용자가 직접 요청한 pin 수정, 비 Tuist 프로젝트의 `.tool-versions`(예: Ruby/Node), `ios-tuist-migrate` 실행 중의 정당한 수정이 모두 경고 대상이 된다. 스킬 활성 여부를 hook이 알 수 없다 **[추정]**. |
| 우회 | Claude에서는 `Bash` 수정이 `Edit|Write` matcher에 안 잡힌다. 경고만으로는 강제도 아니다. |
| 크로스 에이전트 | Claude는 `Edit|Write` + file_path, Codex는 `apply_patch`의 patch 텍스트 파싱이 필요해 구현이 달라진다. Codex는 신뢰 검토 절차가 추가된다. |
| 유지 비용 | 이벤트·입력 스키마가 변하는 두 에이전트에 맞춘 스크립트 2벌과 테스트. 입력 스키마가 [Unverified]. |

### (b) manifest 수정 후 `scripts/skill/check-consumer-edges.sh` 실행 안내

| 항목 | 평가 |
|---|---|
| 이득 | 불필요한 소비 엣지(v0.8 WS1 결함)를 편집 직후 상기시킨다. |
| 오탐·방해 | `Project.swift`·`Tuist/Package.swift`의 모든 편집(사용자 직접 편집 포함)에서 안내가 나온다. 스크립트는 검사할 타깃·의존성 인자가 필요한데, hook은 어떤 엣지가 새로 생겼는지 모른다 **[추정]** (diff를 파싱해야 함). `.external` 엣지는 스크립트가 다루지 않는다(EXPECTATIONS.md의 알려진 한계). |
| 크로스 에이전트 | (a)와 같다. 추가로 PostToolUse 경고를 Claude에 전달하려면 exit 2 또는 `additionalContext`가 필요하다 **[확인]**. |
| 유지 비용 | (a)보다 크다(편집 diff 해석 로직). |

## 3. 권고안 (Claude)

| 후보 | 권고 | 이유 |
|---|---|---|
| (a) pin 경고 | **보류** | 관찰된 위반이 없다(시험 6/6 무변경). 활성 스킬을 알 수 없어 정당한 작업에도 경고하고, Bash 우회가 있으며, 두 에이전트의 구현이 달라진다. 벤치마크 하니스의 변경 파일 검사로 이미 사후 감지되고 있다. 다시 볼 조건: 다른 스킬이 pin 파일을 수정한 사례가 하나라도 관찰될 때. |
| (b) 엣지 점검 안내 | **기각** (현재 설계로는) | hook이 새 엣지를 알 수 없어 안내가 일반론이 되고, 모든 manifest 편집에 소음이 생긴다. 스킬 본문이 이미 스크립트 실행을 지시하며 시험에서 엣지가 올바르게 추가되었다. 필요하면 hook이 아니라 스킬의 검증 단계를 강화하는 쪽이 낫다. |

공통 전제: 두 후보 모두 구현 전에 (1) Claude `Edit`/`Write`의 `tool_input.file_path`, (2) Codex 플러그인의 `hooks/hooks.json` 로드 여부를 실제로 확인해야 한다.

## 4. 결정

사용자 결정 (2026-11-06): 권고안 그대로 채택.

- (a) pin 경고: **보류**. 다른 스킬이 pin 파일을 수정한 사례가 관찰되면 재검토.
- (b) 엣지 점검 안내: **기각**. 필요하면 hook이 아니라 스킬의 검증 단계 강화로 다룬다.
- 이번 릴리스(v0.9.1)에서 hook은 구현하지 않는다.
