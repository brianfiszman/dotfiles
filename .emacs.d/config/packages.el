(package-initialize)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(package-initialize)

(setq package-list
 '(package-selected-packages rainbow-delimiters smart-mode-line magit pretty-mode doom-themes web-mode tide rjsx-mode prettier-js pacmacs neotree helm-youtube helm-tramp helm-systemd helm-google helm-git helm-flymake helm-flycheck helm-css-scss fzf emmet-mode auto-complete arch-packer all-the-icons add-node-modules-path))

; install the missing packages
(dolist (package package-list)
(unless (package-installed-p package)
  (package-refresh-contents)
  (package-install 'use-package)))

(eval-when-compile
  (require 'use-package))

(use-package 'package 
  :ensure t
)
(use-package 'neotree
  :ensure t
)
(use-package 'all-the-icons
  :ensure t
)
(require 'server)
(use-package autopair
  :ensure t
  :config
  (autopair-global-mode)
)
(if (not (server-running-p)) (server-start))

(projectile-mode +1)
(define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
