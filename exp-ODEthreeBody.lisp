;; -*- Mode:Lisp; Syntax:ANSI-Common-LISP; Coding:us-ascii-unix; fill-column:132 -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file      exp-ODEthreeBody.lisp
;; @author    Mitch Richling <http://www.mitchr.me>
;; @Copyright Copyright 2010,2012 by Mitch Richling.  All rights reserved.
;; @brief     A famous 3-body problem.@EOL
;; @Keywords  3-body problem ode
;; @Std       Common Lisp
;;
;;            This particular example is documented in two good texts:
;;              Butcher (2008); Numerical Methods for Ordinary Differential Equations; p29-30
;;              Hairer, Norsett & Wanner (2009). Solving Ordinary Differential Equations. I: Nonstiff Problems. p129-130
;;            Set ACTION to select option:
;;              * (setf action :threeLobe-fehlberg)
;;              * (setf action :threeLobe-euler)
;;              * (setf action :threeLobe-rk4)
;;              * (setf action :fiveLobe)
;;            

;;----------------------------------------------------------------------------------------------------------------------------------
(time (let ((action (if (boundp 'action) (symbol-value 'action) :fiveLobe)))
        (flet ((pvf (time y) 
                 (declare (ignore time))
                 (let* ((x1  (aref y 0))
                        (x2  (aref y 1))
                        (v1  (aref y 2))
                        (v2  (aref y 3))
                        (mu  (/ 1 81.45d0))
                        (s1  (+ x1 mu -1))
                        (s2  (- 1 mu))
                        (s3  (+ x1 mu))
                        (x22 (expt x2 2))
                        (s12 (expt s1 2))
                        (s32 (expt s3 2))
                        (bf1 (expt (+ x22 s12) 3/2))
                        (bf2 (expt (+ x22 s32) 3/2)))
                   (declare (type double-float x1 x2 v1 v2 mu s1 s2 s3 x22 s12 s32 bf1 bf2))
                   (vector v1
                           v2
                           (- (* 2 v2) (- x1) (/ (* mu s1) bf1) (/ (* s2 s3) bf2))
                           (- x2 (* 2 v1) (/ (* mu x2) bf1) (/ (* s2 x2) bf2))))))
          (let ((ns (cond ((eq action :fiveLobe)           (mjr_ode_slv-ivp-erk-interval #'pvf
                                                                                         #(0.87978d0 0d0 0d0 -0.3797d0)
                                                                                         0d0 19.14045706162071d0
                                                                                         :x-delta-min   1d-15
                                                                                         :y-err-abs-max 1d-10
                                                                                         :x-delta-max (/ 17.06521656015796d0 1000)
                                                                                         :algorithm #'mjr_ode_erk-step-fehlberg-7-8
                                                                                         :return-all-steps 't))
                          ((eq action :threeLobe-fehlberg) (mjr_ode_slv-ivp-erk-interval #'pvf
                                                                                         #(0.994d0 0d0 0d0 -2.0015851063790825224d0)
                                                                                         0d0 17.06521656015796d0
                                                                                         :x-delta-min   1d-15
                                                                                         :y-err-abs-max 1d-10
                                                                                         :x-delta-max (/ 17.06521656015796d0 1000)
                                                                                         :algorithm #'mjr_ode_erk-step-fehlberg-7-8
                                                                                         :return-all-steps 't))
                          ((eq action :threeLobe-rk4)      (mjr_ode_slv-ivp-erk-interval #'pvf
                                                                                         #(0.994d0 0d0 0d0 -2.0015851063790825224d0)
                                                                                         0d0 17.06521656015796d0
                                                                                         :x-delta-max (/ 17.06521656015796d0 6000)
                                                                                         :algorithm #'mjr_ode_erk-step-runge-kutta-4
                                                                                         :return-all-steps 't))
                          ((eq action :threeLobe-euler)    (mjr_ode_slv-ivp-erk-interval #'pvf
                                                                                         #(0.994d0 0d0 0d0 -2.0015851063790825224d0)
                                                                                         0d0 17.06521656015796d0
                                                                                         :x-delta-max (/ 17.06521656015796d0 24000)
                                                                                         :algorithm #'mjr_ode_erk-step-euler-1
                                                                                         :return-all-steps 't)))))
            (mjr_vtk_from-dsimp (concatenate 'string "exp-ODEthreeBody-OUT-" (symbol-name action) ".vtk")  
                                (mjr_dsimp_make-from-points ns :point-columns '(1 2) :data-columns 0 :data-column-names "time" :connect-points 't) 
                                :simplices 1)
            (mjr_plot_data :dat ns
                           :title "Orbit"
                           :main (concatenate 'string "Three Body Problem " (symbol-name action))
                           :datcols (list 1 2);; index 0 is the x
                           :xlim '(-2 2) :ylim '(-2 2)
                           :type :l)))))
