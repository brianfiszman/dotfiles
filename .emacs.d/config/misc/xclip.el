(use-package xclip
  :ensure t
  :if (eq system-type 'gnu/linux)
  :config
  (xclip-mode 1))
