;nyquist plug-in
;version 4
;type analyze
;format "labels"
;name "Decode CoCo Data"
;action "Finding frequency pairs..."
;author "tim lindner"
;release 1.0
;info "Finds frequency ratio patterns"
;control ratio-target "Target Ratio" real "" 1.7 0.1 10
;control threshold "Threshold (%)" real "" 10 0 50
;control zero-threshold "Zero Threshold" real "" 0.01 0 1
;codetype sal

set tolerance = threshold / 100.0
set target-max = ratio-target + tolerance
set target-min = ratio-target - tolerance
set neg-zero-threshold = 0 - zero-threshold

; Main processing
set continue-processing = #t
set skip-zero-crossings = 1
set prev = snd-fetch(*track*)
set idx = 1
set crossings = {4 3 2 1 0}
set labels = list()
set current-start = #f
set current-end = #f
set count = 0
set high-sum = 0
set low-sum = 0
;set avg-high = 2400.0
;set avg-low = 1200.0
set decode-threshold = 2400.0 / 1200.0
set current-mode = "leader"
set decode-byte = 0

loop
	while continue-processing
	begin
	
		; Analyze the current window of 5 crossings
		set c1 = nth(4, crossings)
		set c3 = nth(2, crossings)
		set c5 = nth(0, crossings)
		set wave1 = c3 - c1
		set wave2 = c5 - c3

		if current-mode = "sync" then
			begin
				set freq2 = *sound-srate* / wave2
				set decode-byte = decode-byte / 2
				if freq2 > decode-threshold then
					begin
						set decode-byte = decode-byte + 128
						;print "1"
					end
				;else
					;print "0"
				
				if decode-byte = 60 then
					begin
						set continue-processing = #f
						; set current-mode = "length"
						set labels @= list(idx, "Found sync")
					end
				else
					begin
						; check for timeout
						set end-time = float(c5) / *sound-srate*
						if (end-time - current-start) >= 1.5 then
							begin
								;print current-start
								;print end-time
								set current-mode = "leader"
								set skip-zero-crossings = 1
							end
					end
			end
	
		if current-mode = "leader" then
			begin
				; Check for target ratio pattern
				set ratio = float(wave1) / wave2
				if ratio >= target-min & ratio <= target-max then
					begin
						set start-time = float(c1) / *sound-srate*
						set end-time = float(c5) / *sound-srate*
						set freq1 = *sound-srate* / wave1
						set freq2 = *sound-srate* / wave2
						set high-freq = max(freq1, freq2)
						set low-freq = min(freq1, freq2)
						
						set labels @= list(start-time, end-time, "ratio pair")
						set labels @= list(float(c3) / *sound-srate*, "middle")
						; Check if contiguous with previous match
						if current-end & start-time = current-end then
							begin
								; Extend current group
								set current-end = end-time
								set count += 1
								set high-sum += high-freq
								set low-sum += low-freq
							end
						else
							begin
								; Save previous group and start new one
								if current-start & (current-end - current-start) >= 0.25 then
									begin
										set avg-high = round(high-sum / count)
										set avg-low = round(low-sum / count)
										set decode-threshold = (avg-high + avg-low) / 2.0
										; set calc-ratio = round(float(avg-high) / avg-low * 100.0) / 100.0
										; set label-text = strcat(format(nil, "~a", avg-low), " Hz, ", format(nil, "~a", avg-high), " Hz, ", format(nil, "~a", calc-ratio))
										set labels @= list(current-end, "Found leader")
										set current-mode = "sync"
										set skip-zero-crossings = 2
									end
						
								set current-start = start-time
								set current-end = end-time
								set count = 1
								set high-sum = high-freq
								set low-sum = low-freq
							end
					end
			end

		; process zero crossings
		loop
		repeat skip-zero-crossings
			begin
				set detect-crossing = #f
				loop
					until detect-crossing
					begin
						if not(curr) then
							begin
								set continue-processing = #f
								set detect-crossing = #t
							end
						else
							begin
								if (prev <= 0.0 & curr > 0.0) |
									 (prev >= 0.0 & curr < 0.0) then
									begin
										; Add new crossing to front of list
										set crossings @= idx
										set detect-crossing = #t
									end
		
								set prev = curr
								set idx += 1
								set curr = snd-fetch(*track*)
							end
					end
				end
			end
		end
	end
end

if length(labels) > 0 then
  return labels
else
  return "No crossings found"
  