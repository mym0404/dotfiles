;; extends

((protocol_declaration name: (type_identifier) @code.interface) (#set! priority 200))
((class_declaration name: (type_identifier) @code.class) (#set! priority 200))
((custom_operator) @code.operator (#set! priority 200))
((parameter name: (simple_identifier)) @code (#set! priority 150))
((value_argument name: (value_argument_label) @code) (#set! priority 150))

