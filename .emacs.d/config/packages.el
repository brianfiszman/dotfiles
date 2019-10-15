(package-initialize)
(require 'package)
(setq package-list
 '(use-package rainbow-delimiters smart-mode-line magit pretty-mode doom-themes web-mode tide rjsx-mode prettier-js pacmacs neotree helm-youtube helm-tramp helm-systemd helm-google helm-git helm-flymake helm-flycheck helm-css-scss fzf emmet-mode arch-packer all-the-icons add-node-modules-path))

(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

; fetch the list of packages available 
(unless package-archive-contents
  (package-refresh-contents))


(setq package-enable-at-startup nil)

; install the missing packages
(dolist (package package-list)
(unless (package-installed-p package)
  (package-refresh-contents)
  (package-install package)))

(package-initialize)



(eval-when-compile
  (require 'use-package))

(require 'server)
(use-package autopair
  :ensure t
  :config
  (autopair-global-mode)
)
(if (not (server-running-p)) (server-start))

(use-package projectile
  :ensure t
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
)

