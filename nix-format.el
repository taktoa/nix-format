;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(load-file "@NIX_MODE_PATH@/nix-mode.el")

(setq input-file (pop argv))
(setq output-file (pop argv))

(with-temp-file output-file
  (setq-default indent-tabs-mode nil)
  (electric-indent-mode +1)
  (nix-mode)
  (insert-file-contents input-file)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))

(kill-emacs 0)
