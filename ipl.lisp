;;;; Copyright (c) 2011-2016 Henry Harrington <henry.harrington@gmail.com>
;;;; This code is licensed under the MIT license.

(in-package :cl-user)

(defun sys.int::setup-for-release ()
  (load "tools/load-sources.lisp")
  (setf (sys.int::symbol-global-value '*package*) (find-package :cl-user))
  (setf *default-pathname-defaults* (pathname "LOCAL:>")
        mezzano.file-system::*home-directory* *default-pathname-defaults*)
  (setf (mezzano.file-system:find-host :remote) nil)
  (when (y-or-n-p "Snapshot?")
    (sys.int::snapshot-and-exit)))

;; Fast eval mode.
(setf sys.int::*eval-hook* 'mezzano.fast-eval:eval-in-lexenv)

;; Host where the initial system is kept.
;; Change the IP to the host computer's local IP.
(mezzano.file-system.remote:add-simple-file-host :remote sys.int::*file-server-host-ip*)
;; Use PATHNAME instead of #p because the cross-compiler doesn't support #p.
;; Point *DEFAULT-PATHNAME-DEFAULTS* at the full path to the source tree.
(setf *default-pathname-defaults* (pathname (concatenate 'string "REMOTE:" sys.int::*mezzano-source-path*)))
;; Point MEZZANO.FILE-SYSTEM::*HOME-DIRECTORY* at the home directory containing the libraries.
(setf mezzano.file-system::*home-directory* (pathname (concatenate 'string "REMOTE:" sys.int::*home-directory-path*)))

;; Local FS. Loaded from the source tree, not the home directory.
(sys.int::cal "file/local.lisp")
(eval (read-from-string "(mezzano.file-system.local:add-local-file-host :local)"))

;; Fonts. Loaded from the home directory.
(ensure-directories-exist "LOCAL:>Fonts>")
(dolist (f (directory (merge-pathnames "Fonts/**/*.ttf" (user-homedir-pathname))))
  (sys.int::copy-file f
             (merge-pathnames "LOCAL:>Fonts>" f)
             '(unsigned-byte 8)))
(sys.int::copy-file (merge-pathnames "Fonts/LICENSE" (user-homedir-pathname))
                    "LOCAL:>Fonts>LICENSE"
                    'character)

;; Icons. Loaded from the source tree.
(ensure-directories-exist "LOCAL:>Icons>")
(dolist (f (directory "gui/*.png"))
  (sys.int::copy-file f
                      (merge-pathnames "LOCAL:>Icons>" f)
                      '(unsigned-byte 8)))

;; Other stuff.
;; The desktop image, this can be removed or replaced.
;; If it is removed, then the line below that starts the desktop must be updated.
(sys.int::copy-file (merge-pathnames "Hypothymis_azurea_-_Kaeng_Krachan.jpg" (user-homedir-pathname))
                    "LOCAL:>Desktop.jpeg"
                    '(unsigned-byte 8))

;; ASDF.
(sys.int::cal (merge-pathnames "asdf/asdf.lisp" (user-homedir-pathname)))
(defun home-source-registry ()
  `(:source-registry
    (:tree ,(user-homedir-pathname))
    :inherit-configuration))
(eval (read-from-string "(push 'home-source-registry asdf:*default-source-registries*)"))

;; A bunch of GUI related systems.
(require :zpb-ttf)
(require :cl-vectors)
(require :cl-paths-ttf)
;; TCE is required for Chipz's decompressor.
(let ((sys.c::*perform-tce* t)
      ;; Prevent extremely excessive inlining.
      (sys.c::*constprop-lambda-copy-limit* -1))
  (require :chipz))
(require :png-read)
(require :cl-jpeg)
(require :swank)

;; And the GUI.
(sys.int::cal "gui/font.lisp")
(sys.int::cal "gui/widgets.lisp")
(sys.int::cal "line-edit-mixin.lisp")
(sys.int::cal "gui/popup-io-stream.lisp")
(sys.int::cal "gui/xterm.lisp")
(sys.int::cal "applications/telnet.lisp")
(sys.int::cal "applications/mandelbrot.lisp")
(sys.int::cal "applications/irc.lisp")
(require :med)
(sys.int::cal "applications/peek.lisp")
(sys.int::cal "applications/fancy-repl.lisp")
(sys.int::cal "gui/desktop.lisp")
(sys.int::cal "gui/image-viewer.lisp")
(sys.int::cal "applications/filer.lisp")
(sys.int::cal "applications/memory-monitor.lisp")
(sys.int::cal "file/http.lisp")
;; If the desktop image was removed above, then remove the :IMAGE argument
;; from here.
(setf sys.int::*desktop* (eval (read-from-string "(mezzano.gui.desktop:spawn :image \"LOCAL:>Desktop.jpeg\")")))

;; Done.
