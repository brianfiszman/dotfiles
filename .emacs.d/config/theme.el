(require 'doom-themes)

;; Global settings (defaults)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled

;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each theme
;; may have their own settings.
(load-theme 'doom-one t)

;; Enable flashing mode-line on errors
(doom-themes-visual-bell-config)

;; Enable custom neotree theme (all-the-icons must be installed!)
;(doom-themes-neotree-config)
;; or for treemacs users
(setq doom-themes-treemacs-theme "doom-colors") ; use the colorful treemacs theme
(setq doom-neotree-file-icons 'icons)
;;(setq neo-theme 'icons) ; 'classic, 'nerd, 'ascii, 'arrow
;(doom-themes-treemacs-config)

;; Corrects (and improves) org-mode's native fontification.
(doom-themes-org-config)

(setq sml/no-confirm-load-theme t)
(sml/setup)
(setq sml/theme 'dark)

(require 'semantic)
(global-semanticdb-minor-mode 1)
(global-semantic-idle-scheduler-mode 1)
(semantic-mode 1)

(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)
