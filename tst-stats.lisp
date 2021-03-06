;; -*- Mode:Lisp; Syntax:ANSI-Common-LISP; Coding:us-ascii-unix; fill-column:158 -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;; @file      tst-stats.lisp
;; @author    Mitch Richling <https://www.mitchr.me>
;; @brief     Unit Tests.@EOL
;; @std       Common Lisp
;; @see       use-stats.lisp
;; @copyright
;;  @parblock
;;  Copyright (c) 1996,1997,1998,2004,2013,2015, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
;;
;;  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
;;
;;  1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
;;
;;  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
;;     and/or other materials provided with the distribution.
;;
;;  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software
;;     without specific prior written permission.
;;
;;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;;  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;;  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
;;  DAMAGE.
;;  @endparblock
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defpackage :MJR_STATS-TESTS (:USE :COMMON-LISP :LISP-UNIT :MJR_STATS :MJR_EPS))

(in-package :MJR_STATS-TESTS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-test mjr_stats_avg
  (assert-equal                 9/2         (mjr_stats_avg  1 2 3 4 5 6 7 8 9 0))
  ;; Float case
  (assert-equality #'mjr_eps_=  4.5         (mjr_stats_avg  1 2.0 3 4 5 6 7 8 9 0))
  ;; Matrix case (matrix gets flattened)
  (assert-equal 5/2                         (mjr_stats_avg  #2a((1 2)(3 4))))
  ;; Complex case
  (assert-equal #C(9/2 9/2)                 (mjr_stats_avg  #C(1 1) #C(2 2) #C(3 3) #C(4 4) #C(5 5) #C(6 6) #C(7 7) #C(8 8) #C(9 9) #C(0 0)))
  (assert-equal #C(9/2 1/10)                (mjr_stats_avg  #C(1 1) 2 3 4 5 6 7 8 9 0))
  ;; Errors
  (assert-error 'error                      (mjr_stats_avg  't))
  (assert-error 'error                      (mjr_stats_avg  nil))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-test mjr_stats_subtotal
  (assert-equal '(1 3 6 10 15)                                 (mjr_stats_subtotal '(1 2 3 4 5)))
  (assert-equal '(#C(1 1) #C(3 3) #C(6 6) #C(10 10) #C(15 15)) (mjr_stats_subtotal  '(#C(1 1) #C(2 2) #C(3 3) #C(4 4) #C(5 5))))
  ;; Errors
  (assert-error 'error                                         (mjr_stats_subtotal ))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-test mjr_stats_summary
  (assert-equalp '((:GMEAN . 4.1471663) (:LGMEAN . 1.4224253) (:VARP . 137/12)
                   (:SDP . 3.3788557) (:DOOC . 8) (:AOOC . 1) (:VAR . 33/4)
                   (:SD . 2.8722813) (:MEAN . 9/2) (:MAX . 9) (:MIN . 0) (:SUM . 45)
                   (:NZ . 1) (:NN . 0) (:PN . 9) (:SUML . 12.801827) (:SUMABS . 45)
                   (:SUMSQ . 285) (:N . 10))                                           (mjr_stats_summary '(1 2 3 4 5 6 7 8 9 0)))
  (assert-equalp (mjr_stats_summary #(1 2 3 4 5 6 7 8 9 0))                            (mjr_stats_summary '(1 2 3 4 5 6 7 8 9 0)))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-test mjr_stats_fmt-summary
  (assert-equalp
   "
:SUMS>     :SUM: 45;  :SUML: 12.801827;  :SUMSQ: 285;  :SUMABS: 45;
:COUNTS>   :N: 10;  :PN: 9;  :NN: 0;  :NZ: 1;  :AOOC: 1;  :DOOC: 8;
:SPREAD>   :MIN: 0;  :MAX: 9;  :SD: 2.8722813;  :VAR: 33/4;  :SDP: 3.3788557;  :VARP: 137/12;
:CENTER>   :MEAN: 9/2;  :GMEAN: 4.1471663;  :LGMEAN: 1.4224253;
"
   (mjr_stats_fmt-summary (mjr_stats_summary '(1 2 3 4 5 6 7 8 9 0))))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-test mjr_stats_linear-regression
  ;; Basic checks
  (assert-equal 1     (first  (multiple-value-list (mjr_stats_linear-regression '(1 2) '(1   2)))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2) '(1   2)))))
  (assert-equal -1    (first  (multiple-value-list (mjr_stats_linear-regression '(1 2) '(-1  -2)))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2) '(-1  -2)))))
  (assert-equal 1     (first  (multiple-value-list (mjr_stats_linear-regression '(1 2) '(2   3)))))
  (assert-equal 1     (second (multiple-value-list (mjr_stats_linear-regression '(1 2) '(2   3)))))
  (assert-equal -1    (first  (multiple-value-list (mjr_stats_linear-regression '(1 2) '(2   1)))))
  (assert-equal 3     (second (multiple-value-list (mjr_stats_linear-regression '(1 2) '(2   1)))))
  (assert-equal 1/2   (first  (multiple-value-list (mjr_stats_linear-regression '(1 2) '(1/2 1)))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2) '(1/2 1)))))
  ;; Multi-point
  (assert-equal 1     (first  (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4) '(1 2 3 4)))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4) '(1 2 3 4)))))
  (assert-equal 11/10 (first  (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4) '(1 3 2 5)))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4) '(1 2 3 4)))))
  ;; Transforms
  (assert-equal 1     (first  (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4)  '(1 4 9 16) :x-tform (lambda (x) (* x x))))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 2 3 4)  '(1 4 9 16) :x-tform (lambda (x) (* x x))))))
  (assert-equal 1     (first  (multiple-value-list (mjr_stats_linear-regression '(1 4 9 16) '(1 2 3 4)  :y-tform (lambda (x) (* x x))))))
  (assert-equal 0     (second (multiple-value-list (mjr_stats_linear-regression '(1 4 9 16) '(1 2 3 4)  :y-tform (lambda (x) (* x x))))))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(run-tests)
