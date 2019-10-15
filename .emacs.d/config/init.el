(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(show-paren-mode 1)
(blink-cursor-mode -1)

(global-hl-line-mode +1)
(line-number-mode +1)
(global-display-line-numbers-mode 1)
(column-number-mode t)
(size-indication-mode t)

(defun my/disable-line-numbers (&optional dummy)
    (display-line-numbers-mode -1))
(add-hook 'neo-after-create-hook 'my/disable-line-numbers)

(add-to-list 'default-frame-alist '(font . "Fira Code Retina"))

(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-indicate-empty-lines))

;; disable auto-save and auto-backup
(setq auto-save-default nil)
(setq make-backup-files nil)

(delete-selection-mode t)
(transient-mark-mode t)
(setq x-select-enable-clipboard t)

(defalias 'yes-or-no-p 'y-or-n-p)

(ido-mode t)
(setq ido-enable-flex-matching t
      ido-use-virtual-buffers t)

(setq column-number-mode t)

(setq backup-directory-alist `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))
