version 16

/*==============================================================================
DO FILE NAME:			baseline tables
PROJECT:				Gout OpenSAFELY project
DATE: 					01/12/2022
AUTHOR:					M Russell / J Galloway												
DESCRIPTION OF FILE:	baseline tables
DATASETS USED:			main data file
DATASETS CREATED: 		tables
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

**Set filepaths
global projectdir `c(pwd)'

capture mkdir "$projectdir/output/data"
capture mkdir "$projectdir/output/tables"
capture mkdir "$projectdir/output/figures"

global logdir "$projectdir/logs"

**Open a log file
cap log close
log using "$logdir/descriptive_tables.log", replace

**Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

set scheme plotplainblind

**Set index dates ===========================================================*/
global year_preceding = "01/03/2014"
global start_date = "01/03/2015"
global end_date = "01/03/2024"

*Diagnostic incidence======================================================================*/

**Use cleaned data from previous step
use "$projectdir/output/data/file_gout_all.dta", clear

set type double

**Total number of gout patients within study dates
tab gout_code

**Verify that all diagnoses were in study windows
tab mo_year_diagn, missing
tab diagnosis_year, missing

**Verify that all first ULT scripts were in study windows
tab mo_year_ult, missing
tab ult_year, missing

*Table of gout diagnostic incidences by year (total/male/female) - denominator = mid-period TPP population who had >12m of registration
preserve
collapse (count) total_diag=gout_code, by(diagnosis_year sex) 
decode diagnosis_year, gen(year_str)
destring year_str, gen(year)
drop diagnosis_year year_str

**Merge in yearly population (denominator)
merge m:1 sex year using "$projectdir/output/data/gout_incidence_sex_long", keep(match) nogen
drop date 
sort year

**Calculate counts/population for combined male and female
expand=2, gen(copy)
replace sex = "All" if copy==1
bys year: replace total_diag = sum(total_diag) if copy==1
bys year (sex total_diag): gen n=_n if copy==1
drop if n==1
drop n copy
replace pop_inc = pop_inc_all if sex=="All"
drop pop_inc_all

