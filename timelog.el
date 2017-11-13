;;; load org
(setq load-path (cons "~/unix/src/org-mode/lisp" load-path))
(require 'org-install)
(require 'org)

(defvar vr/timelog-data-path "~/org/habits/timelog"
  "Path to timelog data")

(defvar vr/timelog-src-path "~/unix/src/timelog"
  "Path to timelog source code")

;;; timelog file
(defvar vr/timelog-file (concat vr/timelog-data-path "/timelog.org")
  "Path to timelog file")

;;; use helper packages
(require 'package)
(package-initialize)

;;; agenda view
(setq org-agenda-files (cons vr/timelog-file ()))
(setq org-agenda-custom-commands
      '((" " "Default agenda"
         ((agenda ""
                  ((org-agenda-span 'day)
                   (org-agenda-skip-archived-trees nil)
                   (org-agenda-sorting-strategy '(time-up))))
          (tags "Daily"
                ((org-agenda-overriding-header "Täglich:")))
	  (tags "Recurring"
		((org-agenda-overriding-header "Erledigungen:")))
	  (tags "+Projekt-ARCHIVE"
		((org-agenda-overriding-header "Projekt:")))
	  (tags "+Freizeit-ARCHIVE"
		((org-agenda-overriding-header "Freizeit:")))
	  (tags "+Prokrastination-ARCHIVE"
		((org-agenda-overriding-header "Prokrastination:")))))))

;;; show agenda
(defun vr/show-agenda ()
  (interactive)
  (org-agenda nil " ")
  (org-agenda-log-mode 'clockcheck))

;;; switch to agenda
(global-set-key (kbd "<f12>") 'vr/show-agenda)

;;; start agenda on startup
(setq inhibit-startup-message t)
(add-hook 'emacs-startup-hook 'vr/show-agenda)

;;; smaller font
(set-face-attribute 'default nil :height 100)

;;; hide toolbar
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))

;;; hide menu bar
(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))

;;; only show current time in mode line
(setq-default mode-line-format '("" mode-line-misc-info))
(setq org-clock-mode-line-total 'current)

;;; formatting of agenda entries
(setq org-agenda-prefix-format '((agenda . "  %?-12t% s") (tags . "- ")))

;;; don't display horizontal lines
(setq org-agenda-block-separator "")
(setq org-agenda-compact-blocks nil)

;;; no separators in the agenda time grid
(setq org-agenda-time-grid '((daily today required-time)))

;;; hide tags in agenda
(setq org-agenda-hide-tags-regexp "")

;;; use entire frame for agenda
(setq org-agenda-window-setup 'current-window)

;;; archive tasks
(add-hook 'org-agenda-mode-hook '(lambda ()
                                   (define-key org-agenda-keymap "$" '(lambda ()
                                                                        (interactive)
                                                                        (org-agenda-toggle-archive-tag)
                                                                        (org-agenda-redo t)))))

;;; store clocking information
(setq org-clock-persist-file (concat vr/timelog-data-path "/clock-save.el"))
(setq org-clock-persist t)
(org-clock-persistence-insinuate)

;;; show 1 minute clocking gaps
(setq org-agenda-clock-consistency-checks
      '(:max-duration "9:00"
                      :min-duration 0
                      :max-gap 0
                      :gap-ok-around nil))

;;; edit clock by one minute
(setq org-time-stamp-rounding-minutes '(1 1))

;;; capture new tasks
(setq org-capture-templates
      '(("p" "Projekt"  entry (file vr/timelog-file) "* %^{Projekt}    :Projekt:" :clock-in t :clock-keep t :immediate-finish t)
	("f" "Freizeit" entry (file vr/timelog-file) "* %^{Freizeit}  :Freizeit:" :clock-in t :clock-keep t :immediate-finish t)))

(defun vr/capture (key)
  (org-capture nil key)
  (org-agenda-redo t))

(global-set-key (kbd "<f11>") (lambda () (interactive) (vr/capture "p")))
(global-set-key (kbd "<f10>") (lambda () (interactive) (vr/capture "f")))

;;; auto-save after clocking in
(add-hook 'org-clock-in-hook 'org-save-all-org-buffers)

;;; change clock entries from agenda
(require 'org-clock-convenience)
(setq org-clock-convenience-clocked-agenda-re
  " +\\(\\([ 012][0-9]\\):\\([0-5][0-9]\\)\\)\\(?:-\\(\\([ 012][0-9]\\):\\([0-5][0-9]\\)\\)\\|\.*\\)? +Clocked: +\\(([0-9]+:[0-5][0-9])\\|(-)\\)")
(setq org-clock-convenience-clocked-agenda-fields
  '(d1-time d1-hours d1-minutes d2-time d2-hours d2-minutes duration))
(add-hook 'org-agenda-mode-hook '(lambda ()
				   (define-key org-agenda-mode-map (kbd "<S-up>") 'org-clock-convenience-timestamp-up)
				   (define-key org-agenda-mode-map (kbd "<S-down>") 'org-clock-convenience-timestamp-down)
				   (define-key org-agenda-mode-map (kbd "F") 'org-clock-convenience-fill-gap)
				   (define-key org-agenda-mode-map (kbd "B") 'org-clock-convenience-fill-gap-both)))
;;; escape sequences to add S-up, S-down in terminal
;;; S-up \033[1;2A
;;; S-down \033[1;2B

;;; plot figures on save
(defvar vr/timelog-conversion-script (concat vr/timelog-src-path "/convert_timelog.py"))
(defvar vr/timelog-plotting-script (concat vr/timelog-src-path "/timelog.r"))
(defvar vr/timelog-detail-plot (concat vr/timelog-data-path "/timelog-detail.pdf"))

(defun vr/plot-timeline ()
  (interactive)
  (let ((tmp-file (make-temp-file "clock")))
    (shell-command (format "python %s %s %s"
			   (expand-file-name
			    vr/timelog-conversion-script)
			   vr/timelog-file tmp-file))
    (start-process "plot-timelog" "*plotting output*" "r"
		   (format "--vanilla -f %s --args %s %s"
			   (expand-file-name vr/timelog-plotting-script)
			   tmp-file
			   (expand-file-name vr/timelog-detail-plot)))
    (message "Started timelog plotting")))
(add-hook 'after-save-hook #'vr/plot-timeline)

;;; view plots
(add-hook 'org-agenda-mode-hook
	  '(lambda ()
	     (define-key org-agenda-mode-map (kbd "V")
	       '(lambda () (interactive) (shell-command (format "open %s" vr/timelog-detail-plot))))))
