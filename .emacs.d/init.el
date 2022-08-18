(setq gc-cons-threshold 100000000)

(setq read-process-output-max (* 1024 1024)) ;; 1mb

(global-unset-key (kbd "C-M-q"))
  (global-set-key (kbd "<f6>") (lambda() (interactive)(find-file "~/workspace/dotfiles/emacs.org")))
  (global-set-key (kbd "<f7>") (lambda() (interactive)(dired "/Users/tomelliott/Library/CloudStorage/Box-Box/worg")))
  (global-set-key (kbd "C-M-!") (lambda() (interactive)(delete-other-windows)))
  (global-set-key (kbd "C-M-@") (lambda() (interactive)(split-window-below)))
  (global-set-key (kbd "C-M-£") (lambda() (interactive)(split-window-right)))
  (global-set-key (kbd "C-M-w") (lambda() (interactive)(switch-to-next-buffer)))
  (global-set-key (kbd "C-M-q") (lambda() (interactive)(switch-to-prev-buffer)))

(global-set-key (kbd "M-3") '(lambda () (interactive) (insert "#")))

(cd "~")
(desktop-save-mode 1)
(setq inhibit-startup-message t)

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Flashes the mode line for visible bell
;; https://stuff-things.net/2015/10/05/emacs-visible-bell-work-around-on-os-x-el-capitan/n
(setq visible-bell nil)
(setq ring-bell-function (lambda ()
                           (invert-face 'mode-line)
                           (run-with-timer 0.1 nil 'invert-face 'mode-line)))

(column-number-mode)
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(defvar runemacs/default-font-size 135)

(if (eq system-type 'windows-nt)
(setq te-font-face "courier")
(setq te-font-face "Fira Code")
)
(set-face-attribute 'default nil :font te-font-face :height runemacs/default-font-size)

;; Initialize package sources
  (require 'package)

  (setq package-archives '(("melpa" . "https://melpa.org/packages/")
                           ("org" . "https://orgmode.org/elpa/")
                           ("elpa" . "https://elpa.gnu.org/packages/")))
  (package-initialize)

(if (eq system-type 'darwin)
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize))
  (unless package-archive-contents
   (package-refresh-contents))
)

  ;; Initialize use-package on non-Linux platforms
  (unless (package-installed-p 'use-package)
    (package-install 'use-package))

  (require 'use-package)
  (setq use-package-always-ensure t)

(use-package general)
(general-create-definer my-leader-def
  ;; :prefix my-leader
  ;; or without a variable
  :prefix "SPC")
  :(general-define-key
 :states '(normal visual insert emacs)
 :prefix "SPC"
 :non-normal-prefix "M-SPC"
  "'" '(iterm-focus :which-key "iterm")
  "?" '(iterm-goto-filedir-or-home :which-key "iterm - goto dir")
  "/" '(counsel-ag :wich-key "ag")
  "TAB" '(ivy-switch-buffer :which-key "prev buffer")
  "." '(avy-goto-word-or-subword-1  :which-key "go to word")
  "SPC" '(counsel-M-x :which-key "M-x")
  "b" '(hydra-buffer/body t :which-key "Buffer")
  "c" '(:ignore t :which-key "Comment")
  "cl" '(comment-or-uncomment-region-or-line :which-key "comment line")
  "w" '(hydra-window/body :which-key "Window")
  "p" '(hydra-projectile/body t :which-key "Buffer")
  "s" '(:ignore t :which-key "Swiper")
  "sS" '(swiper-isearch :which-key "Search")
  "ss" '(swiper-thing-at-point :which-key "Thing at Point")
  "f" '(:ignore t :which-key "Code folder")
  "ff" '(yafolding-toggle-element :which-key "Toggle Element")
  "fa" '(yafolding-toggle-all :which-key "Toggle All")
  "(" '(:ignore t :which-key "Insert Pair")
  "((" '(insert-pair :which-key "(")
  "({" '(insert-pair :which-key "{")
  "([" '(insert-pair :which-key "[")
  "('" '(insert-pair :which-key "'")
  "(\"" '(insert-pair :which-key "\"")
  )
(defhydra hydra-buffer (:color blue :columns 3)
  "
                Buffers :
  "
  ("n" next-buffer "next" :color red)
  ("b" ivy-switch-buffer "switch")
  ("B" ibuffer "ibuffer")
  ("p" previous-buffer "prev" :color red)
  ("C-b" buffer-menu "buffer menu")
  ("N" evil-buffer-new "new")
  ("d" kill-this-buffer "delete" :color red)
  ;; don't come back to previous buffer after delete
  ("D" (progn (kill-this-buffer) (next-buffer)) "Delete" :color red)
  ("s" save-buffer "save" :color red))


(defhydra hydra-projectile
  (:color teal :hint nil)
  "
     PROJECTILE: %(projectile-project-root)

  ^Find File^        ^Search/Tags^        ^Buffers^       ^Cache^                    ^Project^
  ^---------^        ^-----------^        ^-------^       ^-----^                    ^-------^
  _f_: file          _a_: ag              _i_: Ibuffer    _c_: cache clear           _p_: switch proj
  _F_: file dwim     _g_: update gtags    _b_: switch to  _x_: remove known project  _v_: Magit
  _C-f_: file pwd    _o_: multi-occur   _s-k_: Kill all   _X_: cleanup non-existing
  _r_: recent file   ^ ^                  ^ ^             _z_: cache current
  _d_: dir
"
  ("a"   projectile-ag)
  ("b"   projectile-switch-to-buffer)
  ("c"   projectile-invalidate-cache)
  ("d"   projectile-find-dir)
  ("f"   projectile-find-file)
  ("F"   projectile-find-file-dwim)
  ("C-f" projectile-find-file-in-directory)
  ("g"   ggtags-update-tags)
  ("s-g" ggtags-update-tags)
  ("i"   projectile-ibuffer)
  ("K"   projectile-kill-buffers)
  ("s-k" projectile-kill-buffers)
  ("m"   projectile-multi-occur)
  ("o"   projectile-multi-occur)
  ("p"   projectile-switch-project)
  ("r"   projectile-recentf)
  ("x"   projectile-remove-known-project)
  ("X"   projectile-cleanup-known-projects)
  ("z"   projectile-cache-current-file)
  ("v"   projectile-vc)
  ("q"   nil "cancel" :color blue))

(setq evil-want-integration t) ;; This is optional since it's already set to t by default.
(setq evil-want-keybinding nil)
     (use-package evil
       :init
       (use-package evil-leader
	 :commands (evil-leader-mode global-evil-leader-mode)
	 :demand
	 :config
	 (evil-leader/set-leader "SPC")
	 (global-evil-leader-mode t))
       :config
       (evil-mode 1))
       (global-set-key (kbd "C-i") 'evil-force-normal-state)
  (use-package evil-collection
   :after evil
   :ensure t
   :config
   (evil-collection-init))

     ;(evil-leader/set-key
     ;  "bn" 'next-buffer
     ;  "bp" 'previous-buffer
     ;  ";" 'other-window)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package ivy
  :diminish
  :config
  (ivy-mode 1))

(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history)))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package transpose-frame)
(global-set-key (kbd "C-M-y") 'transpose-frame)

(use-package marginalia
  :ensure t
  :config
  (add-to-list 'marginalia-command-categories '(counsel-projectile-find-file . file))

  (marginalia-mode))

(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
              '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                  nil
                  (window-parameters (mode-line-format . none)))))

(use-package swiper
  :commands (swiper swiper-all)
  :bind ("M-s s" . 'swiper-thing-at-point))

(use-package projectile
  :diminish projectile-mode
  :config
  (add-to-list 'projectile-globally-ignored-directories "*node_modules")
  (add-to-list 'projectile-globally-ignored-directories "*idea")
  (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind (
         ("C-M-p" . counsel-projectile-switch-project)
         ("C-M-S-b" . counsel-projectile-switch-to-buffer)
         ("C-M-S-f" . counsel-projectile-find-file)
         ("C-M-S-v" . projectile-vc)
         )
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init

  ;; we mainly want projects defined by a few markers and we always want to take the top-most marker.
  ;; Reorder so other cases are secondary
  (setq projectile-project-root-files #'( ".projectile" ))
  ;;(setq projectile-project-root-files-functions #'( projectile-root-top-down-recurring ))

  ;; NOTE: Set this to the folder where you keep your Git repos!

  (setq projectile-project-search-path '("~/workspace" "~/workspace/crc1" "~/workspace/crc2"))
  (setq projectile-switch-project-action #'projectile-vc))
;;    (setq projectile-indexing-method 'native)

;;    (setq projectile-require-project-root t))



(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; NOTE: Make sure to configure a GitHub token before using this package!
;; - https://magit.vc/manual/forge/Token-Creation.html#Token-Creation
;; - https://magit.vc/manual/ghub/Getting-Started.html#Getting-Started
(use-package forge)

(defun efs/lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package lsp-mode
  :after projectile
  :commands (lsp lsp-deferred)
  :hook
  (lsp-mode . efs/lsp-mode-setup)
  (php-mode . lsp)
  (web-mode . lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")  ;; Or 'C-l', 's-l'
  :bind (("C-M-G" . lsp-ui-peek-find-definitions))
  :config
  (setq lsp-intelephense-multi-root nil)
  (setq lsp-enable-file-watchers nil)
  (lsp-enable-which-key-integration t)
  (lsp))
(add-hook 'php-mode #'lsp)

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom))

(use-package lsp-treemacs
  :after lsp)

(use-package dap-mode
  :after lsp-mode
  :bind (:map lsp-mode-map
            ("C-c D" . dap-debug)
            ("C-c d" . dap-hydra))
)

(use-package web-mode
  :ensure t
  :mode (("\\.html\\'" . web-mode)
         ("\\.vue\\'" . web-mode)
         ("\\.json\\'" . web-mode)
         ("\\.js\\'" . web-mode)
         ("\\.jsx\\'" . web-mode)
         ("\\.ts\\'" . web-mode)
         ("\\.tsx\\'" . web-mode))
  :commands web-mode
  :hook my-web-mode-hook
  :config
  (setq company-tooltip-align-annotations t)
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-enable-part-face t)
  (setq web-mode-markup-indent-offset 2)
  )
(defun enable-minor-mode (my-pair)
  "Enable minor mode if filename match the regexp.  MY-PAIR is a cons cell (regexp . minor-mode)."
  (if (buffer-file-name)
      (if (string-match (car my-pair) buffer-file-name)
          (funcall (cdr my-pair)))))
(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.jsx?\\'" . prettier-mode))))
(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.ts?\\'" . prettier-mode))))
(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.tsx?\\'" . prettier-mode))))

(use-package nvm)

(use-package prettier)
(add-hook 'web-mode-hook 'prettier-js-mode)

(use-package css-mode
  :mode "\\.css\\'"
  :init
  (setq css-indent-offset 2)
  :hook (css-mode . lsp-deferred))

(setq js-indent-level 2)

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

(use-package php-mode
    :mode "\\.php\\'"
    :hook (php-mode . lsp-deferred)
    :config
    (require 'dap-php)
    (dap-php-setup))

  (add-hook 'php-mode-hook 'php-enable-psr2-coding-style)

;; https://github.com/moskalyovd/emacs-php-doc-blockb
  (add-to-list 'load-path "~/.emacs.d/emacs-php-doc-block")
  (require 'php-doc-block)

;; (use-package phpunit
  ;; :init
  ;; (define-key php-mode-map (kbd "C-t t") 'phpunit-current-test)
  ;; (define-key php-mode-map (kbd "C-t c") 'phpunit-current-class)
  ;; (define-key php-mode-map (kbd "C-t p") 'phpunit-current-project))

(use-package rustic
    :ensure
    :bind (:map rustic-mode-map
                ("M-j" . lsp-ui-imenu)
                ("M-?" . lsp-find-references)
                ("C-c C-c l" . flycheck-list-errors)
                ("C-c C-c a" . lsp-execute-code-action)
                ("C-c C-c r" . lsp-rename)
                ("C-c C-c q" . lsp-workspace-restart)
                ("C-c C-c Q" . lsp-workspace-shutdown)
                ("C-c C-c s" . lsp-rust-analyzer-status))
    :config
    ;; uncomment for less flashiness
    ;; (setq lsp-eldoc-hook nil)
    ;; (setq lsp-enable-symbol-highlighting nil)
    ;; (setq lsp-signature-auto-activate nil)

    ;; comment to disable rustfmt on save
    (setq rustic-format-on-save t)
    (add-hook 'rustic-mode-hook 'rk/rustic-mode-hook))

  (defun rk/rustic-mode-hook ()
    ;; so that run C-c C-c C-r works without having to confirm
    (setq-local buffer-save-without-query t))

(use-package flycheck :ensure)

(use-package company
  :after lsp-mode
  :hook
  (php-mode . lsp-deferred)
  (javascript-mode . lsp-deferred)
  (lsp-mode . company-mode)
  :bind (:map company-active-map
              ("s-<tab>" . company-complete-selection))
        (:map lsp-mode-map
         ("s-<tab>" . company-indent-or-complete-common))
  :custom
  (company-minimum-prefix-length 3)
  (company-idle-delay 0.5))

(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package restclient
  :ensure t
  :mode (("\\.http\\'" . restclient-mode)))

(use-package yasnippet)
(use-package yasnippet-snippets)
(yas-global-mode)

(use-package expand-region)
(use-package sql-indent)
(defun sql-indent-string ()
  "Indents the string under the cursor as SQL."
  (interactive)
  (save-excursion
    (er/mark-inside-quotes)
    (let* ((text (buffer-substring-no-properties (region-beginning) (region-end)))
           (pos (region-beginning))
           (column (progn (goto-char pos) (current-column)))
           (formatted-text (with-temp-buffer
                             (insert text)
                             (delete-trailing-whitespace)
                             (sql-indent-buffer)
                             (replace-string "\n" (concat "\n" (make-string column (string-to-char " "))) nil (point-min) (point-max))
                             (buffer-string))))
      (delete-region (region-beginning) (region-end))
      (goto-char pos)
      (insert formatted-text))))

(defun duplicate-line()
  (interactive)
  (move-beginning-of-line 1)
  (kill-line)
  (yank)
  (open-line 1)
  (next-line 1)
  (yank)
)
(global-set-key (kbd "C-d") 'duplicate-line)

(global-set-key (kbd "s-]") 'forward-word)
(global-set-key (kbd "s-[") 'backward-word)
(global-set-key (kbd "s-o") (lambda() (interactive)(other-window 1)))

(delete-selection-mode 1)

(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2)
  (indent-according-to-mode))
(global-set-key (kbd "M-[") 'move-line-up)

(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1)
  (indent-according-to-mode))
(global-set-key (kbd "M-]") 'move-line-down)

(use-package multiple-cursors)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)

(defun te/beginning-of-line-whitespace ()
  "Move to beggingin of line skipping white space"
  (interactive)
  (beginning-of-visual-line 1)
  (forward-whitespace 1))
(global-set-key (kbd "C-q") 'te/beginning-of-line-whitespace)

(use-package yafolding
  :config
  (yafolding-mode)
  :bind 
  ("C-=" . yafolding-toggle-element)
  ("C--" . yafolding-toggle-all))

;; NOTE: The first time you load your configuration on a new machine, you'll
;; need to run the following command interactively so that mode line icons
;; display correctl:
;;
;; M-x all-the-icons-install-fonts
(use-package all-the-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(use-package doom-themes
  :init (load-theme 'doom-city-lights t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(defun efs/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
      (set-face-attribute (car face) nil :font te-font-face :weight 'regular :height (cdr face)))

;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

(use-package org
  :hook (org-mode . efs/org-mode-setup)
  :config
  (setq org-ellipsis " ▾")
  (efs/org-font-setup))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(defun efs/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . efs/org-mode-visual-fill))



(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("sql" . "src sql"))

(org-babel-do-load-languages
  'org-babel-load-languages
  '((emacs-lisp . t)
    (python . t)))

;; Automatically tangle our Emacs.org config file when we save it
(defun efs/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "~/workspace/dotfiles/emacs.org"))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))


(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'efs/org-babel-tangle-config)))

;; C-x <direction> to switch windows
;;(use-package window-jump
;;             :bind (("C-x <up>" . window-jump-up)
;;                    ("C-x <down>" . window-jump-down)
;;                    ("C-x <left>" . window-jump-left)
;;                    ("C-x <right>" . window-jump-right)))
(defun window-split-toggle ()
  "Toggle between horizontal and vertical split with two windows."
  (interactive)
  (if (> (length (window-list)) 2)
      (error "Can't toggle with more than 2 windows!")
    (Let ((func (if (window-full-height-p)
                    #'split-window-vertically
                  #'split-window-horizontally)))
      (delete-other-windows)
      (funcall func)
      (save-selected-window
        (other-window 1)
        (switch-to-buffer (other-buffer))))))

(use-package exec-path-from-shell
  :init (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

(defun eshell-new()
  "Open a new instance of eshell."
  (interactive)
  (eshell 'N))

(use-package engine-mode
  :ensure t

  :config
  (engine-mode t))

(defengine duckduckgo
  "https://duckduckgo.com/?q=%s"
  :keybinding "d"
  :browser 'eww-browse-url)

(use-package elfeed
:bind
    ("C-x w" . elfeed)
)
(setq elfeed-feeds
    '(("http://nullprogram.com/feed/" blog emacs)
    "https://planet.emacslife.com/atom.xml"
    ("https://sachachua.com/blog/feed/" blog emacs)
    "https://www.thecrazyprogrammer.com/feed"
    ("https://www.sitepoint.com/sitepoint.rss" web)
    "https://blog.jooq.org/feed/"
    "https://medium.com/feed/@daveford"
    "https://blog.codepen.io/feed/"
    "https://davidwalsh.name/feed"
    "https://www.raywenderlich.com/feed"
    ("https://css-tricks.com/feed/" web)
    "https://tympanus.net/codrops/feed/"
    "https://medium.com/feed/better-programming"
    "https://stackoverflow.blog/feed/"
    "https://codesignal.com/feed/"
    "https://alistapart.com/main/feed/"
    "https://www.codingdojo.com/blog/feed"
    "https://fueled.com/feed/"
    "https://www.johndcook.com/blog/feed/"
    "https://webdamn.com/feed/"
    "https://www.codevscolor.com/rss.xml"
    ("https://togglebit.io/atom.xml" streamer rust)
    ("https://fasterthanli.me/index.xml" rust)
    "https://domenicoluciani.com/feed.xml"
    "https://lucumr.pocoo.org/feed.atom"
    "https://hoverbear.org/rss.xml"
    "https://www.lpalmieri.com/rss.xml"
    "https://www.rfleury.com/feed"
))