**Round to nearest 5
foreach var of varlist total_diag pop_inc {
	gen `var'_round=round(`var', 5)
	drop `var'
}

**Generate incidences by year using yearly denominator
gen incidence_gout=((total_diag_round/pop_inc_round)*1000)
export delimited using "$projectdir/output/tables/incidence_year_rounded.csv", replace

twoway connected incidence_gout year if sex=="All", ytitle("Yearly incidence of gout diagnoses per 1,000 adult population", size(small)) color(gold) || connected incidence_gout year if sex=="M", color(blue) || connected incidence_gout year if sex=="F", yscale(range(0(0.5)3.5)) ylabel(0 "0" 0.5 "0.5" 1 "1.0" 1.5 "1.5" 2 "2.0" 2.5 "2.5" 3 "3.0" 3.5 "3.5", nogrid) color(red) xline(2020) xscale(range(2015(1)2023)) xlabel(2015 "Mar 2015" 2016 "Mar 2016" 2017 "Mar 2017" 2018 "Mar 2018" 2019 "Mar 2019" 2020 "Mar 2020" 2021 "Mar 2021" 2022 "Mar 2022" 2023 "Mar 2023", nogrid) xtitle("Year commencing", size(small) margin(medsmall)) title("", size(small)) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(incidence_year_rounded, replace) saving("$projectdir/output/figures/incidence_year_rounded.gph", replace)
	graph export "$projectdir/output/figures/incidence_year_rounded.svg", width(12in) replace

restore

*Graph of gout diagnotic incidence by month (all/male/female) - denominator = as above
preserve
collapse (count) total_diag=gout_code, by(mo_year_diagn sex) 
gen year = year(dofm(mo_year_diagn))
gen month = month(dofm(mo_year_diagn))
replace year = (year-1) if inlist(month,1,2)

**Merge in yearly population (denominator)
merge m:1 sex year using "$projectdir/output/data/gout_incidence_sex_long", keep(match) nogen
drop date month
sort mo_year_diagn

**Calculate counts/population for combined male and female
expand=2, gen(copy)
replace sex = "All" if copy==1
bys mo_year_diagn: replace total_diag = sum(total_diag) if copy==1
bys mo_year_diagn (sex total_diag): gen n=_n if copy==1
drop if n==1
drop n copy
replace pop_inc = pop_inc_all if sex=="All"
drop pop_inc_all

**Round to nearest 5
foreach var of varlist total_diag pop_inc {
	gen `var'_round=round(`var', 5)
	drop `var'
}

**Generate incidences by month using yearly denominator
gen incidence_gout=((total_diag_round/pop_inc_round)*1000)
sort mo_year_diagn
export delimited using "$projectdir/output/tables/incidence_month_rounded.csv", replace

twoway connected incidence_gout mo_year_diagn if sex=="All", ytitle("Monthly incidence of gout diagnoses per 1,000 adult population", size(small)) color(gold) || connected incidence_gout mo_year_diagn if sex=="M", color(blue) || connected incidence_gout mo_year_diagn if sex=="F", color(red) xline(723) yscale(range(0(0.1)0.4)) ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4", nogrid) xscale(range(660(12)780)) xlabel(660 "2015" 672 "2016" 684 "2017" 696 "2018" 708 "2019" 720 "2020" 732 "2021" 744 "2022" 756 "2023" 768 "2024" 780 "2025", nogrid) xtitle("Date of diagnosis", size(small) margin(medsmall)) title("", size(small)) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(incidence_month_rounded, replace) saving("$projectdir/output/figures/incidence_month_rounded.gph", replace)
	graph export "$projectdir/output/figures/incidence_month_rounded.svg", width(12in) replace
restore	

*Graph of gout diagnostic prevalence by year (all/male/female) - denominator = mid-year TPP population
preserve 
use "$projectdir/output/data/gout_prevalence_sex_long", clear

set type double

**Calculate counts/population for combined male and female
expand=2, gen(copy)
replace sex = "All" if copy==1
replace prev_gout = prev_gout_all if sex=="All"
replace pop = pop_all if sex=="All"
bys year (sex prev_gout): gen n=_n if sex=="All"
drop if n==1
drop n copy
drop pop_all prev_gout_all

**Round to nearest 5
foreach var of varlist prev_gout pop {
	gen `var'_round=round(`var', 5)
	drop `var'
}

**Generate prevalences by year
gen prevalence_gout=((prev_gout_round/pop_round)*100) //as a %

export delimited using "$projectdir/output/tables/prevalance_year_rounded.csv", replace	

twoway connected prevalence_gout year if sex=="All", ytitle("Gout prevalence (%)", size(small)) color(gold) || connected prevalence_gout year if sex=="M", ytitle("Gout prevalence (%)", size(small)) color(blue) || connected prevalence_gout year if sex=="F", ytitle("Gout prevalence (%)", size(small)) color(red) yscale(range(0(1)6)) ylabel(0(1)6, nogrid) xline(2020) xscale(range(2015(1)2023)) xlabel(2015 "Mar 2015" 2016 "Mar 2016" 2017 "Mar 2017" 2018 "Mar 2018" 2019 "Mar 2019" 2020 "Mar 2020" 2021 "Mar 2021" 2022 "Mar 2022" 2023 "Mar 2023", nogrid) xtitle("Year commencing", size(small) margin(medsmall)) title("", size(small)) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(prevalance_year_rounded, replace) saving("$projectdir/output/figures/prevalance_year_rounded.gph", replace)
	graph export "$projectdir/output/figures/prevalance_year_rounded.svg", width(12in) replace
restore	

*Graph of gout admissions incidence by year (all/male/female) - denominator = mid-period TPP population (as per prevalence); admission numbers are from April to April
preserve 
use "$projectdir/output/data/gout_admissions_sex_long", clear

set type double

**Calculate counts/population for combined male and female
expand=2, gen(copy)
replace sex = "All" if copy==1
replace gout_admission = gout_admission_all if sex=="All"
replace pop = pop_all if sex=="All"
bys year (sex gout_admission): gen n=_n if sex=="All"
drop if n==1
drop n copy
drop pop_all gout_admission_all

**Round to nearest 5
foreach var of varlist gout_admission pop {
	gen `var'_round=round(`var', 5)
	drop `var'
}

**Generate admission incidence by year
gen incident_gout_adm=((gout_admission_round/pop_round)*100000) //as a %

keep if date>=date("01/04/2016", "DMY") & date<date("01/04/2023", "DMY") & date!=. //admission data available from April 2016 

export delimited using "$projectdir/output/tables/incidence_admission_year_rounded.csv", replace	

twoway connected incident_gout_adm year if sex=="All", ytitle("Incidence of gout admissions per 100,000 adult population", size(small)) color(gold) || connected incident_gout_adm year if sex=="M", color(blue) || connected incident_gout_adm year if sex=="F", color(red) yscale(range(0(5)25)) ylabel(0(5)25, nogrid) xline(2020) xlabel(2016 "Apr 2016" 2017 "Apr 2017" 2018 "Apr 2018" 2019 "Apr 2019" 2020 "Apr 2020" 2021 "Apr 2021" 2022 "Apr 2022", nogrid) xscale(range(2016(1)2022)) xtitle("Year commencing", size(small) margin(medsmall)) title("", size(small)) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(incidence_admission_year_rounded, replace) saving("$projectdir/output/figures/incidence_admission_year_rounded.gph", replace)
	graph export "$projectdir/output/figures/incidence_admission_year_rounded.svg", width(12in) replace
restore	

*Graph of gout admissions incidence by month (all/male/female) - denominator = mid-period TPP population (as per prevalence)
preserve
use "$projectdir/output/measures/gout_admissions.dta", clear

set type double

collapse (count) total_adm=adm_count, by(gout_adm_ym sex) 

gen year = year(dofm(gout_adm_ym))
gen month = month(dofm(gout_adm_ym))
replace year = (year-1) if inlist(month,1,2)

**Merge in yearly population (denominator)
merge m:m sex year using "$projectdir/output/data/gout_admissions_sex_long", keep(match) nogen
drop date gout_admission gout_admission_all month
sort gout_adm_ym

**Calculate counts/population for combined male and female
expand=2, gen(copy)
replace sex = "All" if copy==1
bys gout_adm_ym: replace total_adm = sum(total_adm) if copy==1
bys gout_adm_ym (sex total_adm): gen n=_n if copy==1
drop if n==1
drop n copy
replace pop = pop_all if sex=="All"
drop pop_all

**Round to nearest 5
foreach var of varlist total_adm pop {
	gen `var'_round=round(`var', 5)
	drop `var'
}

**Generate incidences by month using yearly denominator
gen incidence_adm=((total_adm_round/pop_round)*100000)
sort gout_adm_ym

keep if gout_adm_ym>=ym(2016, 4) & gout_adm_ym<=ym(2023, 12) & gout_adm_ym!=. //admission data available from April 2016; restrict to before Dec 2022 for now

export delimited using "$projectdir/output/tables/admission_month_rounded.csv", replace

twoway connected incidence_adm gout_adm_ym if sex=="All", ytitle("Monthly incidence of gout admissions per 100,000 adult population", size(small)) color(gold) || connected incidence_adm gout_adm_ym if sex=="M", color(blue) || connected incidence_adm gout_adm_ym if sex=="F", color(red) xline(723) yscale(range(0(0.5)2.5)) ylabel(0 "0" 0.5 "0.5" 1 "1.0" 1.5 "1.5" 2 "2.0" 2.5 "2.5", nogrid) xscale(range(672(12)768)) xlabel(672 "2016" 684 "2017" 696 "2018" 708 "2019" 720 "2020" 732 "2021" 744 "2022" 756 "2023" 768 "2024", nogrid) xtitle("Date of admission", size(small) margin(medsmall)) title("", size(small)) legend(region(fcolor(white%0)) order(1 "All" 2 "Male" 3 "Female")) name(admission_month_rounded, replace) saving("$projectdir/output/figures/admission_month_rounded.gph", replace)
	graph export "$projectdir/output/figures/admission_month_rounded.svg", width(12in) replace
restore	


/*Baseline tables=====================================================================================*/

**Demographics
tabstat age, stats (n mean sd)
tab agegroup, missing
tab male, missing
tab ethnicity, missing
tab imd, missing
tab nuts_region, missing

**Comorbidities
tab smoke, missing
tabstat bmi_val, stats (n mean p50 p25 p75)
tab bmicat, missing
tabstat creatinine_val, stats (n mean p50 p25 p75)
tabstat egfr, stats (n mean p50 p25 p75)
tab egfr_cat, missing
tab egfr_cat_nomiss, missing
tab esrf, missing
tab ckd, missing //combination of creatinine and esrf codes
tab diabetes, missing 
tabstat hba1c_percentage_val, stats (n mean p50 p25 p75)
tabstat hba1c_mmol_per_mol_val, stats (n mean p50 p25 p75)
tabstat hba1c_pct, stats (n mean p50 p25 p75) //with conversion of mmol values
tab hba1ccat, missing
tabstat hba1c_mmol, stats (n mean p50 p25 p75) //with conversion of % values
tab hba1ccatmm, missing
tab diabcatm, missing //on basis of converted %
tab cancer, missing //lung, haem or other cancer
tab hypertension, missing
tab stroke, missing
tab chronic_resp_disease, missing
tab copd, missing
tab chronic_liver_disease, missing
tab chronic_card_disease, missing
tab diuretic, missing
tab tophus, missing
tab multiple_flares, missing
tabstat flare_count, stats (n mean p50 p25 p75)
tab high_risk, missing

*Baseline table overall
table1_mc, onecol nospacelowpercent iqrmiddle(",")  ///
	vars(agegroup cat %5.1f \ ///
		 male bin %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 bmicat cat %5.1f \ ///
		 smoke cat %5.1f \ ///
		 hypertension bin %5.1f \ ///
		 diabcatm cat %5.1f \ ///
		 chronic_card_disease bin %5.1f \ /// 
		 stroke bin %5.1f \ ///
		 cancer bin %5.1f \ ///
		 chronic_resp_disease bin  %5.1f \ ///
		 chronic_liver_disease bin %5.1f \ ///
		 ckd bin %5.1f \ ///
		 diuretic bin %5.1f \ ///
		 tophus bin %5.1f \ ///
		 multiple_flares bin %5.1f \ ///
		 high_risk bin %5.1f \ ///
		 baseline_urate conts %3.1f \ ///
		 ) saving("$projectdir/output/tables/baseline_bydiagnosis.xls", replace)
		 
*Rounded baseline table
*table (var) (diagnosis_year), stat(fvfrequency agegroup male ethnicity imd bmicat smoke hypertension diabcatm chronic_card_disease stroke cancer chronic_resp_disease chronic_liver_disease ckd diuretic tophus multiple_flares high_risk) missing

*Baseline table by year of diagnosis
table1_mc, by(diagnosis_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(agegroup cat %5.1f \ ///
		 male bin %5.1f \ ///
		 ethnicity cat %5.1f \ ///
		 imd cat %5.1f \ ///
		 bmicat cat %5.1f \ ///
		 smoke cat %5.1f \ ///
		 hypertension bin %5.1f \ ///
		 diabcatm cat %5.1f \ ///
		 chronic_card_disease bin %5.1f \ /// 
		 stroke bin %5.1f \ ///
		 cancer bin %5.1f \ ///
		 chronic_resp_disease bin  %5.1f \ ///
		 chronic_liver_disease bin %5.1f \ ///
		 ckd bin %5.1f \ ///
		 diuretic bin %5.1f \ ///
		 tophus bin %5.1f \ ///
		 multiple_flares bin %5.1f \ ///
		 high_risk bin %5.1f \ ///
		 baseline_urate conts %3.1f \ ///
		 ) saving("$projectdir/output/tables/baseline_byyear.xls", replace)

*Follow-up=======================================================================================================*/

**Proportion of patients with at least 6/12 months of registration after diagnosis 
tab has_6m_follow_up, missing
tab has_12m_follow_up, missing
tab mo_year_diagn has_6m_follow_up, row
tab mo_year_diagn has_12m_follow_up, row
tab mo_year_diagn has_6m_post_diag, row
tab mo_year_diagn has_12m_post_diag, row

*ULT prescriptions===============================================================================================*/

**Proportion with a prescription for ULT within 6m of diagnosis
tab ult_6m, missing
tab ult_6m if has_6m_post_diag==1, missing //for those with at least 6m of available follow-up
tab ult_6m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

**Proportion with a prescription for ULT within 12m of diagnosis
tab ult_12m, missing
tab ult_12m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

**Proportion with a prescription for allopurinol within 6m of diagnosis
tab allo_6m, missing
tab allo_6m if has_6m_post_diag==1, missing //for those with at least 6m of available follow-up
tab allo_6m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

**Proportion with a prescription for allopurinol within 12m of diagnosis
tab allo_12m, missing
tab allo_12m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

**Proportion with a prescription for febuxostat within 6m of diagnosis
tab febux_6m, missing
tab febux_6m if has_6m_post_diag==1, missing //for those with at least 6m of available follow-up
tab febux_6m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

**Proportion with a prescription for febuxostat within 12m of diagnosis
tab febux_12m, missing
tab febux_12m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up

*ULT prescriptions in context of additional risk factors=============================================================*/

**CKD
foreach var of varlist tophi ckd diuretic multiple_flares high_risk {
**ULT within 6m 
bys `var': tab ult_6m, missing
**ULT within 6m for those with at least 6m of available follow-up
bys `var': tab ult_6m if has_6m_post_diag==1, missing 
**ULT within 12m 
bys `var': tab ult_12m, missing
**ULT within 12m for those with at least 12m of available follow-up
bys `var': tab ult_12m if has_12m_post_diag==1, missing //for those with at least 12m of available follow-up
}

foreach x in "6m" "12m" { 
*ULT standards, by year (for those with at least 6m/12m follow-up after diagnosis)
table1_mc if has_`x'_post_diag==1, by(diagnosis_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(ult_`x' cat %3.1f \ ///
		 allo_`x' cat %3.1f \ ///
		 febux_`x' cat %3.1f \ ///
		 had_baseline_urate cat %3.1f \ ///
		 baseline_urate conts %3.1f \ ///
		 ) saving("$projectdir/output/tables/ult`x'_byyear.xls", replace) 
		 
