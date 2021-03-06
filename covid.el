;;; covid.el --- A covid case calculation tool using live WHO Data  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Philip Beadling

;; Author: Philip Beadling <phil@beadling.co.uk>
;; Maintainer: Philip Beadling <phil@beadling.co.uk>
;; Created: 14 Nov 2020
;; Modified: 14 Nov 2020
;; Version: 1.0
;; Package-Requires: ((emacs "26.3"))
;; Keywords: data covid corona
;; URL: https://github.com/falloutphil/covid
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;; Calculates per-country 14 and 7 day cumulative new cases from WHO data,
;; and presents this data in tables and plots for a given date range.
;; Optionally plot data using gnuplot if org-plot/gnuplot is installed.

;;; Code:
(require 'org)
(require 'map)

;; Static taken from ECDC daily covid data
(defvar covid-country-population-alist
  '(("Afghanistan" . 38041757)
    ("Albania" . 2862427)
    ("Algeria" . 43053054)
    ("Andorra" . 76177)
    ("Angola" . 31825299)
    ("Anguilla" . 14872)
    ("Antigua and Barbuda" . 97115)
    ("Argentina" . 44780675)
    ("Armenia" . 2957728)
    ("Aruba" . 106310)
    ("Australia" . 25203200)
    ("Austria" . 8858775)
    ("Azerbaijan" . 10047719)
    ("Bahamas" . 389486)
    ("Bahrain" . 1641164)
    ("Bangladesh" . 163046173)
    ("Barbados" . 287021)
    ("Belarus" . 9452409)
    ("Belgium" . 11455519)
    ("Belize" . 390351)
    ("Benin" . 11801151)
    ("Bermuda" . 62508)
    ("Bhutan" . 763094)
    ("Bolivia" . 11513102)
    ("Bonaire, Saint Eustatius and Saba" . 25983)
    ("Bosnia and Herzegovina" . 3300998)
    ("Botswana" . 2303703)
    ("Brazil" . 211049519)
    ("British Virgin Islands" . 30033)
    ("Brunei Darussalam" . 433296)
    ("Bulgaria" . 7000039)
    ("Burkina Faso" . 20321383)
    ("Burundi" . 11530577)
    ("Cambodia" . 16486542)
    ("Cameroon" . 25876387)
    ("Canada" . 37411038)
    ("Cape Verde" . 549936)
    ("Cayman Islands" . 64948)
    ("Central African Republic" . 4745179)
    ("Chad" . 15946882)
    ("Chile" . 18952035)
    ("China" . 1433783692)
    ("Colombia" . 50339443)
    ("Comoros" . 850891)
    ("Congo" . 5380504)
    ("Costa Rica" . 5047561)
    ("Cote dIvoire" . 25716554)
    ("Croatia" . 4076246)
    ("Cuba" . 11333484)
    ("CuraÃ§ao" . 163423)
    ("Cyprus" . 875899)
    ("Czechia" . 10649800)
    ("Democratic Republic of the Congo" . 86790568)
    ("Denmark" . 5806081)
    ("Djibouti" . 973557)
    ("Dominica" . 71808)
    ("Dominican Republic" . 10738957)
    ("Ecuador" . 17373657)
    ("Egypt" . 100388076)
    ("El Salvador" . 6453550)
    ("Equatorial Guinea" . 1355982)
    ("Eritrea" . 3497117)
    ("Estonia" . 1324820)
    ("Eswatini" . 1148133)
    ("Ethiopia" . 112078727)
    ("Falkland Islands (Malvinas)" . 3372)
    ("Faroe Islands" . 48677)
    ("Fiji" . 889955)
    ("Finland" . 5517919)
    ("France" . 67012883)
    ("French Polynesia" . 279285)
    ("Gabon" . 2172578)
    ("Gambia" . 2347696)
    ("Georgia" . 3996762)
    ("Germany" . 83019213)
    ("Ghana" . 30417858)
    ("Gibraltar" . 33706)
    ("Greece" . 10724599)
    ("Greenland" . 56660)
    ("Grenada" . 112002)
    ("Guam" . 167295)
    ("Guatemala" . 17581476)
    ("Guernsey" . 64468)
    ("Guinea" . 12771246)
    ("Guinea Bissau" . 1920917)
    ("Guyana" . 782775)
    ("Haiti" . 11263079)
    ("Holy See" . 815)
    ("Honduras" . 9746115)
    ("Hungary" . 9772756)
    ("Iceland" . 356991)
    ("India" . 1366417756)
    ("Indonesia" . 270625567)
    ("Iran" . 82913893)
    ("Iraq" . 39309789)
    ("Ireland" . 4904240)
    ("Isle of Man" . 84589)
    ("Israel" . 8519373)
    ("Italy" . 60359546)
    ("Jamaica" . 2948277)
    ("Japan" . 126860299)
    ("Jersey" . 107796)
    ("Jordan" . 10101697)
    ("Kazakhstan" . 18551428)
    ("Kenya" . 52573967)
    ("Kosovo" . 1798506)
    ("Kuwait" . 4207077)
    ("Kyrgyzstan" . 6415851)
    ("Laos" . 7169456)
    ("Latvia" . 1919968)
    ("Lebanon" . 6855709)
    ("Lesotho" . 2125267)
    ("Liberia" . 4937374)
    ("Libya" . 6777453)
    ("Liechtenstein" . 38378)
    ("Lithuania" . 2794184)
    ("Luxembourg" . 613894)
    ("Madagascar" . 26969306)
    ("Malawi" . 18628749)
    ("Malaysia" . 31949789)
    ("Maldives" . 530957)
    ("Mali" . 19658023)
    ("Malta" . 493559)
    ("Mauritania" . 4525698)
    ("Mauritius" . 1269670)
    ("Mexico" . 127575529)
    ("Moldova" . 4043258)
    ("Monaco" . 33085)
    ("Mongolia" . 3225166)
    ("Montenegro" . 622182)
    ("Montserrat" . 4991)
    ("Morocco" . 36471766)
    ("Mozambique" . 30366043)
    ("Myanmar" . 54045422)
    ("Namibia" . 2494524)
    ("Nepal" . 28608715)
    ("Netherlands" . 17282163)
    ("New Caledonia" . 282757)
    ("New Zealand" . 4783062)
    ("Nicaragua" . 6545503)
    ("Niger" . 23310719)
    ("Nigeria" . 200963603)
    ("North Macedonia" . 2077132)
    ("Northern Mariana Islands" . 57213)
    ("Norway" . 5328212)
    ("Oman" . 4974992)
    ("Pakistan" . 216565317)
    ("Palestine" . 4981422)
    ("Panama" . 4246440)
    ("Papua New Guinea" . 8776119)
    ("Paraguay" . 7044639)
    ("Peru" . 32510462)
    ("Philippines" . 108116622)
    ("Poland" . 37972812)
    ("Portugal" . 10276617)
    ("Puerto Rico" . 2933404)
    ("Qatar" . 2832071)
    ("Romania" . 19414458)
    ("Russia" . 145872260)
    ("Rwanda" . 12626938)
    ("Saint Kitts and Nevis" . 52834)
    ("Saint Lucia" . 182795)
    ("Saint Vincent and the Grenadines" . 110593)
    ("San Marino" . 34453)
    ("Sao Tome and Principe" . 215048)
    ("Saudi Arabia" . 34268529)
    ("Senegal" . 16296362)
    ("Serbia" . 6963764)
    ("Seychelles" . 97741)
    ("Sierra Leone" . 7813207)
    ("Singapore" . 5804343)
    ("Sint Maarten" . 42389)
    ("Slovakia" . 5450421)
    ("Slovenia" . 2080908)
    ("Somalia" . 15442906)
    ("South Africa" . 58558267)
    ("South Korea" . 51225321)
    ("South Sudan" . 11062114)
    ("Sri Lanka" . 21323734)
    ("Sudan" . 42813237)
    ("Suriname" . 581363)
    ("Sweden" . 10230185)
    ("Switzerland" . 8544527)
    ("Syria" . 17070132)
    ("Taiwan" . 23773881)
    ("Tajikistan" . 9321023)
    ("Thailand" . 69625581)
    ("Timor Leste" . 1293120)
    ("Togo" . 8082359)
    ("Trinidad and Tobago" . 1394969)
    ("Tunisia" . 11694721)
    ("Turkey" . 82003882)
    ("Turks and Caicos islands" . 38194)
    ("Uganda" . 44269587)
    ("Ukraine" . 43993643)
    ("United Arab Emirates" . 9770526)
    ("United Kingdom" . 66647112)
    ("United Republic of Tanzania" . 58005461)
    ("United States of America" . 329064917)
    ("United States Virgin Islands" . 104579)
    ("Uruguay" . 3461731)
    ("Uzbekistan" . 32981715)
    ("Venezuela" . 28515829)
    ("Vietnam" . 96462108)
    ("Western Sahara" . 582458)
    ("Yemen" . 29161922)
    ("Zambia" . 17861034)
    ("Zimbabwe" . 14645473)))
  
(defvar covid-country-list
  (map-keys covid-country-population-alist))

;;;###autoload
(defun covid-country-history (country start-date max-cases)
  "Helper function to get covid details from COUNTRY.  If POPULATION is non-zero this is used directly (eg to match ECDC numbers).  START-DATE dictates X-Axis start.  MAX-CASES dictates Y-Axis scale for ASCII plots."
  (interactive (list (ido-completing-read "Country? " covid-country-list)
		     (org-read-date nil nil nil "Plot Start Date? "
				    (org-time-string-to-time "2020-01-01"))
		     (read-number "Max Cases? " 1000)))
  (switch-to-buffer (format "%s covid" country))
  (org-mode)
  (url-handler-mode t)
  (insert-file-contents "http://covid19.who.int/WHO-COVID-19-global-data.csv")
  (move-end-of-line nil)
  (insert ",14 day,7 day,Max 7 day,Graph")
  (keep-lines country (point) (point-max))
  (org-table-convert-region (point-min) (point-max))
  (org-table-insert-hline)
  (insert (format "#+PLOT: title:\"Covid Cumulative Window New Cases In %s\" " country))
  ;; keep timefmt out of above nested format due to % clashes
  (insert "set:\"xdata time\" set:\"timefmt '%Y-%m-%d'\" ind:1 deps:(10) with:boxes\n")
  ;; order is important here xdata and timefmt must be declared before an xrange using date format
  (insert (format "#+PLOT: set:\"xrange ['%s':]\" set:\"xlabel 'Date'\" set:\"yrange [0:]\" set:\"ylabel 'Cases per 100,000'\"\n" start-date))
  (goto-char (point-max))
  (let ((p (/ 100000.0 (cdr (assoc country
				   covid-country-population-alist)))))
    ;; Zero data until last element of initial window, last element is then just copied (and scaled),
    ;; after that it's the difference between the last and first cumulative values in the window.
    (insert (format "#+TBLFM: @2$9..@14$9 = 0 :: @15$9 =  $6 * %f :: @16$9..@>$9 = ($6 - @-14$6) * %f :: @2$10..@7$10 = 0 :: @8$10 =  $6 * %f :: @9$10..@>$10 = ($6 - @-7$6) * %f :: @2$11 = 0 :: @3$11..@>$11 = vmax([$10 @-1]) :: $12 = '(orgtbl-uc-draw-grid $10 0 %d 40)"
		    p p p p max-cases)))
  (org-ctrl-c-ctrl-c)
  (org-ctrl-c-ctrl-c) ;recalc (twice or graph is missing?!)
  (goto-char (point-min))
  (when (require 'gnuplot nil 'noerror)
    (org-plot/gnuplot)))

(provide 'covid)
;;; covid.el ends here
