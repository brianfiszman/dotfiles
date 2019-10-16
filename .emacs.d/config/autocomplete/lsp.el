(use-package lsp-mode
  :commands lsp
  :ensure t
  :hook (js2-mode . lsp)
  :hook (rjsx-mode . lsp)
  :hook (sh-mode . lsp)
  :commands lsp)
(use-package lsp-ui
  :commands lsp-ui-mode
  :ensure t
  :config
  (setq lsp-ui-sideline-ignore-duplicate t)
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
)
(use-package company-lsp
  :ensure t
  :commands company-lsp
  :config (push 'company-lsp company-backends)
    ;; lsp extras
) ;; add company-lsp as a backend
