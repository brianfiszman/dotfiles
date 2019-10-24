(use-package ag
  :custom
  (ag-highligh-search t)
  (ag-reuse-buffers t)
  (ag-reuse-window t)
  :bind
  ("M-s a" . ag-project)
  :config
  (use-package wgrep-ag))
