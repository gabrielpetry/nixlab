;; Custom highlights for Prometheus YAML files
;; YAML keys - green
(block_mapping_pair
  key: (flow_node) @yaml.key)

;; YAML values (non-expr) - white
(block_mapping_pair
  key: (flow_node) @_key (#not-eq? @_key "expr")
  value: (flow_node) @yaml.value)

(block_mapping_pair
  key: (flow_node) @_key (#not-eq? @_key "expr")
  value: (block_node) @yaml.value)
