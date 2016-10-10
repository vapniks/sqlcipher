;;; sqlcipher.el --- support for sqlcipher in sql-interactive-mode

;; Filename: sqlcipher.el
;; Description: support for sqlcipher in sql-interactive-mode
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2016, Joe Bloggs, all rites reversed.
;; Created: 2016-10-10 02:38:48
;; Version: 20161010.300
;; Last-Updated: Mon Oct 10 03:00:03 2016
;;           By: Joe Bloggs
;;     Update #: 1
;; URL: https://github.com/vapniks/sqlcipher
;; Keywords: data
;; Compatibility: GNU Emacs 24.5.1
;; Package-Requires:  
;;
;; Features that might be required by this library:
;;
;; sql
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Commentary: 

;; This file provides a backend for connecting to encrypted sqlite databases
;; with emacs `sql-connect' using sqlcipher.
;; You can store connection information in `sql-connection-alist'. The path
;; to the database file should be stored in `sql-database', and you can either
;; store the encryption key as plain text in `sql-password' or in one of your
;; `auth-sources' files. In the latter case you can store the host and port
;; entries in `sql-server' and `sql-user' respectively in the `sql-connection-alist' entry.
;; 

;;;;;;;;

;;; Commands:
;;
;; Below is a complete list of commands:
;;
;;  `sql-sqlcipher'
;;    Run sqlcipher as an inferior process.
;;    Keybinding: M-x sql-sqlcipher
;;
;;; Customizable Options:
;;
;; Below is a list of customizable options:
;;
;;  `sql-sqlcipher-program'
;;    Location of sqlcipher binary.
;;    default = (or (executable-find "sqlcipher") "sqlcipher")
;;  `sql-sqlcipher-options'
;;    List of additional options for `sql-sqlcipher-program'.
;;    default = nil

;;
;; All of the above can be customized by:
;;      M-x customize-group RET sqlcipher RET
;;

;;; Installation:
;;
;; Put sqlcipher.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'sqlcipher)

;;; History:

;;; Require
(require 'sql)

;;; Code:

;; REMEMBER TODO ;;;###autoload's 
(defcustom sql-sqlcipher-program (or (executable-find "sqlcipher")
				     "sqlcipher")
  "Location of sqlcipher binary."
  :type 'file
  :group 'SQL)

(defcustom sql-sqlcipher-options nil
  "List of additional options for `sql-sqlcipher-program'."
  :type '(repeat string)
  :group 'SQL)

(sql-add-product 'sqlcipher "SQLcipher"
		 :free-software t
		 :font-lock 'sql-mode-sqlite-font-lock-keywords
		 :sqli-program 'sql-sqlcipher-program
		 :sqli-login 'sql-sqlite-login-params
		 :sqli-comint-func 'sql-comint-sqlcipher
		 :sqli-options 'sql-sqlcipher-options		 
		 :list-all ".tables"
		 :list-table ".schema %s"
		 :completion-object 'sql-sqlite-completion-object
		 :prompt-regexp "^sqlite> "
		 :prompt-length 8
		 :prompt-cont-regexp "^   \.\.\.> "
		 :terminator ";"
		 :sql-server "sqlcipher"
		 :sql-user nil
		 :sql-password nil)

;;;###autoload
(defun sql-comint-sqlcipher (product options)
  "Create comint buffer and connect to sqlcipher.
Will attempt to get key/password from `sql-password', and if that is not available
then it will use `sql-server' and `sql-user' as the host and port values for obtaining
the password from `auth-sources'."
  ;; Put all parameters to the program (if defined) in a list and call
  ;; make-comint.
  (let* ((params
	  (append options
		  (list "-cmd"
			(concat "pragma key = '"
				(if (equal sql-password "")
				    (funcall (plist-get
					      (car (auth-source-search
						    :host sql-server
						    :port sql-user))
					      :secret))
				  sql-password) "'"))
		  (if (not (string= "" sql-database))
		      `(,(expand-file-name sql-database))))))
    (sql-comint product params)))

;;;###autoload
(defun sql-sqlcipher (&optional buffer)
  "Run sqlcipher as an inferior process.

SQLite is free software.

If buffer `*SQL*' exists but no process is running, make a new process.
If buffer exists and a process is running, just switch to buffer
`*SQL*'.

Interpreter used comes from variable `sql-sqlcipher-program'.  
The value of `sql-password' is used as the key for decrypting the database,
or if that is empty then the key is obtained from `auth-sources' using
`sql-server' and `sql-user' to lookup the host and username.
Additional command line parameters can be stored in the 
list `sql-sqlcipher-options'. 

The buffer is put in SQL interactive mode, giving commands for sending
input.  See `sql-interactive-mode'.

To set the buffer name directly, use \\[universal-argument]
before \\[sql-sqlcipher].  Once session has started,
\\[sql-rename-buffer] can be called separately to rename the
buffer.

To specify a coding system for converting non-ASCII characters
in the input and output to the process, use \\[universal-coding-system-argument]
before \\[sql-sqlcipher].  You can also specify this with \\[set-buffer-process-coding-system]
in the SQL buffer, after you start the process.
The default comes from `process-coding-system-alist' and
`default-process-coding-system'.

\(Type \\[describe-mode] in the SQL buffer for a list of commands.)"
  (interactive "P")
  (sql-product-interactive 'sqlcipher buffer))

(provide 'sqlcipher)

;; (org-readme-sync)
;; (magit-push)

;;; sqlcipher.el ends here
