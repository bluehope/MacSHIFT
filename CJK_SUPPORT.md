# MacSHIFT CJK 지원 설계안

프로젝트 이름은 `MacSHIFT — Synchronized Handoff of Input-method Frameworks for Remote Typing`을 사용합니다. 현재의 한국어/영어 동기화에 일본어와 중국어를 추가해도 이름을 바꾸지 않아도 됩니다.

저장소 이름 예시:

```text
macshift-ime
```

## 현재 상태

현재 실행 구현은 다음 두 목표 상태를 지원합니다.

- `EN`: `com.apple.keylayout.ABC`
- `KO`: `com.apple.inputmethod.Korean.2SetKorean`

`config.cjk.example.lua`는 일반화 방향을 보여주는 예시이며, 현재 구현에서 바로 사용할 수 있는 설정 파일은 아닙니다.

## CJK 일반화에 필요한 변경

### 1. 고정 필드를 언어 맵으로 변경

현재:

```lua
abcSourceID = "..."
koreanSourceID = "..."
```

변경 방향:

```lua
sources = {
    EN = { label = "English", sourceID = "..." },
    KO = { label = "한국어", sourceID = "..." },
    JA = { label = "日本語", sourceID = "..." },
    ZH_HANS = { label = "简体中文", sourceID = "..." },
    ZH_HANT = { label = "繁體中文", sourceID = "..." },
}
```

일본어·중국어 Source ID는 Mac에 활성화된 입력 소스와 설치된 입력기마다 다를 수 있으므로 이름으로 추정하지 않고 `layouts(true)`/`methods(true)` 결과에서 선택해야 합니다.

### 2. 토글을 순환 모델로 변경

현재 Right Shift는 `KO ↔ EN`만 전환합니다. CJK에서는 다음처럼 순환합니다.

```lua
cycle = { "EN", "KO", "JA", "ZH_HANS", "ZH_HANT" }
```

현재 Source ID가 목록에 있으면 다음 항목을 선택하고, 알 수 없는 Source ID이면 `EN` 또는 설정된 기본 언어로 복구합니다.

### 3. 원격 신호 확장

언어별 명시 신호를 별도로 둡니다.

```text
F18 = EN
F19 = KO
F20 = JA
F21 = ZH_HANS
F22 = ZH_HANT
```

F20 이상이 Jump Desktop에서 전달되는지는 실제 Viewer/Connect 조합에서 확인해야 합니다. 전달되지 않으면 Shift+F18 계열 또는 4-modifier 조합을 언어별로 시험합니다.

### 4. 단축키와 알림 일반화

- `Set Both KO` 같은 고정 문구를 `Set Both 한국어`로 변경
- 메뉴바나 명시 단축키에서 언어 목록을 표시
- 오류에 Source ID와 사람이 읽는 언어 이름을 함께 표시
- Right Shift 동작 시 `MacSHIFT → 日本語`처럼 표시

### 5. 검증 강화

각 언어별로 다음을 검증해야 합니다.

- Source ID가 실제 활성 목록에 존재하는가
- 신호가 원격으로 전달되는가
- 신호가 원격 앱에 문자나 기능키로 누출되지 않는가
- 한글 조합, 일본어 Romaji/Kana 입력, 중국어 병음/주음 입력이 정상인가
- 네 언어 이상을 순환할 때 첫 글자와 조합 중 문자가 유실되지 않는가

## 권장 구현 순서

1. `sources` 맵과 `cycle`을 추가하되 legacy `abcSourceID/koreanSourceID`도 잠시 지원
2. 언어별 Source ID 검증 함수 작성
3. `setTarget(languageCode)`와 `receive(languageCode)`로 내부 API 일반화
4. Right Shift 순환 동작 일반화
5. F18~F22 전달 시험
6. KO/EN 회귀 테스트 후 JA/ZH 테스트 추가
7. 설정 마이그레이션 및 README 업데이트

## 주의

중국어·일본어 입력기는 “언어” 하나가 여러 입력 방식으로 구성될 수 있습니다. 따라서 `JA`, `ZH_HANS`, `ZH_HANT`를 자동으로 하나씩 추측하는 방식은 사용하지 않고, 사용자가 실제 사용할 입력 Source ID를 확인해 설정하도록 해야 합니다.
