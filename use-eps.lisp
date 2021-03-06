;; -*- Mode:Lisp; Syntax:ANSI-Common-LISP; Coding:us-ascii-unix; fill-column:158 -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;; @file      use-eps.lisp
;; @author    Mitch Richling <https://www.mitchr.me>
;; @brief     Floating point comparison: within EPSilon.@EOL
;; @std       Common Lisp
;; @see       tst-eps.lisp
;; @copyright
;;  @parblock
;;  Copyright (c) 1996,1997,2008,2013,2015, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
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
;; @todo      Add Macro that can make a comparison function with a given epsilon..@EOL@EOL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defpackage :MJR_EPS
  (:USE :COMMON-LISP
        :MJR_ARR)
  (:DOCUMENTATION "Brief: Floating point comparison: within EPSilon.;")
  (:EXPORT #:mjr_eps_help
           #:*mjr_eps_eps* #:mjr_eps_normalize
           #:mjr_eps_= #:mjr_eps_=0
           #:mjr_eps_integerp #:mjr_eps_evenp #:mjr_eps_oddp
           #:mjr_eps_make-fixed=
           #:mjr_eps_zap
           ))

(in-package :MJR_EPS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_help ()
"Help for MJR_EPS:

This package implements 'within epsilon' comparisons -- i.e. if the comparison is within epsilon of being true, then non-NIL is returned.  The primary use
case is for testing convergence in numerical algorithms.

All functions apply MJR_EPS_NORMALIZE to arguments."
  (documentation 'mjr_eps_help 'function))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defparameter *mjr_eps_eps* 0.00001
  "The default epsilon used for fuzzy comparisons")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_normalize (eps &rest rest)
"Normalize an EPS argument

If EPS is:
  * NIL: use global parameter *mjr_eps_eps* (*mjr_eps_eps* may be a positive or negative real number)
  * positive real number: use as traditional epsilon value
  * negative real number: use as a percentage (1% of magnitude of the smallest remaining argument)
  * integer 0: use 0 as the eps (reverts all tests to native lisp version)
  * anything else: ERROR!"
  (cond ((null eps)                       (apply #'mjr_eps_normalize *mjr_eps_eps* rest))
        ((not (numberp eps))              (error "mjr_eps_normalize: If EPS is non-NIL, then it must be a number!"))
        ((complexp eps)                   (error "mjr_eps_normalize: If EPS is a number, is must be real!"))
        ((> eps 0)                        eps)
        ((< eps 0)                        (max 1d-15
                                               (* (/ (abs eps) 100.0d0)
                                                  (reduce (lambda (a &optional b)
                                                            (if b
                                                                (min (abs a) (abs b))
                                                                (abs a)))
                                                          rest))))
        ((and (integerp eps) (zerop eps)) 0)
        ('t                               (error "mjr_eps_normalize: Something very bad happened!"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_= (a b &optional eps)
  "Return true if number are within EPS of zero.

Works with numbers, lists, vectors, multidimensional arrays, and nested combinations of lists, vectors, and arrays.
A and B should be structurally identical -- i.e. (mjr_eps_= '(1 2 3) '(1 (2) 3)) is not valid."
  (if (and (integerp eps) (zerop eps))
      (= a b)
      (typecase  a
        (number (< (abs (- a b)) (mjr_eps_normalize eps a b)))
        (vector (and (= (length a) (length b))                         (every         (lambda (x y) (mjr_eps_= x y eps)) a b)))
        (list   (and (= (length a) (length b))                         (every         (lambda (x y) (mjr_eps_= x y eps)) a b)))
        (array  (and (equal (array-dimensions a) (array-dimensions b)) (mjr_arr_every (lambda (x y) (mjr_eps_= x y eps)) a b))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_=0 (a &optional eps)
  "Return true if number(s) is(are) within EPS of zero

Works with numbers, lists, vectors, multidimensional arrays, and nested combinations of lists, vectors, and arrays."
  (if (and (integerp eps) (zerop eps))
      (zerop a)
      (typecase  a
        (number (< (abs a) (mjr_eps_normalize eps a)))
        (vector (every         (lambda (x) (mjr_eps_=0 x eps)) a))
        (list   (every         (lambda (x) (mjr_eps_=0 x eps)) a))
        (array  (mjr_arr_every (lambda (x) (mjr_eps_=0 x eps)) a)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_integerp (a &optional eps)
  (if (and (integerp eps) (zerop eps))
      (integerp a)
      (mjr_eps_= a (round a) eps)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_evenp (a &optional eps)
  (if (and (integerp eps) (zerop eps))
      (evenp a)
      (and (mjr_eps_integerp a eps) (evenp (round a)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_oddp (a &optional eps)
  (if (and (integerp eps) (zerop eps))
      (oddp a)
      (and (mjr_eps_integerp a eps) (oddp  (round a)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmacro mjr_eps_make-fixed= (eps)
  "Construct an MJR_EPS_= function with a fixed EPS -- very useful for unit tests"
  (if (and (integerp eps) (zerop eps))
      `(lambda (a b) (= a b))
      `(lambda (a b) (mjr_eps_= a b ,eps))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr_eps_zap (a &optional eps)
  "Zero out small numbers. Real and imaginary parts of complex Numbers are individually zapped."
  (typecase  a  (number  (if (complexp a)
                             (complex (mjr_eps_zap (realpart a) eps)
                                      (mjr_eps_zap (imagpart a) eps))
                             (if (< (abs a) (mjr_eps_normalize eps a))
                                 0
                                 a)))
             (list    (mapcar      (lambda (x) (mjr_eps_zap x eps)) a))
             (array   (mjr_arr_map (lambda (x) (mjr_eps_zap x eps)) a))))
