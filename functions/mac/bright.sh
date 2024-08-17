function bright() {
    local json_input='{"UserKeyMapping":[
        {
            "HIDKeyboardModifierMappingSrc": 0xC00000221,
            "HIDKeyboardModifierMappingDst": 0xFF00000009
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000CF,
            "HIDKeyboardModifierMappingDst": 0xFF00000008
        }
    ]}'

    hidutil property --set "$json_input" > /dev/null 2>&1
}