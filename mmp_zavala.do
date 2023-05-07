** MIGRATION & DEVELOPMENT INDIVIDUAL EMPIRICAL PROJECT
** MEGHAN ZAVALA

set more off
clear all

cd "/Users/meghanmattioli/OneDrive - UC San Diego/22 FALL/Migration & Development/Individual Empirical Project"

capture log close
log using MMP_log, replace

use "life174.dta", clear
gen id= commun + (hhnum*10000)
sort id
save "life174_id.dta", replace

use "mig174.dta", clear
gen id= commun + (hhnum*10000)
sort id
*All of our datasets have the variables COMMUN (comunity) and HHNUM (household number) in common. You need to create an ID with those two variables. The ID will follow this idea: COMMUN + (HHNUM*10000). COMMUN has 3 digits and HHNUM has 4; miltiply HHNUM by 10,000 and add it to COMMUN to obtain such ID. Then, sort both files by ID and merge them by ID.

merge 1:m id using "life174_id"
drop if (_merge==1 | _merge==2)
save "mig_life174.dta", replace

use "mig_life174.dta", clear
* need to drop duplicates to return to cross-sectional (1,342 unique observations)
keep if year==usyrl
sum usyrl

* drop observations without usyrl and whose last US trip was before 1986, drop women (small n), drop communities 1-71 (lack of marriage data)
drop if usyrl==9999
drop if usyrl < 1986
drop if sex==2
drop if commun<72
*only want to keep undoc and h2a for last US trip (usdocl = 3 or 8)
codebook usdocl
keep if (usdocl==3 |usdocl==8)
drop if uswagel==9999
drop if uswagel==8888
drop if hrwage==9999
drop if hrwage==8888
sum hrwage,d
drop if hrwage >65.64

* CREATE TREATMENT VARIABLE (h2a program or undoc)
gen h2a= 1 if usdocl==3
replace h2a=0 if usdocl!=3
tab h2a

* CREATE OUTCOME VARIABLES
* calculate cost of living by adding an individual migrant's monthly rent and food expenditures
replace rent=. if rent==9999
replace food=. if food==9999
gen costliv= rent + food
replace remit=. if remit==9999
gen formemp= 1 if howpaid==1
replace formemp=0 if howpaid==2
* social capital = 1 if "friends" or "very close" to an Anglo American, African American, or Asian American, or participation in sports or social organization on last US trip, else 0
gen soccap=1 if (blacks==3 | asians==3 | anglos==3 | sport==1 |social==1)
replace soccap=0 if soccap!=1
*language acquistion
gen langacq= 1 if (english==3 | english==4 | enghome==3 | enghome==4 | engwork==3 | engwork==4 |  engfrnd==3 | engfrnd==4 | engneig==3 | engneig==4)
replace langacq=0 if langacq!=1
* HEALTH OUTCOMES
gen hosp=1 if hospital==1
replace hosp=0 if hospital!=1
gen insurance=1 if (hlthpmt1==1 | hlthpmt1==2 | hlthpmt1==3 | hlthpmt2==1 | hlthpmt2==2 | hlthpmt2==3 | hlthpmt3==1 | hlthpmt3==2 | hlthpmt3==3 | hlthpmt4==1 | hlthpmt4==2 | hlthpmt4==3)
replace insurance=0 if insurance==.
gen poorhealth=1 if mxhealth==1
replace poorhealth=0 if mxhealth!=1

