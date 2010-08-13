(define (caar pair) (car (car pair)))
(define (cadr pair) (car (cdr pair)))
(define (cdar pair) (cdr (car pair)))
(define (cddr pair) (cdr (cdr pair)))
(define (caaar pair) (car (car (car pair))))
(define (caadr pair) (car (car (cdr pair))))
(define (cadar pair) (car (cdr (car pair))))
(define (caddr pair) (car (cdr (cdr pair))))
(define (cdaar pair) (cdr (car (car pair))))
(define (cdadr pair) (cdr (car (cdr pair))))
(define (cddar pair) (cdr (cdr (car pair))))
(define (cdddr pair) (cdr (cdr (cdr pair))))
(define (caaaar pair) (car (car (car (car pair)))))
(define (caaadr pair) (car (car (car (cdr pair)))))
(define (caadar pair) (car (car (cdr (car pair)))))
(define (caaddr pair) (car (car (cdr (cdr pair)))))
(define (cadaar pair) (car (cdr (car (car pair)))))
(define (cadadr pair) (car (cdr (car (cdr pair)))))
(define (caddar pair) (car (cdr (cdr (car pair)))))
(define (cadddr pair) (car (cdr (cdr (cdr pair)))))
(define (cdaaar pair) (cdr (car (car (car pair)))))
(define (cdaadr pair) (cdr (car (car (cdr pair)))))
(define (cdadar pair) (cdr (car (cdr (car pair)))))
(define (cdaddr pair) (cdr (car (cdr (cdr pair)))))
(define (cddaar pair) (cdr (cdr (car (car pair)))))
(define (cddadr pair) (cdr (cdr (car (cdr pair)))))
(define (cdddar pair) (cdr (cdr (cdr (car pair)))))
(define (cddddr pair) (cdr (cdr (cdr (cdr pair)))))


(define (not x)      (if x #f #t))

(define (list . objs)  objs)
(define (id obj)       obj)

(define (flip func)    (lambda (arg1 arg2) (func arg2 arg1)))

(define (curry func arg1)  (lambda (arg) (apply func (cons arg1 (list arg)))))
(define (compose f g)      (lambda (arg) (f (apply g arg))))

(define (foldr func end lst)
  (if (null? lst)
	  end
	  (func (car lst) (foldr func end (cdr lst)))))

(define (foldl func accum lst)
  (if (null? lst)
	  accum
	  (foldl func (func accum (car lst)) (cdr lst))))

(define fold foldl)
(define reduce fold)

(define (unfold func init pred)
  (if (pred init)
      (cons init '())
      (cons init (unfold func (func init) pred))))

(define (sum . lst)     (fold + 0 lst))
(define (product . lst) (fold * 1 lst))
(define (and . lst)     (fold && #t lst))
(define (or . lst)      (fold || #f lst))

(define (max first . rest) (fold (lambda (old new) (if (> old new) old new)) first rest))
(define (min first . rest) (fold (lambda (old new) (if (< old new) old new)) first rest))

(define zero?        (curry = 0))
(define positive?    (curry < 0))
(define negative?    (curry > 0))
(define (odd? num)   (= (mod num 2) 1))
(define (even? num)  (= (mod num 2) 0))

(define (length lst)    (fold (lambda (x y) (+ x 1)) 0 lst))
(define (reverse lst)   (fold (flip cons) '() lst))

(define (mem-helper pred op)  (lambda (acc next) (if (and (not acc) (pred (op next))) next acc)))
(define (memq obj lst)        (fold (mem-helper (curry eq? obj) id) #f lst))
(define (memv obj lst)        (fold (mem-helper (curry eqv? obj) id) #f lst))
(define (member obj lst)      (fold (mem-helper (curry equal? obj) id) #f lst))
(define (assq obj alist)      (fold (mem-helper (curry eq? obj) car) #f alist))
(define (assv obj alist)      (fold (mem-helper (curry eqv? obj) car) #f alist))
(define (assoc obj alist)     (fold (mem-helper (curry equal? obj) car) #f alist))

; TODO on map and for-each - Support variable number of args, per spec:
; http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-9.html#%_sec_6.4
;(define (for-each func . lsts) )

; TODO:
(define (for-each func lst) 
  (if (eq? 1 (length lst))
	(func (car lst))
    (begin (func (car lst))
           (for-each func (cdr lst)))))

(define (map func lst)        (foldr (lambda (x y) (cons (func x) y)) '() lst))
(define (filter pred lst)     (foldr (lambda (x y) (if (pred x) (cons x y) y)) '() lst))


(define (list-tail lst k) 
        (if (zero? k)
          lst
          (list-tail (cdr lst) (- k 1))))
(define (list-ref lst k)  (car (list-tail lst k)))

(define (append inlist alist) (foldr (lambda (ap in) (cons ap in)) alist inlist))


(define-syntax let
  (syntax-rules ()
    ((_ ((x v) ...) e1 e2 ...)
    ((lambda (x ...) e1 e2 ...) v ...))))

