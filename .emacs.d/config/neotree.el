(global-set-key [f8] 'neotree-toggle)

(setq neo-theme 'icons) ; 'classic, 'nerd, 'ascii, 'arrow
(setq neo-vc-integration '(face char))

;; every time when the neotree window is  opened, it will try to find current
;; file and jump to node.
(setq-default neo-smart-open t)

(setq neo-show-hidden-files t)
(setq neo-force-change-root t)
