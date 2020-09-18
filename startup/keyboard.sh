# See keycodes here:
# https://developer.apple.com/library/archive/technotes/tn2450/_index.html
hidutil property --set  '{
  "UserKeyMapping": [
    {
      "HIDKeyboardModifierMappingSrc": 0x700000064,
      "HIDKeyboardModifierMappingDst": 0x700000035
    }
  ]
}'
