(defpackage :tecgraf-libs
  (:use :cl))

(in-package :tecgraf-libs)

(defvar +cd-version+ "5.13")
(defvar +im-version+ "3.14")
(defvar +iup-version+ "3.29")

(defvar +win-version+ "16")
(defvar +linux-version+ "54")

(defun replace-char (o n s)
  (let ((place (search o s :test #'string=)))
    (if place
	(replace-char o n
		      (uiop:strcat (subseq s 0 place)
				   n
				   (subseq s (1+ place))))
	s)))

(defun windows-path (stream path &optional colonp atp)
  (declare (ignore colonp atp))
  (write-string (replace-char "/" "\\" (namestring path)) stream))

(let ((lib-dir (asdf:system-relative-pathname :tecgraf-libs #P"libs/")))
  (unless (and (uiop:directory-exists-p lib-dir)
	       (uiop:directory-files lib-dir))
    (ensure-directories-exist lib-dir)
    (flet ((generate-link (for)
	     (let ((system-name (case for
				  (:cd "canvasdraw")
				  (:im "imtoolkit")
				  (:iup "iup")))
		   (system-version (case for
				     (:cd +cd-version+)
				     (:im +im-version+)
				     (:iup +iup-version+))))
	       (format nil "http://sourceforge.net/projects/~a/files/~a/~a%20Libraries/Dynamic/~a-~a_~a_lib.~a/download"
		       system-name
		       system-version
		       
		       #+(or win32 windows) "Windows"
		       #+linux "Linux"
		       
		       (string-downcase (string for))
		       system-version
		       
		       #+(or win32 windows) (uiop:strcat "Win64_dll" +win-version+)
		       #+linux (uiop:strcat "Linux" +linux-version+ "_64")
		       
		       #+(or win32 windows) "zip"
		       #+linux "tar.gz"))))
      (dolist (system '(:cd :im :iup))
	(let ((outpath (merge-pathnames (uiop:strcat (string system) ".zip")
					lib-dir)))
	  (ql-http:fetch (generate-link system) outpath)
	  (uiop:run-program (format nil
				    #+(or win32 windows)
				    "powershell -command \"Expand-Archive -Force '~/tecgraf-libs::windows-path/' '~/tecgraf-libs::windows-path/'\""
				    
				    #-(or win32 windows)
				    "tar -xzf ~a -C ~a --wildcards \\*.so --transform='s/.*///'"
				    outpath lib-dir))
	  #+(or windows win32)
	  (progn
	    (mapcar #'delete-file (uiop:directory-files lib-dir "*.lib"))
	    (dolist (dir (uiop:subdirectories lib-dir))
	      (uiop:delete-directory-tree dir :validate t)))))
      (mapcar #'delete-file (uiop:directory-files lib-dir "*.zip"))))

  #+(or win32 windows)
  (setf (uiop:getenv "PATH")
	(uiop:strcat (uiop:getenv "PATH") ":" (namestring lib-dir)))

  #-(or win32 windows)
  (setf (uiop:getenv "LD_LIBRARY_PATH")
	(uiop:strcat (uiop:getenv "LD_LIBRARY_PATH") ":" (namestring lib-dir))))