*ULT standards, by region (for those with at least 6m/12m follow-up after diagnosis)
table1_mc if nuts_region!=. & has_`x'_post_diag==1, by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(ult_`x' cat %3.1f \ ///
		 allo_`x' cat %3.1f \ ///
		 febux_`x' cat %3.1f \ ///
		 had_baseline_urate cat %3.1f \ ///
		 baseline_urate conts %3.1f \ ///
		 ) saving("$projectdir/output/tables/ult`x'_byregion.xls", replace)
}		 

*ULT standards, by region and year (for those with at least 6m follow-up after diagnosis) - boxplot
table1_mc if nuts_region!=. & has_6m_post_diag==1 & (diagnosis_year>=5 & diagnosis_year!=.), by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(ult_time cat %3.1f \ ///
		 ult_time_19 cat %3.1f \ ///
		 ult_time_20 cat %3.1f \ ///
		 ult_time_21 cat %3.1f \ ///
		 ult_time_22 cat %3.1f \ ///
		 ult_time_23 cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/ult_byyearandregion.xls", replace)
		 
*Urate attainment within 6m of ULT, by region and year (for those with at least 6m follow-up after ULT) - boxplot
table1_mc if nuts_region!=. & has_6m_post_ult==1 & ult_6m==1 & (ult_year>=5 & ult_year!=.), by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(urate_6m_ult_time cat %3.1f \ ///
		 urate_6m_ult_time_19 cat %3.1f \ ///
		 urate_6m_ult_time_20 cat %3.1f \ ///
		 urate_6m_ult_time_21 cat %3.1f \ ///
		 urate_6m_ult_time_22 cat %3.1f \ ///
		 urate_6m_ult_time_23 cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate_6m_ult_byyearandregion.xls", replace)	

*Urate attainment within 12m of ULT, by region and year (for those with at least 12m follow-up after ULT) - boxplot
table1_mc if nuts_region!=. & has_12m_post_ult==1 & ult_6m==1 & (ult_year>=5 & ult_year<=8 & ult_year!=.), by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(urate_12m_ult_time cat %3.1f \ ///
		 urate_12m_ult_time_19 cat %3.1f \ ///
		 urate_12m_ult_time_20 cat %3.1f \ ///
		 urate_12m_ult_time_21 cat %3.1f \ ///
		 urate_12m_ult_time_22 cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate_12m_ult_byyearandregion.xls", replace)
		 
*First ULT drug===================================================================================================*/

*If ULT within 6m of diagnosis
tab first_ult_drug_6m, missing
tab first_ult_drug_6m if has_6m_post_diag==1, missing
tab first_ult_drug_6m if has_6m_post_diag==1 & ult_6m==1, missing

*If ULT within 12m of diagnosis
tab first_ult_drug_12m, missing
tab first_ult_drug_12m if has_12m_post_diag==1, missing
tab first_ult_drug_12m if has_12m_post_diag==1 & ult_12m==1, missing

*Baseline urate==================================================================================================*/

**Define baseline serum urate level as urate level closest to index diagnosis date (must be within 6m before/after diagnosis and before ULT commencement)
tab had_baseline_urate, missing
tabstat baseline_urate, stats(n mean p50 p25 p75)
tab baseline_urate_below360, missing
tab baseline_urate_below360 if baseline_urate!=., missing //of those who had a baseline urate performed

*Urate target attainment following ULT commencement=========================================================================================*/

**Proportion of patients with >6m/12m of registration and follow-up after first ULT prescription, assuming first prescription was within 6m of diagnosis
tab has_6m_post_ult, missing
tab has_6m_post_ult if ult_6m==1, missing //of those who had ULT within 6m
tab has_6m_post_ult if ult_6m==1 & has_6m_post_diag==1, missing //of those who had ULT within 6m
tab has_12m_post_ult, missing 
tab has_12m_post_ult if ult_6m==1, missing //of those who had ULT within 6m
tab has_12m_post_ult if ult_6m==1 & has_12m_post_diag==1, missing //of those who had ULT within 6m 
 
**6 months (must have 6m of follow-up post-ULT)
tab ult_6m, missing //those who received ULT within 6m of diagnosis
tab has_6m_post_ult if ult_6m==1 & has_6m_post_diag==1, missing //proportion receiving ULT within 6m who had at least 6m of registration and follow-up after first ULT prescription
tab had_test_ult_6m if has_6m_post_ult==1, missing //proportion receiving ULT with >6m follow-up, who had a least one test performed within 6m
tabstat lowest_urate_ult_6m if has_6m_post_ult==1, stats(n mean p50 p25 p75) //lowest urate value within 6m of ULT
tab urate_below360_ult_6m if has_6m_post_ult==1, missing //proportion who attained <360 micromol/L from those who received ULT within 6m and had >6m of follow-up
tab urate_below360_ult_6m_fup, missing //should be same as above
tab urate_below360_ult_6m if has_6m_post_ult==1 & had_test_ult_6m==1, missing //proportion who attained <360 micromol/L from those who received ULT within 6m, had >6m of follow-up, and had a test performed within 6m of ULT

**12 months (must have 12m of follow-up post-ULT)
tab ult_6m, missing //those who received ULT within 6m of diagnosis
tab has_12m_post_ult if ult_6m==1 & has_12m_post_diag==1, missing //proportion receiving ULT within 6m who had at least 12m of registration and follow-up after first ULT prescription
tab had_test_ult_12m if has_12m_post_ult==1, missing //proportion receiving ULT with >6m follow-up, who had a least one test performed within 12m
tabstat lowest_urate_ult_12m if has_12m_post_ult==1, stats(n mean p50 p25 p75) //lowest urate value within 12m of ULT
tab urate_below360_ult_12m if has_12m_post_ult==1, missing //proportion who attained <360 micromol/L from those who received ULT within 6m and had >12m of follow-up
tab urate_below360_ult_12m_fup, missing //should be same as above
tab urate_below360_ult_12m if has_12m_post_ult==1 & had_test_ult_12m==1, missing //proportion who attained <360 micromol/L from those who received ULT within 6m, had >12m of follow-up, and had a test performed within 12m of ULT

*Urate target attainment within 6m/12m of diagnosis; i.e. irrespective of ULT===================================================================*/

**Proportion of patients with >6/12m of follow-up after diagnosis
tab has_6m_post_diag, missing
tab has_12m_post_diag, missing

**6 months (must have 6m of follow-up after diagnosis)
tab has_6m_post_diag, missing //proportion who had at least 6m of registration and follow-up after diagnosis
tab had_test_6m if has_6m_post_diag==1, missing //proportion with >6m follow-up who had a least one test performed within 6m
tabstat lowest_urate_6m if has_6m_post_diag==1, stats(n mean p50 p25 p75) //lowest urate value within 6m 
tab urate_below360_6m if has_6m_post_diag==1, missing //proportion who attained <360 micromol/L with 6m of diagnosis
tab urate_below360_6m if has_6m_post_diag==1 & had_test_6m==1, missing //proportion who attained <360 micromol/L from those who had >6m of follow-up and had a test performed within 6m of diagnosis

**12 months 
tab has_12m_post_diag, missing //proportion who had at least 12m of registration and follow-up after diagnosis
tab had_test_12m if has_12m_post_diag==1, missing //proportion with >12m follow-up who had a least one test performed within 12m
tabstat lowest_urate_12m if has_12m_post_diag==1, stats(n mean p50 p25 p75) //lowest urate value within 12m 
tab urate_below360_12m if has_12m_post_diag==1, missing //proportion who attained <360 micromol/L with 12m of diagnosis
tab urate_below360_12m if has_12m_post_diag==1 & had_test_12m==1, missing //proportion who attained <360 micromol/L from those who had >12m of follow-up and had a test performed within 12m of diagnosis

*Number of urate levels perfomred within 6m/12m of ULT initiation=========================================================*/

**6 months
tabstat count_urate_ult_6m if has_6m_post_ult==1, stats(n mean p50 p25 p75) //number of tests performed within 6m of ULT initiation
tab two_urate_ult_6m if has_6m_post_ult==1, missing //two or more urate tests performed within 6m of ULT initiation

**12 months
tabstat count_urate_ult_12m if has_12m_post_ult==1, stats(n mean p50 p25 p75) //number of tests performed within 12m of ULT initiation
tab two_urate_ult_12m if has_12m_post_ult==1, missing //two or more urate tests performed within 12m of ULT initiation

*====================================================================================================================*/  

foreach x in "6m" "12m" { 
*Urate standards, by year (for those with at least 6m/12m follow-up; irrespective of ULT)
table1_mc if has_`x'_post_diag==1, by(diagnosis_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(had_test_`x' cat %3.1f \ ///
		 lowest_urate_`x' conts %3.1f \ ///
		 urate_below360_`x' cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate`x'_byyear_diag.xls", replace) 
		 
*Urate standards, by region (for those with at least 6m/12m follow-up; irrespective of ULT)
table1_mc if has_`x'_post_diag==1 & nuts_region!=., by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(had_test_`x' cat %3.1f \ ///
		 lowest_urate_`x' conts %3.1f \ ///
		 urate_below360_`x' cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate`x'_byregion_diag.xls", replace)	
		 
*Urate standards, by year (for those with at least 6m/12m follow-up and had a test performed; irrespective of ULT)
table1_mc if has_`x'_post_diag==1 & had_test_`x'==1, by(diagnosis_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(lowest_urate_`x' conts %3.1f \ ///
		 urate_below360_`x' cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate`x'_byyear_diag_test.xls", replace) 
		 
*Urate standards, by region (for those with at least 6m/12m follow-up and had a test performed; irrespective of ULT)
table1_mc if has_`x'_post_diag==1 & had_test_`x'==1 & nuts_region!=., by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(lowest_urate_`x' conts %3.1f \ ///
		 urate_below360_`x' cat %3.1f \ ///
		 ) saving("$projectdir/output/tables/urate`x'_byregion_diag_test.xls", replace)	 
		 
*Urate standards, by year (for those with at least 6m/12m follow-up after ULT) - Note - this is by ULT year, not diagnosis year
table1_mc if ult_6m==1 & has_`x'_post_ult==1, by(ult_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(had_test_ult_`x' cat %3.1f \ ///
		 lowest_urate_ult_`x' conts %3.1f \ ///
		 urate_below360_ult_`x' cat %3.1f \ /// 
		 count_urate_ult_`x' conts %3.1f \ ///
		 two_urate_ult_`x' cat %3.1f \ /// 
		 ) saving("$projectdir/output/tables/urate`x'_byyear_ult.xls", replace) 
		 
*Urate standards, by region (for those with at least 6m/12m follow-up after ULT)
table1_mc if ult_6m==1 & has_`x'_post_ult==1 & nuts_region!=., by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(had_test_ult_`x' cat %3.1f \ ///
		 lowest_urate_ult_`x' conts %3.1f \ ///
		 urate_below360_ult_`x' cat %3.1f \ /// 
		 count_urate_ult_`x' conts %3.1f \ ///
		 two_urate_ult_`x' cat %3.1f \ /// 
		 ) saving("$projectdir/output/tables/urate`x'_byregion_ult.xls", replace)
		 
*Urate standards, by ULT year (for those with at least 6m/12m follow-up after ULT, and had a test performed) - 
table1_mc if ult_6m==1 & has_`x'_post_ult==1 & had_test_ult_`x'==1, by(ult_year) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(lowest_urate_ult_`x' conts %3.1f \ ///
		 urate_below360_ult_`x' cat %3.1f \ /// 
		 count_urate_ult_`x' conts %3.1f \ ///
		 two_urate_ult_`x' cat %3.1f \ /// 
		 ) saving("$projectdir/output/tables/urate`x'_byyear_ult_test.xls", replace) 
		 
*Urate standards, by region (for those with at least 6m/12m follow-up after ULT, and had a test performed)
table1_mc if ult_6m==1 & has_`x'_post_ult==1 & had_test_ult_`x'==1 & nuts_region!=., by(nuts_region) total(before) onecol nospacelowpercent iqrmiddle(",")  ///
	vars(lowest_urate_ult_`x' conts %3.1f \ ///
		 urate_below360_ult_`x' cat %3.1f \ /// 
		 count_urate_ult_`x' conts %3.1f \ ///
		 two_urate_ult_`x' cat %3.1f \ /// 
		 ) saving("$projectdir/output/tables/urate`x'_byregion_ult_test.xls", replace)		 
}
		 
*Output tables as CSVs================================================================================================*/		 

import excel "$projectdir/output/tables/baseline_bydiagnosis.xls", clear
outsheet * using "$projectdir/output/tables/baseline_bydiagnosis.csv" , comma nonames replace	

import excel "$projectdir/output/tables/baseline_byyear.xls", clear
outsheet * using "$projectdir/output/tables/baseline_byyear.csv" , comma nonames replace		 

foreach x in "6m" "12m" {
	
import excel "$projectdir/output/tables/ult`x'_byyear.xls", clear
outsheet * using "$projectdir/output/tables/ult`x'_byyear.csv" , comma nonames replace	

import excel "$projectdir/output/tables/ult`x'_byregion.xls", clear
outsheet * using "$projectdir/output/tables/ult`x'_byregion.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byyear_diag.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byyear_diag.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byregion_diag.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byregion_diag.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byyear_diag_test.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byyear_diag_test.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byregion_diag_test.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byregion_diag_test.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byyear_ult.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byyear_ult.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byregion_ult.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byregion_ult.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byyear_ult_test.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byyear_ult_test.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate`x'_byregion_ult_test.xls", clear
outsheet * using "$projectdir/output/tables/urate`x'_byregion_ult_test.csv" , comma nonames replace	
}

import excel "$projectdir/output/tables/ult_byyearandregion.xls", clear
outsheet * using "$projectdir/output/tables/ult_byyearandregion.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate_6m_ult_byyearandregion.xls", clear
outsheet * using "$projectdir/output/tables/urate_6m_ult_byyearandregion.csv" , comma nonames replace	

import excel "$projectdir/output/tables/urate_12m_ult_byyearandregion.xls", clear
outsheet * using "$projectdir/output/tables/urate_12m_ult_byyearandregion.csv" , comma nonames replace

log close