;;; kubernetes-contexts.el --- Rendering for Kubernetes contexts  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'dash)

(require 'kubernetes-kubectl)
(require 'kubernetes-modes)
(require 'kubernetes-process)
(require 'kubernetes-state)
(require 'kubernetes-utils)
(require 'kubernetes-vars)
(require 'kubernetes-yaml)


;; Component

(defun kubernetes-contexts--render-current-context (context current-namespace)
  (-let* (((&alist 'name name
                   'context (&alist 'cluster cluster-name
                                    'namespace context-namespace))
           context)
          (context-name (propertize name 'face 'kubernetes-context-name))
          (namespace-in-use (or current-namespace context-namespace)))
    `(nav-prop :display-config
               (heading (key-value 12 "Context" ,context-name))
               (key-value 12 "Cluster" ,cluster-name)
               (key-value 12 "Namespace" ,namespace-in-use))))

(defun kubernetes-contexts--render-namespace-only (current-namespace)
  (let ((none (propertize "<none>" 'face 'magit-dimmed)))
    `(nav-prop :display-config
               (heading (key-value 12 "Context" ,none))
               (key-value 12 "Namespace" ,current-namespace))))

(defun kubernetes-contexts--render-fetching ()
  (let ((fetching (propertize "Fetching..." 'face 'kubernetes-progress-indicator)))
    `(heading (key-value 12 "Context" ,fetching))))

(defun kubernetes-contexts-render (state)
  (let ((current-namespace (kubernetes-state-current-namespace state))
        (current-context (kubernetes-state-current-context state)))

    `(section (context-container nil)
              (section (context nil)
                       ,(cond
                         (current-context
                          (kubernetes-contexts--render-current-context current-context current-namespace))
                         (current-namespace
                          (kubernetes-contexts--render-namespace-only current-namespace))
                         (t
                          (kubernetes-contexts--render-fetching)))

                       (padding)))))


;; Requests and state management

(defun kubernetes-contexts-refresh (&optional interactive)
  (unless (kubernetes-process-poll-config-process-live-p)
    (kubernetes-process-set-poll-config-process
     (kubernetes-kubectl-config-view kubernetes-default-props
                                     (kubernetes-state)
                                     (lambda (response)
                                       (kubernetes-state-update-config response)
                                       (when interactive
                                         (message "Updated config.")))
                                     (lambda ()
                                       (kubernetes-process-release-poll-config-process))))))


;; Displaying config.

;;;###autoload
(defun kubernetes-display-config (config)
  "Display information for CONFIG in a new window."
  (interactive (list (kubernetes-kubectl-await-on-async kubernetes-default-props (kubernetes-state) #'kubernetes-kubectl-config-view)))
  (select-window
   (display-buffer
    (kubernetes-yaml-make-buffer kubernetes-display-config-buffer-name config))))


(provide 'kubernetes-contexts)

;;; kubernetes-contexts.el ends here