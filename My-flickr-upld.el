;; -- emacs --
;; version 0.2 
;; xml.el is abandoned as it is extremly slow; copletion lists are
;; generated now by Perl directly as Lisp structures (much faster);
;; 
;; add the following to .emacs:
;; (autoload 'My-flickr-images-init "My-flickr-images" 
;;  "Tryb do edytowania opisów zdjêæ" t )
;; (autoload 'My-flickr-images-edit "My-flickr-images" 
;;  "Tryb do edytowania opisów zdjêæ" t )
;;
(require 'image-file)
;; pobierz nazwy miejsc/zbiorów/tagi (generowane Perlem):

(add-to-list 'load-path "~/.flickr")

(load "hr.icio.el")

(setq My-flickr-image-tmp "** image **")
;;(setq My-flickr-fileout "/tmp/my-show-tmp-image.jpg")
(setq My-flickr-list-dir "flickr-list.dir")
(setq perl-prog-name "/usr/local/lib/perl5/site_perl/flickr_upld.pl --script")

(defun My-flickr-images-init (dir)
  "Utwórz nowy listing zdjêæ"
  (interactive "fdir: ")

  (setq flickr-images-dir dir)  ;;

  (let ( ( f (directory-files dir nil ".*\\.jpg")))
    (progn 
      ;; (switch-to-buffer (get-buffer-create My-flickr-list-dir ))
      (switch-to-buffer (find-file-noselect My-flickr-list-dir nil nil nil))  
      (erase-buffer)
      (insert "# Opisy do zdjêæ na flickr.com **\n")
      (insert "# Po NAZWA-ZDJECIA >> wstaw: @g nazwa @k taglist @s set @p pool @t tytu³ @lrot @rrot\n")
      (insert "#\n")
      (while f
	(insert (concat (car f) " >> @g  @k \n"))
	(setq f (cdr f)))
      (cd dir) ; change default directory
      ;; (save-buffer)
      (write-file My-flickr-list-dir)
      ;; go to the first line and show the image:
      ;; (insert default-directory)
      ;; (insert "\n")
      (goto-char (point-min))
      (search-forward-regexp "#$")
      (search-forward "@g ") ;; position the coursor
      ;;(end-of-line) ;;
      (My-flickr-show-image)
      ;; switch to flickr mode:
      (My-flickr-images-mode) ;; set mode in that buffer
      ;; default-directory
      ) )
  )

(defun My-flickr-images-edit (dir)
  "Edytuj istniej±cy listing zdjêæ"
  (interactive "fdir: ")

  (setq flickr-images-dir dir) ;;

  (switch-to-buffer (find-file-noselect 
		     (concat dir My-flickr-list-dir)))
  (goto-char (point-min))
  (end-of-line) ;;
  (My-flickr-show-image)
  ;; switch to flickr mode:
  (My-flickr-images-mode) 
)

(defun My-flickr-copy-previous-line ()
  "Skopiuj zawarto¶æ poprzedniego wiersza po sekwencji '>>'. Cokolwiek
by³o po sekwencji '>>' w bie¿±cym wierszu jest kasowane."
  (interactive)
  (save-excursion
  (if (< (My-flickr-which-line) 2)
    (message "** nothing to copy **")
    (progn
      (previous-line 1)
      (beginning-of-line)
      (re-search-forward ">>\\(.*\\)" nil t nil)
      (let ((text (match-string 1)))
	(next-line 1)
	(beginning-of-line)
	(re-search-forward ">>\\(.*\\)" nil t)
	(replace-match (concat ">>" text) nil nil))
	(message "OK"))
    )))

(defun My-flickr-show-image (&optional rot)
  "Poka¿ zawarto¶æ pliku w wierszu, w którym jest kursor."
  (interactive)
  (save-excursion
  (beginning-of-line)
  (progn
    (re-search-forward "^\\([a-zA-Z0-9._\\-]+\\)\\(.*$\\)" nil t nil)
    (My-flickr-show-image-with-type 
     (file-name-nondirectory (match-string 1)) 
     'jpeg 
     rot
     (match-string 2)
     )
    )))

(defun My-flickr-show-image-rotated-right ()
  "Insert the image file FILE into the current buffer rotated right."
  (interactive)
  (My-flickr-show-image 270) )

(defun My-flickr-show-image-rotated-left ()
  "Insert the image file FILE into the current buffer rotated left."
  (interactive)
  (My-flickr-show-image 90) )

(defun My-flickr-down ()
  "Wykonaj polecenie 'next-line', wy¶wietl rysunek z tego wiersza."
  (interactive)
  (next-line 1)
  (My-flickr-show-image))

(defun My-flickr-up ()
  "Wykonaj polecenie 'previous-line', wy¶wietl rysunek z tego wiersza."
  (interactive)
  (if (> (My-flickr-which-line) 1)
   (progn   
     (previous-line 1)
     ;(end-of-line)
     (My-flickr-show-image))))

(defun My-flickr-which-line()
  "Return line number"
  ;;(interactive)
  ;;(message (count-lines (point-min) (point)))
  (1+ (count-lines 1 (point))))
  ;;(count-lines (point-min) (point)))

(defun My-flickr-remove-all-thumbnails
  ;; usuniêcie miniaturek ;;
  (shell-command "rm /tmp/*.thmb")
)

(defun My-flickr-show-image-with-type (file &optional type rotation line-args )
  "Insert the image file FILE into the current buffer.
Optional arguments type overrides inferred type."

  ;; nazwa miniaturki ;;
  (if (null rotation)  (setq rotation 0))
  ;;rot-string ;;  (format "-%d"  (concat "-0")

  (setq My-flickr-fileout 
     (concat "/tmp/" (file-name-nondirectory file) 
	 (format "-%d" rotation) ".thmb" ))

  (set-buffer (get-buffer-create My-flickr-image-tmp ))
  (cd flickr-images-dir) ;;

  (if (not (one-window-p t))
      (delete-other-windows))

  (set-window-buffer (split-window-vertically -15) 
		     My-flickr-image-tmp )
  (setq buffer-read-only nil)
  (erase-buffer)
  (goto-char (point-min))
  ;;

  (if (file-readable-p My-flickr-fileout)
      (message (concat "** Redisplaying: " My-flickr-fileout ":" line-args ))
  (progn
    (message (concat "** Generating: " My-flickr-fileout ))
    (let ((command (format "%s -size 250x250 \"%s\" -resize 250x250 %s +profile \"*\" \"%s\""
			   (executable-find "convert")
			   (expand-file-name file)
			   (if (> rotation 0) (format "-rotate %d" rotation) (concat "") )
			   My-flickr-fileout))) ;; -- tu l±duje output --
   (shell-command command)))
      ;;(message command))
  )
  
  ;;
  (let ((rval
	 (image-file-call-underlying #'insert-file-contents-literally
				     'insert-file-contents My-flickr-fileout)))
    ;; Turn the image data into a real image, but only if the whole file
    ;; was inserted
    (let* ((ibeg (point))
	   (iend (+ (point) (cadr rval)))
	   (visitingp nil)
	   (data
	    (string-make-unibyte
	     (buffer-substring-no-properties ibeg iend)))
	   (image
	    (create-image data type t))
	   (props
	    `(display ,image
		      intangible ,image
		      rear-nonsticky (display intangible)
		      ;; This a cheap attempt to make the whole buffer
		      ;; read-only when we're visiting the file (as
		      ;; opposed to just inserting it).
		      ,@(and visitingp
			     '(read-only t front-sticky (read-only))))))
      (add-text-properties ibeg iend props)
      (when visitingp
	;; Inhibit the cursor when the buffer contains only an image,
	;; because cursors look very strange on top of images.
	(setq cursor-type nil)
	;; This just makes the arrow displayed in the right fringe
	;; area look correct when the image is wider than the window.
	(setq truncate-lines t)))
    rval))

(defun My-flickr-insert-geo (geo)
  "Wstawia GEO z bazy z dope³nieniem nazwy"
  (interactive (list (completing-read
		      "Podaj GEO: "
		      glist
		      nil t nil 'geo)))
  (insert geo)
)

(defun My-flickr-insert-tag (tag)
  "Wstawia TAG z bazy z dope³nieniem nazwy"
  (interactive (list (completing-read
		      "Podaj TAG: "
		      tlist
		      nil t nil 'tag)))
   (insert (replace-regexp-in-string " " "_" tag))
)

(defun My-flickr-insert-set (fset)
  "Wstawia SET z bazy z dope³nieniem nazwy"
  (interactive (list (completing-read
		      "Podaj ID zbioru: "
		      slist nil t nil 'fset)))
  ;; remove all stuff before @
  (insert (replace-regexp-in-string "^.*@" "" fset))
)

(defun My-flickr-insert-pool (pool)
  "Wstawia LOC poola do grupy z bazy z dope³nieniem nazwy"
  (interactive (list (completing-read
		      "Podaj ID poola: "
		      plist nil t nil 'pool)))
  ;; remove all stuff before @
  (insert (replace-regexp-in-string "^.*@" "" pool))
)

(defun My-flickr-buffer-upload ()
  "Uruchamia Perla w trybie compile z odpowiednimi parametrami"
  (interactive)
  ;; confirm as it can be run accidentally:
  (if (yes-or-no-p "Are you sure? ")
  (compilation-start (concat perl-prog-name " " buffer-file-name )
  )))

(defvar My-flickr-images-map nil "Keymap for some files")
(setq My-flickr-images-map (make-keymap))

(defun My-flickr-images-mode ()
   (interactive)
   ;;
   (run-hooks 'My-flickr-images-mode-hook)
   ;(font-lock-mode 1)
   ;(define-key My-flickr-images-map [(control f11)] 'delete-frame )
   (define-key My-flickr-images-map "\C-c\C-s"  'My-flickr-show-image)
   (define-key My-flickr-images-map "\C-c\C-l"  'My-flickr-show-image-rotated-left)
   (define-key My-flickr-images-map "\C-c\C-r"  'My-flickr-show-image-rotated-right)
   (define-key My-flickr-images-map "\C-c\C-i"  'My-flickr-show-image)

   (define-key My-flickr-images-map "\C-c\C-a"  'My-flickr-insert-set)
   (define-key My-flickr-images-map "\C-c\C-g"  'My-flickr-insert-geo)
   (define-key My-flickr-images-map "\C-c\C-t"  'My-flickr-insert-tag)
   (define-key My-flickr-images-map "\C-c\C-k"  'My-flickr-insert-tag)
   (define-key My-flickr-images-map "\C-c\C-p"  'My-flickr-insert-pool)

   (define-key My-flickr-images-map "\C-c\C-d"  'My-flickr-images-init)

   (define-key My-flickr-images-map "\C-c\C-c"  'My-flickr-copy-previous-line)
   (define-key My-flickr-images-map [down] 'My-flickr-down)
   (define-key My-flickr-images-map [up] 'My-flickr-up)
   (use-local-map My-flickr-images-map)

   (make-local-hook 'after-save-hook) 
   ;;(add-hook 'after-save-hook 'My-flickr-buffer-xwrite t t)
   ;;
   ;;(My-flickr-create-kb)

)

;(My-flickr-create-kb)
;; koniec ;;
