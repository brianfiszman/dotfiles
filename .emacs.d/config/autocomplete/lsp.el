(use-package lsp-mode
             :commands lsp
             :ensure t
             :custom
             ;; debug
             (lsp-print-io nil)
             (lsp-trace nil)
             (lsp-print-performance nil)
             ;; general
             (lsp-auto-guess-root t)
             (lsp-document-sync-method 'incremental) ;; none, full, incremental, or nil
             (lsp-response-timeout 10)
             (lsp-prefer-flymake t) ;; t(flymake), nil(lsp-ui), or :none
             :bind
             (:map lsp-mode-map
                   ("C-c r"   . lsp-rename))
             :hook (js2-mode . lsp)
             :hook (rjsx-mode . lsp)
             :hook (sh-mode . lsp)
             :commands lsp)
(use-package lsp-ui
             :commands lsp-ui-mode
             :ensure t
             :custom
             ;; lsp-ui-doc
             (lsp-ui-doc-enable nil)
             (lsp-ui-doc-header t)
             (lsp-ui-doc-include-signature nil)
             (lsp-ui-doc-position 'at-point) ;; top, bottom, or at-point
             (lsp-ui-doc-max-width 120)
             (lsp-ui-doc-max-height 30)
             (lsp-ui-doc-use-childframe t)
             (lsp-ui-doc-use-webkit t)
             ;; lsp-ui-flycheck
             (lsp-ui-flycheck-enable nil)
             ;; lsp-ui-sideline
             (lsp-ui-sideline-enable nil)
             (lsp-ui-sideline-ignore-duplicate t)
             (lsp-ui-sideline-show-symbol t)
             (lsp-ui-sideline-show-hover t)
             (lsp-ui-sideline-show-diagnostics nil)
             (lsp-ui-sideline-show-code-actions t)
             (lsp-ui-sideline-code-actions-prefix "")
             ;; lsp-ui-imenu
             (lsp-ui-imenu-enable t)
             (lsp-ui-imenu-kind-position 'top)
             ;; lsp-ui-peek
             (lsp-ui-peek-enable t)
             (lsp-ui-peek-peek-height 20)
             (lsp-ui-peek-list-width 50)
             (lsp-ui-peek-fontify 'on-demand) ;; never, on-demand, or always
             :preface
             (defun ladicle/toggle-lsp-ui-doc ()
               (interactive)
               (if lsp-ui-doc-mode
                 (progn
                   (lsp-ui-doc-mode -1)
                   (lsp-ui-doc--hide-frame))
                 (lsp-ui-doc-mode 1)))
             :bind
             (:map lsp-mode-map
                   ("C-c C-r" . lsp-ui-peek-find-references)
                   ("C-c C-j" . lsp-ui-peek-find-definitions)
                   ("C-c i"   . lsp-ui-peek-find-implementation)
                   ("C-c m"   . lsp-ui-imenu)
                   ("C-c s"   . lsp-ui-sideline-mode)
                   ("C-c d"   . ladicle/toggle-lsp-ui-doc))
             :hook
             (lsp-mode . lsp-ui-mode)
             )
(use-package company-lsp
             :ensure t
             :commands company-lsp
             :custom
             (company-lsp-cache-candidates t)
             (company-lsp-async t)
             (company-lsp-enable-snippet t)
             (company-lsp-enable-recompletion t)
             :config (push 'company-lsp company-backends)
             ;; lsp extras
             ) ;; add company-lsp as a backend
