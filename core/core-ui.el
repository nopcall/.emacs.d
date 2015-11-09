;;; core-ui.el --- interface settings
;; see lib/ui-defuns.el

(if window-system
    (progn
      (fringe-mode '(3 . 6))
      (setq frame-title-format '(buffer-file-name "%f" ("%b")))
      (setq initial-frame-alist '((width . 120) (height . 80)))
      (set-face-attribute 'default t :font narf-default-font)

      (setq-default indicate-empty-lines t)
      (define-fringe-bitmap 'tilde [0 0 0 113 219 142 0 0] nil nil 'center)
      (setcdr (assq 'empty-line fringe-indicator-alist) 'tilde)
      (set-fringe-bitmap-face 'tilde 'font-lock-comment-face))
  (menu-bar-mode -1))

;; Highlight matching parens
(setq show-paren-delay 0.075)

(blink-cursor-mode     1)    ; do blink cursor
(tooltip-mode         -1)    ; show tooltips in echo area

;; Highlight line
(add-hook! prog-mode 'hl-line-mode)
(add-hook! puml-mode 'hl-line-mode)
(add-hook! markdown-mode 'hl-line-mode)

(setq-default
 blink-matching-paren nil

 ;; Multiple cursors across buffers cause a strange redraw delay for
 ;; some things, like auto-complete or evil-mode's cursor color
 ;; switching.
 cursor-in-non-selected-windows  nil

 uniquify-buffer-name-style      nil

 visible-bell                    nil    ; silence of the bells
 use-dialog-box                  nil    ; avoid GUI
 redisplay-dont-pause            nil
 indicate-buffer-boundaries      nil
 indicate-empty-lines            nil
 fringes-outside-margins         t      ; fringes on the other side of line numbers

 jit-lock-defer-time 0
 jit-lock-stealth-time 3

 resize-mini-windows t)

;; hl-line-mode breaks minibuffer in TTY
;; (add-hook! minibuffer-setup
;;   (make-variable-buffer-local 'global-hl-line-mode)
;;   (setq global-hl-line-mode nil))

;; Hide modeline in help windows
(add-hook! help-mode (setq-local mode-line-format nil))

;; Highlight TODO/FIXME/NOTE tags
(defface narf-todo-face  '((t (:inherit font-lock-warning-face))) "Face for TODOs")
(defface narf-fixme-face '((t (:inherit font-lock-warning-face))) "Face for FIXMEs")
(defface narf-note-face  '((t (:inherit font-lock-warning-face))) "Face for NOTEs")
(add-hook! (prog-mode emacs-lisp-mode)
  (font-lock-add-keywords nil '(("\\<\\(TODO\\((.+)\\)?:?\\)"  1 'narf-todo-face prepend)))
  (font-lock-add-keywords nil '(("\\<\\(FIXME\\((.+)\\)?:?\\)" 1 'narf-fixme-face prepend)))
  (font-lock-add-keywords nil '(("\\<\\(NOTE\\((.+)\\)?:?\\)"  1 'narf-note-face prepend))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package hideshow
  :commands (hs-minor-mode hs-toggle-hiding hs-already-hidden-p)
  :diminish hs-minor-mode
  :init
  (after! evil
    (defun narf-load-hs-minor-mode ()
      (advice-remove 'evil-toggle-fold 'narf-load-hs-minor-mode)
      (hs-minor-mode 1))
    (advice-add 'evil-toggle-fold :before 'narf-load-hs-minor-mode)))

(use-package rainbow-delimiters
  :if (display-graphic-p)
  :commands rainbow-delimiters-mode
  :init (add-hook! (emacs-lisp-mode js2-mode scss-mode) 'rainbow-delimiters-mode)
  :config (setq rainbow-delimiters-outermost-only-face-count 1))

(use-package rainbow-mode :defer t)

(use-package popwin
  :config
  (setq popwin:popup-window-height 25)
  (mapc (lambda (rule) (push rule popwin:special-display-config))
        '(("*quickrun*" :position bottom :height 10 :stick t)
          ("*scratch*" :position bottom :height 20 :stick t :dedicated t)
          ("*helm-ag-edit*" :position bottom :height 20 :stick t)
          (help-mode :position bottom :height 15 :stick t)
          ("^\\*[Hh]elm.*?\\*\\'" :regexp t :position bottom :height 15)
          ("*eshell*" :position left :width 80 :stick t :dedicated t)
          ("*Apropos*" :position bottom :height 40 :stick t :dedicated t)
          ("*Backtrace*" :position bottom :height 15 :stick t)
          ("^\\*Org-Babel.*\\*$" :regexp t :position bottom :height 15)
          ("^\\*Org .*\\*$" :regexp t :position bottom :height 15)
          ))
  (popwin-mode 1))

(use-package volatile-highlights
  :diminish volatile-highlights-mode
  :config
  (vhl/define-extension 'my-evil-highlights
    'evil-yank
    'evil-paste-pop-proxy
    'evil-paste-pop-next
    'evil-paste-after
    'evil-paste-before)
  (vhl/install-extension 'my-evil-highlights)

  (vhl/define-extension 'my-undo-tree-highlights
    'undo-tree-undo 'undo-tree-redo)
  (vhl/install-extension 'my-undo-tree-highlights)
  (volatile-highlights-mode t))

(use-package nlinum
  :commands nlinum-mode
  :preface
  (defvar narf--hl-nlinum-overlay nil)
  (defvar narf--hl-nlinum-line    nil)
  (defvar nlinum-format " %4d  ")
  :init
  (defface linum-highlight-face '((t (:inherit linum))) "Face for line highlights")

  (defun narf|nlinum-enable ()
    (nlinum-mode +1)
    (add-hook! post-command 'narf|nlinum-hl-line))

  (defun narf|nlinum-disable ()
    (nlinum-mode -1)
    (remove-hook 'post-command-hook 'narf|nlinum-hl-line)
    (narf|nlinum-unhl-line))

  (add-hook! (markdown-mode prog-mode scss-mode web-mode) 'narf|nlinum-enable)
  :config
  (defun narf|nlinum-unhl-line ()
    "Highlight line number"
    (when narf--hl-nlinum-overlay
      (let* ((ov narf--hl-nlinum-overlay)
             (disp (get-text-property 0 'display (overlay-get ov 'before-string)))
             (str (nth 1 disp)))
        (put-text-property 0 (length str) 'face 'linum str)
        (setq narf--hl-nlinum-overlay nil
              narf--hl-nlinum-line nil))))

  (defun narf|nlinum-hl-line (&optional line)
    "Unhighlight line number"
    (let ((line-no (or line (line-number-at-pos (point)))))
      (when (and nlinum-mode (not (eq line-no narf--hl-nlinum-line)))
        (let* ((pbol (if line (save-excursion (goto-char (point-min))
                                              (forward-line line-no)
                                              (point-at-bol))
                       (point-at-bol)))
               (peol (1+ pbol)))
          ;; Handle EOF case
          (let ((max (point-max)))
            (when (>= peol max)
              (setq peol max)))
          (jit-lock-fontify-now pbol peol)
          (let* ((overlays (overlays-in pbol peol))
                 (ov (-first (lambda (item) (overlay-get item 'nlinum)) overlays)))
            (when ov
              (narf|nlinum-unhl-line)
              (let* ((disp (get-text-property 0 'display
                                              (overlay-get ov 'before-string)))
                     (str (nth 1 disp)))
                (put-text-property 0 (length str) 'face 'linum-highlight-face str)
                (put-text-property 0 (length str) 'face 'linum-highlight-face str)
                (setq narf--hl-nlinum-overlay ov
                      narf--hl-nlinum-line line-no))))))))

  (add-hook! nlinum-mode
    (setq nlinum--width
          (length (int-to-string (count-lines (point-min) (point-max)))))))


;; Mode-line ;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package spaceline-segments
  :init
  (defvar narf--env-version nil)
  (defvar narf--env-command nil)
  (make-variable-buffer-local 'narf--env-version)
  (make-variable-buffer-local 'narf--env-command)
  :config
  (setq-default
   powerline-default-separator nil
   powerline-height 20)

  (defface mode-line-is-modified nil "Face for mode-line modified symbol")
  (defface mode-line-buffer-file nil "Face for mode-line buffer file path")
  (defface mode-line-buffer-dir  nil "Face for mode-line buffer dirname")

  ;; Custom modeline segments
  (spaceline-define-segment narf-buffer-path
    (if buffer-file-name
        (let* ((project-path (let (projectile-require-project-root) (projectile-project-root)))
               (buffer-path (file-relative-name buffer-file-name project-path))
               (max-length (/ (window-width) 2))
               (path-len (length buffer-path)))
          (concat (file-name-nondirectory (directory-file-name project-path))
                  "/"
                  (if (> path-len max-length)
                      (concat "…" (replace-regexp-in-string
                                   "^.*?/" "/"
                                   (substring buffer-path (- path-len max-length) path-len)))
                    buffer-path)))
      "%b")
    :face (if active 'mode-line-buffer-file 'mode-line-inactive)
    :tight t)

  (spaceline-define-segment narf-buffer-modified
    (concat
     (when buffer-file-name
       (concat
        (when (buffer-modified-p) "[+]")
        (unless (file-exists-p buffer-file-name) "[!]")))
     (if buffer-read-only "[RO]"))
    :face mode-line-is-modified
    :when (not (string-prefix-p "*" (buffer-name)))
    :tight t)

  (spaceline-define-segment narf-buffer-encoding-abbrev
    "The line ending convention used in the buffer."
    (symbol-name buffer-file-coding-system)
    :when (not (string-match-p "\\(utf-8\\|undecided\\)" (symbol-name buffer-file-coding-system))))

  (spaceline-define-segment narf-buffer-position
    "A more vim-like buffer position."
    (let ((start (window-start))
          (end (window-end))
          (pend (point-max)))
      (if (and (eq start 1)
               (eq end pend))
          ":All"
        (let ((perc (/ end 0.01 pend)))
          (cond ((eq start 1) ":Top")
                ((>= perc 100) ":Bot")
                (t (format ":%d%%%%" perc))))))
    :tight-right t)

  (spaceline-define-segment narf-vc
    "Version control info"
    (let ((vc (vc-working-revision buffer-file-name)))
      (when vc
        (format "%s%s" vc (case (vc-state buffer-file-name)
                            ('edited "+")
                            ('conflict "!!!")
                            (t "")))))
    :when (and active vc-mode))

  (spaceline-define-segment narf-env-version
    "A HUD that shows which part of the buffer is currently visible."
    (when (and narf--env-command (not narf--env-version))
      (narf|spaceline-env-update))
    narf--env-version
    :when (and narf--env-version (memq major-mode '(ruby-mode enh-ruby-mode python-mode))))

  (spaceline-define-segment narf-hud
    "A HUD that shows which part of the buffer is currently visible."
    (powerline-hud highlight-face default-face 1)
    :tight-right t)

  (spaceline-define-segment narf-anzu
    "Show the current match number and the total number of matches.  Requires anzu
to be enabled."
    (let ((here anzu--current-position)
          (total anzu--total-matched))
      (when anzu--state
        (concat
         (propertize
          (cl-case anzu--state
            (search (format " %s/%d%s "
                            (anzu--format-here-position here total)
                            total (if anzu--overflow-p "+" "")))
            (replace-query (format " %d replace " total))
            (replace (format " %d/%d " here total)))
          'face highlight-face)
         " ")))
    :when (and active (bound-and-true-p anzu--state))
    :tight t)

  ;; Initialize modeline
  (spaceline-install
   ;; Left side
   '(narf-anzu
     (narf-buffer-path remote-host)
     narf-buffer-modified
     narf-vc
     ((flycheck-error flycheck-warning flycheck-info) :when active))
   ;; Right side
   '((selection-info :face highlight-face)
     narf-env-version
     narf-buffer-encoding-abbrev
     ((major-mode :face (if active 'mode-line-buffer-file 'mode-line-inactive) :tight t)
      (minor-modes :tight t :separator "")
      process :when active)
     (global :when active)
     ("%l·%c" narf-buffer-position)
     )))

(provide 'core-ui)
;;; core-ui.el ends here
