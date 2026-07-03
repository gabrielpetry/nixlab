;; Inject PromQL into YAML expr field values
(block_mapping_pair
  key: (flow_node) @_key (#eq? @_key "expr")
  value: (flow_node
    (plain_scalar
      (string_scalar) @injection.content))
  (#set! injection.language "promql"))

(block_mapping_pair
  key: (flow_node) @_key (#eq? @_key "expr")
  value: (block_node
    (block_scalar) @injection.content)
  (#set! injection.language "promql"))
