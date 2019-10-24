(use-package ssh-config-mode
  :ensure t
  :mode ("/\\.ssh/config\\'" "/system/ssh\\'" "/sshd?_config\\'" "/known_hosts\\'" "/authorized_keys2?\\'")
  :hook (ssh-config-mode . turn-on-font-lock)

  :config
  (autoload 'ssh-config-mode "ssh-config-mode" t))

(use-package ssh :ensure t)
(use-package ssh-deploy :ensure t)
(use-package symon :ensure t :defer t)
