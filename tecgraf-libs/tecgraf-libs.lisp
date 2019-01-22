(in-package #:tecgraf-libs)

(defvar *libs-pathname*
  (asdf:system-relative-pathname
   (asdf:find-system "tecgraf-libs")
   (make-pathname :directory '(:relative "libs"))))

(defvar *shared-library-type* #+windows ".dll" #+linux ".so")

(defvar *archives*
  #+(and linux x86-64)
  '()
  #+(and windows x86-64)
  '(("https://sourceforge.net/projects/iup/files/3.26/Windows%20Libraries/Dynamic/iup-3.26_Win64_dll15_lib.zip"
     "179fc01047c6ee5f86fd010e71613c991fe82c4ad5d929b4017d1ee6fe6662b7")
    ("https://sourceforge.net/projects/canvasdraw/files/5.12/Windows%20Libraries/Dynamic/cd-5.12_Win64_dll15_lib.zip"
     "8b5c791c0d01468a20369b56002c1dda8fb34b2e5d9a5332c479cb34b24b4674")
    ("https://sourceforge.net/projects/imtoolkit/files/3.13/Windows%20Libraries/Dynamic/im-3.13_Win64_dll15_lib.zip"
     "82e6b12e96d2d278e0f94bef0ec335500af97aac044254b8d6a5bcc73847fe43")))

(defun download-tecgraf-libs ()
  (loop for (archive-url hash) in *archives*
	for archive-pathname = (pathname-from-url archive-url)
	for output-pathname
	  = (asdf:system-relative-pathname :tecgraf-libs archive-pathname)
	do (format t "~&Downloading ~A..." archive-url)
	do (download-to-pathname archive-url output-pathname)
	collect (list output-pathname hash)))

(defun verify (downloads)
  (loop for (pathname expected-hash) in downloads
	for download-hash
	  = (ironclad:byte-array-to-hex-string
	     (ironclad:digest-file 'ironclad:sha256 pathname))
	for match = (string= download-hash expected-hash)
	do (unless match
	     (cerror "Skip verification of file checksum"
		     "Checksum for ~A does not match (got ~A, expected ~A)"
		     pathname download-hash expected-hash))
	collect pathname))

#+windows
(defun unpack (archive-pathnames)
  (let ((unpacked '()))
    (dolist (archive archive-pathnames unpacked)
      (zip:with-zipfile (file archive)
	(zip:do-zipfile-entries (name entry file)
	  (when (alexandria:ends-with-subseq *shared-library-type* name)
	    (let* ((entry-pathname (parse-namestring name))
		   (out-pathname (merge-pathnames 
				  (make-pathname :name (pathname-name entry-pathname)
						 :type (pathname-type entry-pathname ))
				  *libs-pathname*)))
	      (push out-pathname unpacked)
	      (alexandria:write-byte-vector-into-file
	       (zip:zipfile-entry-contents entry)
	       out-pathname
	       :if-exists :supersede))))))))

#+linux
(defun unpack (archive-pathnames) (error "Not implemented"))

(defun download ()
  (let* ((downloaded (download-tecgraf-libs))
	 (verified (verify downloaded))
	 (unpacked (unpack verified)))
    (format t "~%Unpacked to ~S" *libs-pathname*)))
