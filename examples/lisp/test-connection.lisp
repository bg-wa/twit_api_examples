;;;; TWiT API Client - Fixed Working Implementation
;;;; This is a complete implementation of the TWiT API client in Common Lisp

;;; First, ensure Quicklisp is loaded
(let ((quicklisp-init (merge-pathnames ".local/share/twit-lisp/quicklisp/setup.lisp" 
                                      (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

;;; Load required packages
(handler-case
    (progn
      (format t "Loading required packages...~%")
      (ql:quickload :dexador :silent t)
      (ql:quickload :jonathan :silent t)
      (ql:quickload :cl-ppcre :silent t)
      (ql:quickload :local-time :silent t)
      (format t "All packages loaded successfully!~%"))
  (error (e)
    (format t "Error loading packages: ~A~%" e)))

;;; Define our package
(defpackage :twit-api
  (:use :cl))

(in-package :twit-api)

;;; Utility functions

(defun format-timestring ()
  "Format current time as string using local-time if available"
  (if (find-package :local-time)
      (let ((now (funcall (intern "NOW" :local-time))))
        (funcall (intern "FORMAT-TIMESTRING" :local-time) nil now
                 :format '(:year "-" (:month 2) "-" (:day 2) " " 
                           (:hour 2) ":" (:min 2) ":" (:sec 2))))
      (multiple-value-bind (second minute hour date month year)
          (get-decoded-time)
        (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                year month date hour minute second))))

(defun log-message (level message &rest args)
  "Log a message with timestamp and level"
  (let ((timestamp (format-timestring)))
    (format t "[~A] [~A] ~A~%" timestamp level (apply #'format nil message args))
    (force-output)))

(defun mask-string (input)
  "Mask a string for display (e.g., for API keys)"
  (if (or (null input) (<= (length input) 8))
      "********"
      (concatenate 'string (subseq input 0 4) "********************************")))

(defun join-strings (strings &optional (separator "&"))
  "Join a list of strings with a separator"
  (with-output-to-string (s)
    (loop for str in strings
          for first = t then nil
          unless first do (write-string separator s)
          do (write-string str s))))

;;; HTTP Client

(defun http-get (url headers)
  "Make HTTP GET request using dexador"
  (log-message "DEBUG" "Making HTTP request to: ~A" url)
  (log-message "DEBUG" "With headers: ~S" headers)
  
  (handler-case
      (multiple-value-bind (body status response-headers)
          (dex:get url :headers headers)
        (log-message "INFO" "Request completed with status: ~A" status)
        (values body status response-headers))
    (dex:http-request-failed (e)
      (log-message "ERROR" "HTTP request failed: ~A (Status: ~A)" 
                   (dex:response-body e) (dex:response-status e))
      (values (dex:response-body e) (dex:response-status e) nil))
    (error (e)
      (log-message "ERROR" "HTTP request error: ~A" e)
      (values (format nil "{\"error\":\"~A\"}" e) 500 nil))))

;;; JSON Parser

(defun parse-json (json-string)
  "Parse JSON string into a property list using jonathan"
  (handler-case
      (jojo:parse json-string)
    (error (e)
      (log-message "ERROR" "Error parsing JSON: ~A" e)
      (list :error (format nil "JSON parse error: ~A" e)))))

;;; TWiT API Client

(defstruct twit-client
  "TWiT API Client structure"
  app-id
  app-key
  base-url)

(defun load-credentials ()
  "Load credentials from the shared credentials.yml file"
  (let ((credentials-path "../credentials.yml"))
    (log-message "INFO" "Loading credentials from: ~A" credentials-path)
    
    (handler-case
        (with-open-file (stream credentials-path :direction :input :if-does-not-exist nil)
          (if stream
              (let ((yaml-content (make-string (file-length stream)))
                    (twit-api-section nil)
                    (app-id nil)
                    (app-key nil)
                    (base-url nil))
                
                ;; Read the entire file
                (read-sequence yaml-content stream)
                
                ;; Parse YAML content using simple line-by-line approach
                (with-input-from-string (s yaml-content)
                  (loop for line = (read-line s nil nil)
                        while line
                        do (cond
                             ;; Check if we're entering the twit_api section
                             ((string= (string-trim " " line) "twit_api:")
                              (setf twit-api-section t))
                             
                             ;; If we're in the twit_api section, parse key-value pairs
                             ((and twit-api-section 
                                   (> (length line) 0)
                                   (char= (char line 0) #\Space))
                              (let* ((trimmed-line (string-trim " " line))
                                     (colon-pos (position #\: trimmed-line)))
                                (when colon-pos
                                  (let ((key (string-trim " " (subseq trimmed-line 0 colon-pos)))
                                        (value (string-trim " " (subseq trimmed-line (1+ colon-pos)))))
                                    (cond
                                      ((string= key "app_id") (setf app-id value))
                                      ((string= key "app_key") (setf app-key value))
                                      ((string= key "base_url") (setf base-url value)))))))
                             
                             ;; If we hit a line that's not indented and not empty, we've left the twit_api section
                             ((and twit-api-section 
                                   (> (length line) 0) 
                                   (not (char= (char line 0) #\Space))
                                   (not (char= (char line 0) #\Tab)))
                              (setf twit-api-section nil)))))
                
                ;; Check if we found all required credentials
                (if (and app-id app-key)
                    (progn
                      (log-message "INFO" "Credentials loaded successfully - APP_ID: ~A, BASE_URL: ~A" 
                                   app-id (or base-url "https://twit.tv/api/v1.0"))
                      (list :twit-api 
                            (list :app-id app-id
                                  :app-key app-key
                                  :base-url (or base-url "https://twit.tv/api/v1.0"))))
                    (progn
                      (log-message "ERROR" "Missing required credentials in file")
                      (error "Missing required credentials in file ~A" credentials-path))))
              
              ;; File doesn't exist
              (progn
                (log-message "ERROR" "Credentials file not found: ~A" credentials-path)
                (log-message "INFO" "Please copy credentials.yml.sample to credentials.yml and update with your actual credentials")
                (error "Credentials file not found: ~A" credentials-path))))
      
      ;; Handle any errors during file reading/parsing
      (error (err)
        (log-message "ERROR" "Error loading credentials: ~A" err)
        (error "Failed to load credentials: ~A" err)))))

(defun create-twit-client (&key app-id app-key base-url)
  "Create a new TWiT API client"
  (if (and app-id app-key)
      ;; Use provided credentials
      (make-twit-client 
       :app-id app-id
       :app-key app-key
       :base-url (or base-url "https://twit.tv/api/v1.0"))
      ;; Load credentials from file
      (let* ((credentials (load-credentials))
             (twit-creds (getf credentials :twit-api)))
        (make-twit-client
         :app-id (getf twit-creds :app-id)
         :app-key (getf twit-creds :app-key)
         :base-url (or (getf twit-creds :base-url) "https://twit.tv/api/v1.0")))))

(defun build-url (base-url endpoint &optional params)
  "Build a URL with query parameters"
  (let ((url (concatenate 'string base-url endpoint)))
    (when params
      (let ((param-strings nil))
        (loop for (key value) on params by #'cddr
              do (push (format nil "~A=~A" key value) param-strings))
        (setf url (concatenate 'string url "?" (join-strings param-strings)))))
    url))

(defun make-request (client endpoint &optional params)
  "Make an HTTP request to the TWiT API"
  (let* ((url (build-url (twit-client-base-url client) endpoint params))
         (headers `(("Accept" . "application/json")
                    ("app-id" . ,(twit-client-app-id client))
                    ("app-key" . ,(twit-client-app-key client)))))
    
    (log-message "DEBUG" "Making request to: ~A" url)
    
    (multiple-value-bind (body status response-headers)
        (http-get url headers)
      
      (declare (ignore response-headers))
      
      (cond
        ((= status 200)
         (parse-json body))
        
        ((or (= status 401) (= status 403))
         (log-message "ERROR" "Authentication error: Check your app-id and app-key")
         (list :error "Authentication failed" :code status))
        
        ((= status 404)
         (log-message "ERROR" "Resource not found: ~A" endpoint)
         (list :error "Resource not found" :code status))
        
        ((= status 500)
         (if (and body (search "usage limits are exceeded" body))
             (progn
               (log-message "ERROR" "API usage limits exceeded")
               (list :error "API usage limits exceeded" :code status))
             (progn
               (log-message "ERROR" "Server error: ~A" body)
               (list :error "Server error" :code status))))
        
        (t
         (log-message "ERROR" "Unexpected response: ~A - ~A" status body)
         (list :error "Unexpected response" :code status :body body))))))

;;; API Endpoint Functions

(defun get-shows (client &optional params)
  "Get a list of all shows"
  (log-message "INFO" "Getting shows list")
  (make-request client "/shows" params))

(defun get-show (client id &optional params)
  "Get a specific show by ID"
  (log-message "INFO" "Getting show with ID: ~A" id)
  (make-request client (concatenate 'string "/shows/" id) params))

(defun get-episodes (client &optional params)
  "Get a list of all episodes"
  (log-message "INFO" "Getting episodes list")
  (make-request client "/episodes" params))

(defun get-episode (client id &optional params)
  "Get a specific episode by ID"
  (log-message "INFO" "Getting episode with ID: ~A" id)
  (make-request client (concatenate 'string "/episodes/" id) params))

(defun get-streams (client &optional params)
  "Get live streams information"
  (log-message "INFO" "Getting streams list")
  (make-request client "/streams" params))

(defun get-people (client &optional params)
  "Get people information"
  (log-message "INFO" "Getting people list")
  (make-request client "/people" params))

;;; Test Connection

(defun test-connection ()
  "Test the connection to the TWiT API"
  (handler-case
      (let* ((client (create-twit-client)))
        
        (format t "~%=== TWiT API Client Test ===~%")
        (format t "Using APP_ID: ~A~%" (twit-client-app-id client))
        (format t "Using APP_KEY: ~A~%" (mask-string (twit-client-app-key client)))
        (format t "Using BASE_URL: ~A~%~%" (twit-client-base-url client))
        
        ;; Test Shows endpoint
        (format t "~%--- Testing /shows endpoint ---~%")
        (let ((shows (get-shows client)))
          (if (getf shows :error)
              (format t "Error: ~A~%" (getf shows :error))
              (progn
                (format t "Success! Found ~A shows~%" (getf shows :count))
                (when (getf shows :_embedded)
                  (let ((items (getf (getf shows :_embedded) :items)))
                    (loop for show in items
                          for i from 0 below (min 5 (length items))
                          do (format t "- ~A (~A)~%" 
                                     (getf show :title)
                                     (getf show :id))))))))
        
        ;; Test Episodes endpoint
        (format t "~%--- Testing /episodes endpoint ---~%")
        (let ((episodes (get-episodes client '(:limit 3))))
          (if (getf episodes :error)
              (format t "Error: ~A~%" (getf episodes :error))
              (progn
                (format t "Success! Found ~A episodes~%" (getf episodes :count))
                (when (getf episodes :_embedded)
                  (let ((items (getf (getf episodes :_embedded) :items)))
                    (loop for episode in items
                          do (format t "- ~A (~A)~%" 
                                     (getf episode :title)
                                     (getf episode :id))))))))
        
        ;; Test Streams endpoint
        (format t "~%--- Testing /streams endpoint ---~%")
        (let ((streams (get-streams client)))
          (if (getf streams :error)
              (format t "Error: ~A~%" (getf streams :error))
              (progn
                (format t "Success! Found ~A streams~%" (getf streams :count))
                (when (getf streams :_embedded)
                  (let ((items (getf (getf streams :_embedded) :items)))
                    (loop for stream in items
                          do (format t "- ~A (~A)~%" 
                                     (getf stream :title)
                                     (getf stream :id))))))))
        
        ;; Test People endpoint
        (format t "~%--- Testing /people endpoint ---~%")
        (let ((people (get-people client '(:limit 5))))
          (if (getf people :error)
              (format t "Error: ~A~%" (getf people :error))
              (progn
                (format t "Success! Found ~A people~%" (getf people :count))
                (when (getf people :_embedded)
                  (let ((items (getf (getf people :_embedded) :items)))
                    (loop for person in items
                          do (format t "- ~A (~A)~%" 
                                     (getf person :name)
                                     (getf person :id)))))))))
    
    (error (e)
      (format t "Error: ~A~%" e))))

;;; Run the test if this file is loaded directly
(format t "~%Starting TWiT API Client Test...~%")
(test-connection)

(format t "~%Test completed. Exiting...~%")

;; Exit with success code
#+sbcl (sb-ext:exit :code 0)
#+clisp (ext:exit 0)
#-(or sbcl clisp) (quit)
