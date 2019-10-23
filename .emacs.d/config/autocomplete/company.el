(use-package company
             :diminish company-mode
             :defines
             (company-dabbrev-ignore-case company-dabbrev-downcase)
             :bind
             (:map company-active-map
                   ("C-n" . company-select-next)
                   ("C-p" . company-select-previous)
                   ("<tab>" . company-complete-common-or-cycle)
                   :map company-search-map
                   ("C-p" . company-select-previous)
                   ("C-n" . company-select-next))
             :custom
             (company-idle-delay 0)
             (company-echo-delay 0)
             (company-minimum-prefix-length 1)
             :hook
             (after-init . global-company-mode)
             (plantuml-mode . (lambda () (set (make-local-variable 'company-backends)
                                              '((company-yasnippet
                                                  ;; company-dabbrev
                                                  )))))
             ((go-mode
                c++-mode
                c-mode
                objc-mode) . (lambda () (set (make-local-variable 'company-backends)
                                             '((company-yasnippet
                                                 company-lsp
                                                 company-files
                                                 ;; company-dabbrev-code
                                                 )))))
             :config
             ;; using child frame
             (use-package company-posframe
                          :hook (company-mode . company-posframe-mode))
             ;; Show pretty icons
             (use-package company-box
                          :diminish
                          :hook (company-mode . company-box-mode)
                          :init (setq company-box-icons-alist 'company-box-icons-all-the-icons)
                          :config
                          (setq company-box-backends-colors nil)
                          (setq company-box-show-single-candidate t)
                          (setq company-box-max-candidates 50)

                          (defun company-box-icons--elisp (candidate)
                            (when (derived-mode-p 'emacs-lisp-mode)
                              (let ((sym (intern candidate)))
                                (cond ((fboundp sym) 'Function)
                                      ((featurep sym) 'Module)
                                      ((facep sym) 'Color)
                                      ((boundp sym) 'Variable)
                                      ((symbolp sym) 'Text)
                                      (t . nil)))))
                          ; ICONS IN COMPLETION
                          (with-eval-after-load 'all-the-icons
                                                (declare-function all-the-icons-faicon 'all-the-icons)
                                                (declare-function all-the-icons-fileicon 'all-the-icons)
                                                (declare-function all-the-icons-material 'all-the-icons)
                                                (declare-function all-the-icons-octicon 'all-the-icons)
                                                (setq company-box-icons-all-the-icons
                                                      `((Unknown . ,(all-the-icons-material "find_in_page" :height 0.7 :v-adjust -0.15))
                                                        (Text . ,(all-the-icons-faicon "book" :height 0.68 :v-adjust -0.15))
                                                        (Method . ,(all-the-icons-faicon "cube" :height 0.7 :v-adjust -0.05 :face 'font-lock-constant-face))
                                                        (Function . ,(all-the-icons-faicon "cube" :height 0.7 :v-adjust -0.05 :face 'font-lock-constant-face))
                                                        (Constructor . ,(all-the-icons-faicon "cube" :height 0.7 :v-adjust -0.05 :face 'font-lock-constant-face))
                                                        (Field . ,(all-the-icons-faicon "tags" :height 0.65 :v-adjust -0.15 :face 'font-lock-warning-face))
                                                        (Variable . ,(all-the-icons-faicon "tag" :height 0.7 :v-adjust -0.05 :face 'font-lock-warning-face))
                                                        (Class . ,(all-the-icons-faicon "clone" :height 0.65 :v-adjust 0.01 :face 'font-lock-constant-face))
                                                        (Interface . ,(all-the-icons-faicon "clone" :height 0.65 :v-adjust 0.01))
                                                        (Module . ,(all-the-icons-octicon "package" :height 0.7 :v-adjust -0.15))
                                                        (Property . ,(all-the-icons-octicon "package" :height 0.7 :v-adjust -0.05 :face 'font-lock-warning-face)) ;; Golang module
                                                        (Unit . ,(all-the-icons-material "settings_system_daydream" :height 0.7 :v-adjust -0.15))
                                                        (Value . ,(all-the-icons-material "format_align_right" :height 0.7 :v-adjust -0.15 :face 'font-lock-constant-face))
                                                        (Enum . ,(all-the-icons-material "storage" :height 0.7 :v-adjust -0.15 :face 'all-the-icons-orange))
                                                        (Keyword . ,(all-the-icons-material "filter_center_focus" :height 0.7 :v-adjust -0.15))
                                                        (Snippet . ,(all-the-icons-faicon "code" :height 0.7 :v-adjust 0.02 :face 'font-lock-variable-name-face))
                                                        (Color . ,(all-the-icons-material "palette" :height 0.7 :v-adjust -0.15))
                                                        (File . ,(all-the-icons-faicon "file-o" :height 0.7 :v-adjust -0.05))
                                                        (Reference . ,(all-the-icons-material "collections_bookmark" :height 0.7 :v-adjust -0.15))
                                                        (Folder . ,(all-the-icons-octicon "file-directory" :height 0.7 :v-adjust -0.05))
                                                        (EnumMember . ,(all-the-icons-material "format_align_right" :height 0.7 :v-adjust -0.15 :face 'all-the-icons-blueb))
                                                        (Constant . ,(all-the-icons-faicon "tag" :height 0.7 :v-adjust -0.05))
                                                        (Struct . ,(all-the-icons-faicon "clone" :height 0.65 :v-adjust 0.01 :face 'font-lock-constant-face))
                                                        (Event . ,(all-the-icons-faicon "bolt" :height 0.7 :v-adjust -0.05 :face 'all-the-icons-orange))
                                                        (Operator . ,(all-the-icons-fileicon "typedoc" :height 0.65 :v-adjust 0.05))
                                                        (TypeParameter . ,(all-the-icons-faicon "hashtag" :height 0.65 :v-adjust 0.07 :face 'font-lock-const-face))
                                                        (Template . ,(all-the-icons-faicon "code" :height 0.7 :v-adjust 0.02 :face 'font-lock-variable-name-face))))))

             ;; Show quick tooltip
             (use-package company-quickhelp
                          :defines company-quickhelp-delay
                          :bind (:map company-active-map
                                      ("M-h" . company-quickhelp-manual-begin))
                          :hook (global-company-mode . company-quickhelp-mode)
                          :custom (company-quickhelp-delay 0.8)))
