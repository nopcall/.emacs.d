;;; module-sh.el --- description

(use-package company-shell
  :defer t
  :config
  (setq company-shell-delete-duplicates t))

(associate! sh-mode :match "/\\.dotfiles/aliases$")
(associate! sh-mode :match "/\\.?z\\(sh/.*\\|profile\\|login\\|logout\\|shrc\\|shenv\\)$")
(associate! sh-mode :match "/\\.?bash\\(/.*\\|rc\\|_profile\\)$")
(after! sh-script
  ;; [pedantry intensifies]
  (defadvice sh-mode (after sh-mode-rename-modeline activate)
    (setq mode-name "sh"))

  (setq sh-indent-after-continuation 'always)

  (define-repl! sh-mode narf/inf-shell)
  (add-hook! sh-mode 'flycheck-mode)
  (add-hook! sh-mode 'electric-indent-local-mode)

  (require 'company-shell)

  ;; Fontify variables in strings
  (add-hook 'sh-mode-hook 'narf|sh-extra-font-lock-activate))

(provide 'module-sh)
;;; module-sh.el ends here