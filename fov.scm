(module fov
        (calculate-fov)

        (import scheme
                srfi-1
                srfi-25)

        (define (get-ring x y radius)
          (let* ((boxes '()) (theta (- (/ 1 (* 8 radius)))) (theta-inc (/ 1 (* 4 radius))))
            (begin
              (if (= (modulo radius 2) 1)
                (set! theta (- (/ theta-inc 2))))
              (for-each (lambda (i)
                          (set! boxes (cons `(,(+ i x) ,(+ (- radius i) y) ,theta ,(+ theta theta-inc)) boxes))
                          (set! theta (+ theta theta-inc)))
                        (iota radius radius -1))
              (for-each (lambda (i)
                          (set! boxes (cons `(,(+ (- i) x) ,(+ (- radius i) y) ,theta ,(+ theta theta-inc)) boxes))
                          (set! theta (+ theta theta-inc)))
                        (iota radius 0 1))
              (for-each (lambda (i)
                          (set! boxes (cons `(,(+ (- i) x) ,(+ (- (- radius  i)) y) ,theta ,(+ theta theta-inc)) boxes))
                          (set! theta (+ theta theta-inc)))
                        (iota radius radius -1))
              (for-each (lambda (i)
                          (set! boxes (cons `(,(+ i x) ,(+ (- (- radius i)) y) ,theta ,(+ theta theta-inc)) boxes))
                          (set! theta (+ theta theta-inc)))
                        (iota radius 0 1))
              boxes)))

        (define (add-shadow shadow-queue angle-start angle-end)
          (if (< angle-start 0)
              (merge-shadow (merge-shadow shadow-queue (+ 1 angle-start) 1) 0 angle-end)
              (if (null? shadow-queue)
                  `((,angle-start ,angle-end))
                  (merge-shadow shadow-queue angle-start angle-end))))

        (define (merge-shadow shadow-queue angle-start angle-end)
          (if (inside-shadow? shadow-queue angle-start angle-end)
              shadow-queue
              (if (intersect-shadow? shadow-queue angle-start angle-end)
                  (let ((intersections (intersections-shadow shadow-queue angle-start angle-end)))
                    (fold (lambda (shadow l)
                            (if (memq shadow intersections)
                                (let ((theta-start (first shadow)) (theta-end (second shadow)))
                                  (if (and (< angle-start theta-start) (> angle-end theta-end))
                                      (cons `(,(min theta-start theta-end angle-start angle-end)
                                              ,(max theta-start theta-end angle-start angle-end)) l)
                                      (cons `(,(min angle-start theta-start) ,(max angle-end theta-end)) l)))
                                (cons shadow l)))
                          '() shadow-queue))
                  (cons `(,angle-start ,angle-end) shadow-queue))))

        (define (inside-shadow? shadow-queue angle-start angle-end)
          (if (< angle-start 0)
              (and (inside-shadow? shadow-queue 0 angle-end) (inside-shadow? shadow-queue (+ angle-start 1) 1))
              (not (null? (filter (lambda (shadow)
                                    (let ((theta-start (first shadow)) (theta-end (second shadow)))
                                      (and (>= angle-start theta-start) (<= angle-end theta-end))))
                                  shadow-queue)))))

        (define (intersections-shadow shadow-queue angle-start angle-end)
          (filter (lambda (shadow)
                    (let ((theta-start (first shadow)) (theta-end (second shadow)))
                      (or (and (< angle-start theta-start) (> angle-end theta-start))
                          (and (> angle-end theta-end) (< angle-start theta-end)))))
                  shadow-queue))

        (define (intersect-shadow? shadow-queue angle-start angle-end)
          (not (null? (intersections-shadow shadow-queue angle-start angle-end))))

        (define (calculate-fov grid width height x-start y-start radius)
          (let ((shadow-queue '()) (fov-grid (make-array (shape 0 width 0 height) #f)))
            (for-each (lambda (rho)
                        (for-each (lambda (cell)
                                    (let ((x (first cell)) (y (second cell))
                                          (theta-start (third cell)) (theta-end (fourth cell)))
                                      (if (not (inside-shadow? shadow-queue theta-start theta-end))
                                        (begin
                                          (array-set! fov-grid x y #t)
                                          (if (eq? (array-ref grid x y) #\#)
                                            (set! shadow-queue (add-shadow shadow-queue theta-start theta-end)))))))
                                  (get-ring x-start y-start rho)))
                      (iota radius 1 1))
            fov-grid))

        )