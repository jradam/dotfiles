; This expands tailwind-sorter's matching in TypeScript files

; Match "const classes = ..."
(variable_declarator
  name: (identifier) @var_name
  (#eq? @var_name "classes")
  value: (string
    (string_fragment) @tailwind))

; Match assignments to any object's "className" property
(expression_statement
  (assignment_expression
    left: (member_expression
      object: (_)
      property: (property_identifier) @prop)
    right: (string
      (string_fragment) @tailwind))
  (#eq? @prop "className"))
