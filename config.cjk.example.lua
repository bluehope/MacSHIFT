-- 예시 전용 설정입니다.
-- 현재 hammerspoon/ime_sync.lua는 legacy abcSourceID/koreanSourceID
-- 형식을 사용하므로, 이 파일을 config.lua로 바로 복사하지 마십시오.
-- CJK 일반화 구현 후 사용할 목표 설정 예시입니다.

return {
    role = "both",

    sources = {
        EN = {
            label = "English",
            sourceID = "com.apple.keylayout.ABC",
        },
        KO = {
            label = "한국어",
            sourceID = "com.apple.inputmethod.Korean.2SetKorean",
        },
        JA = {
            label = "日本語",
            sourceID = "<확인 필요: 일본어 Source ID>",
        },
        ZH_HANS = {
            label = "简体中文",
            sourceID = "<확인 필요: 중국어 간체 Source ID>",
        },
        ZH_HANT = {
            label = "繁體中文",
            sourceID = "<확인 필요: 중국어 번체 Source ID>",
        },
    },

    -- Right Shift는 현재 소스의 다음 언어로 이동합니다.
    cycle = { "EN", "KO", "JA", "ZH_HANS", "ZH_HANT" },

    -- F20 이상은 Jump Desktop 전달 여부를 장치별로 검증해야 합니다.
    signalKeys = {
        EN = "f18",
        KO = "f19",
        JA = "f20",
        ZH_HANS = "f21",
        ZH_HANT = "f22",
    },
}
