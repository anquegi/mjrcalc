;; -*- Mode:Lisp; Syntax:ANSI-Common-LISP; Coding:us-ascii-unix; fill-column:158 -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;; @file      exp-Gravity3D.lisp
;; @author    Mitch Richling <https://www.mitchr.me>
;; @brief     Difference between two gravitational systems with the same total mass.@EOL
;; @std       Common Lisp
;; @copyright 
;;  @parblock
;;  Copyright (c) 2015, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
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
;; @filedetails
;;
;;  We look at the difference between the gravitational fields of two different systems with the same mass -- just different geometry.  Why?  Because
;;  frequently such systems are used interchangeably in simulation code because people think that one need simply use the total mass and the center of
;;  gravity.  This may work if distances are quite large, but as you get close to the objects things break down.
;;
;;  We compare two scenarios:
;;  
;;         * Three Iridium spheres.  One (m1) of radius 1000m located at (0, 1000), a second (m2) of the same radius located at (0, -1000), and a third (mp)
;;           of radius 10 who's location varies.  We compute the gravitational force vector on the small sphere.
;;  
;;         * Two Iridium spheres.  One (m0) with radius 1000*2^(1/3) (twice the mass of each big sphere in the previous scenario), and a second sphere (mp) of
;;           radius 10 who's location varies.  We compute the gravitational force vector on the small sphere.
;;  
;;  The total mass in both systems is the same.  The larger sphere in the second scenario is located at the center of mass for the two large spheres in the
;;  first scenario.  One might be tempted to combine the two large spheres into a single sphere located at the center of mass when faced with this problem;
;;  however, this experiment shows the very different forces involved.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(labels ((mi (r) ;; Compute the mass of an Iridium sphere of given radius
           (* (expt r 3) pi 4/3 22560))
         (f (pos1 rad1 pos2 rad2) ;; force vector between Iridium sphere1 at pos1 with radius rad1, and Iridium sphere2 at pos2 with radius rad2
           (let ((d (mjr_vec_- pos1 pos2)))
             (mjr_vec_/ (mjr_vec_* d (* 6.67428L-11 (mi rad1) (mi rad2))) (mjr_vec_norm-two-squared d)))))
  (let* ((p1  #(0  1000 0))
         (r1  1000)
         (p2  #(0 -1000 0))
         (r2  1000)
         (p0  #(0     0 0))
         (r0  (* r1 (expt 2 1/3))))
    (labels ((bl (x)                                       ;; nil if vector is inside of any sphere
               (and (> (mjr_vec_norm-two (mjr_vec_- x p0)) (+ r0 10))
                    (> (mjr_vec_norm-two (mjr_vec_- x p1)) (+ r1 10))
                    (> (mjr_vec_norm-two (mjr_vec_- x p2)) (+ r2 10))))
             (f1 (x) (if (bl x) (f p0 r0 x 10) #(0 0 0)))  ;; Force vector 1 sphere
             (f2 (x) (if (bl x)                            ;; Force vector 2 spheres
                         (mjr_vec_+ (f p1 r1 x 10) (f p2 r2 x 10))
                         #(0 0 0))))

      (let ((daData (mjr_dquad_make-from-axis "x" '(:start -3000 :end 3000.0 :len 60)
                                              "y" '(:start -3000 :end 3000.0 :len 60)
                                              "z" '(:start     0 :end 3000.0 :len 60))))

        (print "Compute 1sph...")
        (mjr_dquad_add-data-from-map daData
                                     #'f1
                                     :axes 't
                                     :ano-nam "1sph"
                                     :ano-typ :ano-typ-rvec
                                     :arg-mode :arg-vector)

        (print "Compute 2sph...")
        (mjr_dquad_add-data-from-map daData
                                     #'f2
                                     :axes 't
                                     :ano-nam "2sph"
                                     :ano-typ :ano-typ-rvec
                                     :arg-mode :arg-vector)
        (print "Dumping VTK...")
        (mjr_vtk_from-dquad "exp-Gravity3D-OUT.vtk" daData)))))
             
                             
