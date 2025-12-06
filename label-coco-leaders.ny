;nyquist plug-in
;version 4
;type analyze
;format "labels"
;name "Label CoCo Leaders"
;action "Finding frequency pairs..."
;author "tim lindner with Claude (Anthropic, Sonnet 4.5)"
;release 1.0
;info "Finds frequency ratio patterns"
;control ratio-target "Target Ratio" real "" 1.7 0.1 10
;control threshold "Threshold (%)" real "" 10 0 50
;control zero-threshold "Zero Threshold" real "" 0.01 0 1

(setq tolerance (/ threshold 100.0))
(setq target-max (+ ratio-target tolerance))
(setq target-min (- ratio-target tolerance))

(defun samples-to-time (idx)
  (/ (float idx) *sound-srate*))

;; Main processing loop with snd-fetch
(let ((prev (snd-fetch *track*))
      (idx 0)
      (crossings '())
      (labels '())
      (current-start nil)
      (current-end nil)
      (count 0)
      (high-sum 0)
      (low-sum 0))
  
  ;; Preload first 5 crossings
  (do ((curr (snd-fetch *track*) (snd-fetch *track*)))
      ((or (not curr) (>= (length crossings) 5)))
    (when (and prev curr
               (or (and (<= prev zero-threshold) (> curr zero-threshold))
                   (and (>= prev (- zero-threshold)) (< curr (- zero-threshold)))))
      (push idx crossings))
    (setq prev curr)
    (setq idx (1+ idx)))
  
  (setq crossings (reverse crossings))
  
  ;; Continue collecting crossings and processing
  (do ((curr (snd-fetch *track*) (snd-fetch *track*)))
      ((not curr))
    
    ;; Detect zero crossing
    (when (and prev curr
               (or (and (<= prev zero-threshold) (> curr zero-threshold))
                   (and (>= prev (- zero-threshold)) (< curr (- zero-threshold)))))
      
      ;; Add new crossing and remove oldest (keep window of 5)
      (setq crossings (append (cdr crossings) (list idx)))
      
      ;; Analyze the current window of 5 crossings
      (let* ((c1 (nth 0 crossings))
             (c3 (nth 2 crossings))
             (c5 (nth 4 crossings))
             (wave1 (- c3 c1))
             (wave2 (- c5 c3))
             (ratio (/ (float wave1) wave2)))
        
        ;; Check for target ratio pattern
        (when (and (>= ratio target-min) (<= ratio target-max))
          (let* ((start-time (samples-to-time c1))
                 (end-time (samples-to-time c5))
                 (freq1 (/ *sound-srate* wave1))
                 (freq2 (/ *sound-srate* wave2))
                 (high-freq (max freq1 freq2))
                 (low-freq (min freq1 freq2)))
            
            ;; Check if contiguous with previous match
            (if (and current-end (= start-time current-end))
                ;; Extend current group
                (progn
                  (setq current-end end-time)
                  (setq count (1+ count))
                  (setq high-sum (+ high-sum high-freq))
                  (setq low-sum (+ low-sum low-freq)))
                ;; Save previous group and start new one
                (progn
                  (when (and current-start (>= (- current-end current-start) 0.25))
                    (let* ((avg-high (round (/ high-sum count)))
                           (avg-low (round (/ low-sum count)))
                           (calc-ratio (/ (round (* (/ (float avg-high) avg-low) 100.0)) 100.0)))
                      (push (list current-start 
                                 current-end 
                                 (format nil "~aHz/~aHz r=~a (x~a)" 
                                        avg-high avg-low calc-ratio count))
                            labels)))
                  (setq current-start start-time)
                  (setq current-end end-time)
                  (setq count 1)
                  (setq high-sum high-freq)
                  (setq low-sum low-freq)))))))
    
    (setq prev curr)
    (setq idx (1+ idx)))
  
  ;; Don't forget the last group
  (when (and current-start (>= (- current-end current-start) 0.25))
    (let* ((avg-high (round (/ high-sum count)))
           (avg-low (round (/ low-sum count)))
           (calc-ratio (/ (round (* (/ (float avg-high) avg-low) 100.0)) 100.0)))
      (push (list current-start 
                 current-end 
                 (format nil "~aHz/~aHz r=~a (x~a)" 
                        avg-high avg-low calc-ratio count))
            labels)))
  
  (if labels
      (reverse labels)
      ""))