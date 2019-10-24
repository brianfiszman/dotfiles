(use-package ccls
  :ensure t
  :config
  (setq ccls-executable "ccls")
  (setq lsp-prefer-flymake nil)
  (setq ccls-sem-highlight-method 'overlay)
  (setq-default flycheck-disabled-checkers '(c/c++-clang c/c++-cppcheck c/c++-gcc))
  :hook ((c-mode c++-mode objc-mode) .
         (lambda () (require 'ccls) (lsp))))

(use-package yasnippet
  :ensure t
  :config
  ;; Adding yasnippet support to company
  (yas-global-mode 1)
)

(use-package yasnippet-snippets :ensure t)
