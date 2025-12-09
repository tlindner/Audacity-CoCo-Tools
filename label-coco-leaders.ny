;nyquist plug-in
;version 4
;type analyze
;format "labels"
;name "Label CoCo Leaders"
;action "Finding frequency pairs..."
;author "Claude"
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
set prev = snd-fetch(*track*)
set idx = 0
set crossings = {0 0 0 0 0}
set labels = list()
set current-start = #f
set current-end = #f
set count = 0
set high-sum = 0
set low-sum = 0

; Continue collecting crossings and processing
set curr = snd-fetch(*track*)
loop
  until not(curr)
  begin
    ; Detect zero crossing
    if (prev <= zero-threshold & curr > zero-threshold) |
       (prev >= neg-zero-threshold & curr < neg-zero-threshold) then
      begin
        ; Add new crossing to front of list
        set crossings @= idx
        
        ; Analyze the current window of 5 crossings
        set c1 = nth(4, crossings)
        set c3 = nth(2, crossings)
        set c5 = nth(0, crossings)
        set wave1 = c3 - c1
        set wave2 = c5 - c3
        set ratio = float(wave1) / wave2
            
            ; Check for target ratio pattern
            if ratio >= target-min & ratio <= target-max then
              begin
                set start-time = float(c1) / *sound-srate*
                set end-time = float(c5) / *sound-srate*
                set freq1 = *sound-srate* / wave1
                set freq2 = *sound-srate* / wave2
                set high-freq = max(freq1, freq2)
                set low-freq = min(freq1, freq2)
                
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
                        set calc-ratio = round(float(avg-high) / avg-low * 100.0) / 100.0
                        set label-text = strcat(format(nil, "~a", avg-low), " Hz, ", format(nil, "~a", avg-high), " Hz, ", format(nil, "~a", calc-ratio))
                        set labels @= list(current-start, current-end, label-text)
                      end
                    
                    set current-start = start-time
                    set current-end = end-time
                    set count = 1
                    set high-sum = high-freq
                    set low-sum = low-freq
                  end
              end
      end
    
    set prev = curr
    set idx += 1
    set curr = snd-fetch(*track*)
  end
end

if length(labels) > 0 then
  return labels
else
  return "No crossings found"
  