* COVARIATES
gen marriedlast=1 if usmarl==1
replace marriedlast=0 if usmarl==2
gen empsp=1 if (hrwages!=8888 & hrwages!=9999)
replace empsp=0 if hrwages==8888
replace edyrs=. if edyrs==9999
* migratory social capital = 1 if parent or sibling a US migrant during or prior to year of last US trip, else 0
replace sbmgyr1=. if sbmgyr1==9999 | sbmgyr1==8888
replace sbmgyr2=. if sbmgyr2==9999 | sbmgyr2==8888
replace sbmgyr3=. if sbmgyr3==9999 | sbmgyr3==8888
replace sbmgyr4=. if sbmgyr4==9999 | sbmgyr4==8888
replace sbmgyr5=. if sbmgyr5==9999 | sbmgyr5==8888
replace sbmgyr6=. if sbmgyr6==9999 | sbmgyr6==8888
replace sbmgyr7=. if sbmgyr7==9999 | sbmgyr7==8888
replace sbmgyr8=. if sbmgyr8==9999 | sbmgyr8==8888
replace sbmgyr9=. if sbmgyr9==9999 | sbmgyr9==8888
replace sbmgyr10=. if sbmgyr10==9999 | sbmgyr10==8888
replace sbmgyr11=. if sbmgyr11==9999 | sbmgyr11==8888
replace sbmgyr12=. if sbmgyr12==9999 | sbmgyr12==8888
replace momgyr=. if momgyr==9999 | momgyr==8888
replace famgyr=. if famgyr==9999 | famgyr==8888
gen migsoccap=1 if (usyrl>sbmgyr1 | usyrl>sbmgyr2 | usyrl>sbmgyr3 | usyrl>sbmgyr4 | usyrl>sbmgyr5 | usyrl>sbmgyr6 | usyrl>sbmgyr7 | usyrl>sbmgyr8 | usyrl>sbmgyr9 | usyrl>sbmgyr10 | usyrl>sbmgyr11 | usyrl>sbmgyr12 | usyrl>momgyr | usyrl>famgyr)
replace migsoccap=0 if migsoccap==.
br migsoccap usyrl momgyr famgyr sbmgyr1 sbmgyr2 sbmgyr3 sbmgyr4 sbmgyr5 sbmgyr6 sbmgyr7 sbmgyr8 sbmgyr9 sbmgyr10 sbmgyr11 sbmgyr12 usyrl famgyr 
* physical capital= 1 if migrant owned house, land, business during or prior to year of last US trip, else 0
gen physcap=1 if (property>0 | land>0 | business>0)
replace physcap=0 if physcap==.
save "miglife_clean.dta", replace

*Motivating figures
* year of last US trip by group
byhist usyrl, by(h2a) density  start(1986)
	
*create list
global list2 age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap hrwage savings costliv remit formemp soccap langacq hosp insurance poorhealth
*create Table1b with full data
estpost tabstat $list2, by(h2a) stat(mean sd) col(stat)
esttab . using summary_stats.rtf, cell((mean(fmt(%9.2f)) sd(fmt(%9.2f)))) not nostar unstack nomtitle nonote nolines nogaps plain compress label replace
 
* propensity score matching, nearest neighbor
* outcome vars: hrwage savings costliv remit // formemp soccap langacq
* covariates: h2a age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap

* RESULTS - ECONOMIC OUTCOMES
use "miglife_clean.dta", clear
eststo e1: teffects nnmatch (hrwage age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo e2: teffects nnmatch (savings age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo e3: teffects nnmatch (costliv age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables 
eststo e4: teffects nnmatch (remit age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables 
esttab e* using "economic_outcomes.doc", label brackets replace onecell compress nogaps star rtf mtitles title("Table 1: Economic Outcomes for H2A vs. Undocumented Migrant Workers") addnotes(Matching variables: age, married, spouse employed, total children born prior to or during last US trip, education, total months of US experience, total number of US migrations, migration social capital, and physical capital)

*SOCIAL OUTCOMES
eststo s1: teffects nnmatch (formemp age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo s2: teffects nnmatch (soccap age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo s3: teffects nnmatch (langacq age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables 
esttab s* using "social_outcomes.doc", label brackets replace onecell compress nogaps star rtf mtitles title("Table 2: Social Outcomes for H2A vs. Undocumented Migrant Workers") addnotes(Matching variables: age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap)

*SOCIAL OUTCOMES
eststo h1: teffects nnmatch (hosp age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo h2: teffects nnmatch (insurance age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables
eststo h3: teffects nnmatch (poorhealth age marriedlast empsp cebsofar edyrs usexp ustrips migsoccap physcap) (h2a), nneighbor(2) dmvariables 
esttab h* using "health_outcomes.doc", label brackets replace onecell compress nogaps star rtf mtitles title("Table 4: Health Outcomes for H2-A vs. Undocumented Migrant Workers") addnotes("Matching variables: age, married, spouse employed, total children born prior to or during last US trip, education, total months of US experience, total number of US migrations, migration social capital, and physical capital")

clear
capture log close
