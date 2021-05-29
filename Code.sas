/***************************************************************\
							PROJECT
					  Statical modelling
				  Analysis of continuous data
 ***************************************************************
 * Authors: Leon D'Hulster
			Viktor Moortgat
			Bhanu Durganath Angam
			Narendra Kamineni
 * Created: 04/12/2020
 * Last update: 12/13/2020
/****************************************************************/

/****************  SETUP  ****************/
/* Library assignments */
%LET path = /folders/myshortcuts/statcomp2020/modeling/;
LIBNAME contdat BASE "&path.";

/* Turn on ODS graphs */
ODS GRAPHICS ON;

/* Read in data */
PROC IMPORT DATAFILE="&path.US_County_Level_Presidential_Res.csv"
			DBMS=csv OUT=USPOLL_import REPLACE;
			GUESSINGROWS=200;
run;

PROC CONTENTS DATA=USPOLL_import;
RUN;

PROC SQL;
	CREATE TABLE uspoll AS
		SELECT
			CAT(t1.state_abbr, t1.county_name) AS ID, 
			t1.per_dem_2016 AS votes_16, 
			t1.per_dem_2012 AS votes_12,
			t1.PST045214 AS population,
			t1.state_abbr AS state, 
			t1.SEX255214 AS gender, 
			t1.AGE135214 AS age5, 
			t1.AGE295214 AS age18, 
			t1.AGE775214 AS age65, 
			t1.RHI125214 AS whiteness, 
			t1.EDU635213 AS highschool, 
			t1.EDU685213 AS bachelor, 
			t1.HSG010214/t1.PST045214 AS housing, 
			t1.HSG445213 AS home_ownership, 
			t1.HSG096213 AS house_units_per_struc, 
			t1.HSG495213 AS housing_value, 
			t1.HSD410213 AS households, 
			t1.HSD310213 AS household_size, 
			t1.INC910213 AS income_capita, 
			t1.INC110213 AS income_median, 
			t1.PVY020213 AS poverty, 
			t1.BPS030214/t1.PST045214 AS permits,
			t1.POP815213 AS language,
			t1.VET605213/t1.PST045214 AS veterans,
			t1.BZA110213 AS employed,
			t1.BZA110213/t1.PST045214 AS employment,
			t1.BZA115213 AS employment_change
		FROM USPOLL_import t1
			WHERE t1.state_abbr NOT = 'AK'; /* Alaska has no counties(?), so excluded */
QUIT;

/* Add labels */
DATA uspoll;
	SET uspoll;
	LABEL 
		votes_16 = "Percentage of democratic votes, 2016" 
		votes_12 = "Percentage of democratic votes, 2012" 
		gender = "Female persons, %, 2014" /* Not enough variation */
		age5 = "Persons under 5 years old, %, 2014" 
		age18 = "Persons under 18 years old, %, 2014" 
		age65 = "Persons over 65 years old, 2014" 
		whiteness = "White alone, %, 2014" 
		highschool = "High school grad. or higher, %, 2009-2013" /* No correlation with votes_12 */
		bachelor = "Bachelor's degree or higher, %, 2009-2013" 
		housing = "Housing units per capita, 2014" /* Not enough variation */
		home_ownership = "Homeownership rate, 2009-2013" 
		house_units_per_struc = "Housing units in multi-unit structures, %, 2009-2013" 
		housing_value = "Median value of housing unit, 2009-2013" 
		households = "Households, 2009-2013" 
		household_size = "Average household size, 2009-2013" /* strong correlation with age18 */
		income_capita = "Income per capita, 2009-2013" 
		income_median = "Median income, 2009-2013" 
		poverty = "Persons below poverty level, %, 2009-2013" 
		permits = "Building permints, 2014"
		language_sqrt = "Language other than English spoken at home, squareroot of %, 2009-2013"
		employment = "Employed persons per capita, 2014";
RUN;

/* Add interaction terms to dataset */
DATA uspoll;
	SET uspoll;
	intvoteswhit = votes_12 * whiteness;
	intvotesage = votes_12 * age18;
	intvotesbach = votes_12 * bachelor;
	intvotespov = votes_12 * poverty;
	intvoteslang = votes_12 * sqrt(language);
	intvotesemp = votes_12 * employment;
	intwhitage = whiteness * age18;
	intwhitbach = whiteness * bachelor;
	intwhitpov = whiteness * poverty;
	intwhitlang= whiteness * sqrt(language);
	intwhitemp = whiteness * employment;
	intagebach = age18 * bachelor;
	intagepov = age18 * poverty;
	intageemp = age18 * employment;
	intagelang = age18 * sqrt(language);
	intpovlang = poverty * sqrt(language);
	intpovemp = poverty * employment;
	intpovbach = poverty * bachelor;
	intlangbach = sqrt(language) * bachelor;
	intlangemp = sqrt(language) * employment;
	whiteness_sq = whiteness*whiteness;
	whiteness_cube = whiteness*whiteness*whiteness;
	language_sq = language*language;
	language_sqrt = sqrt(language);
RUN;

/****************  DESCRIPTIVES  ****************/

PROC UNIVARIATE DATA=uspoll;
  VAR votes_16 votes_12 whiteness age18 bachelor poverty language;
  HISTOGRAM votes_16 votes_12 whiteness age18 bachelor poverty language;
  QQPLOT votes_12 whiteness age18 bachelor poverty language;
run;

PROC MEANS DATA=uspoll MEAN VAR LCLM UCLM MAXDEC=2;
  VAR votes_16 votes_12 whiteness age18 bachelor poverty language;
RUN;

/* Bivariate descriptives */
PROC SGSCATTER DATA=uspoll;
  MATRIX votes_16 votes_12 whiteness age18 bachelor poverty language/ DIAGONAL=(HISTOGRAM NORMAL);
RUN;

PROC CORR DATA=uspoll NOSIMPLE;
	VAR votes_16 votes_12 whiteness age18 bachelor poverty language;
RUN;

%MACRO scatter(var);
PROC SGPLOT DATA=uspoll;
	SCATTER X=&var. Y=votes_16;
	REG X=&var. Y=votes_16;
RUN;
%MEND;

%scatter(votes_12);
%scatter(whiteness);
%scatter(age18);
%scatter(bachelor);
%scatter(poverty);
%scatter(language);

/* Descriptives by state (only 10 most populous states) */
DATA uspoll_10state;
	SET uspoll;
	WHERE state IN ("CA","TX","FL","NY","PA","IL","OH","GA","NC");
RUN;

	/* Boxplots for continuous versus categorical variable */
%MACRO box(var,cat=state);
PROC SGPLOT DATA = uspoll_10state;
  VBOX &var/ CATEGORY = &cat;
RUN;
%MEND;

%box(votes_16);
%box(votes_12);
%box(whiteness);
%box(age18);
%box(bachelor);
%box(poverty);
%box(language);


/****************  CONTINUOUS MODEL  ****************/

/* Select random half of data */
PROC SURVEYSELECT DATA=uspoll SAMPRATE=0.5
	OUT= uspoll_all outall 
	SEED=123;
RUN;

DATA uspoll_training;
	SET uspoll_all;
	WHERE Selected=1;
RUN;

DATA uspoll_test;
	SET uspoll_all;
	WHERE Selected=0;
RUN;

/* Main effects model */
/* Adding main effect to model based on strength of correlation
	and checking functional form using partial regression*/
PROC REG DATA=uspoll_training;
  MODEL votes_16 = votes_12 age18 whiteness bachelor poverty language_sqrt;
  OUTPUT OUT=resid r=rmain p=pmain STUDENT=stud;
RUN;

%MACRO residplot(int=);
PROC SGPLOT DATA=resid;
  SCATTER X=&int Y=rmain;
  LOESS X=&int Y=rmain;
  REFLINE 0 / AXIS=y LINEATTRS=(COLOR=red);
RUN;
%mend;

%residplot(int=intvoteswhit);
%residplot(int=intvotesage);
%residplot(int=intvotesbach);
%residplot(int=intvotespov);
%residplot(int=intvoteslang);
%residplot(int=intwhitage);
%residplot(int=intwhitbach);
%residplot(int=intwhitpov);
%residplot(int=intwhitlang);
%residplot(int=intagebach);
%residplot(int=intagepov);
%residplot(int=intagelang);
%residplot(int=intpovlang);

/* Forward selection process*/
/* Regression model + selection criterion = BIC + Adj R² */
%MACRO modelselection(model_list);
%LET last_var = %SCAN(&model_list.,%SYSFUNC(COUNTW(&model_list.)));

PROC REG DATA=uspoll_training OUTEST=outest_&last_var. plots=none;
 	MODEL votes_16 = &model_list. / BIC ADJRSQ PARTIAL;
	OUTPUT OUT=resid r=rmain;
	TEST &last_var = 0;
RUN;
%MEND;

%modelselection(votes_12);
%modelselection(votes_12 bachelor);
%modelselection(votes_12 bachelor whiteness);
/*%modelselection(votes_12 bachelor whiteness language);*/
/*%modelselection(votes_12 bachelor whiteness language_sq);*/
%modelselection(votes_12 bachelor whiteness language_sqrt);
%modelselection(votes_12 bachelor whiteness language_sqrt poverty);
%modelselection(votes_12 bachelor whiteness language_sqrt poverty age18);

/* Running our initial model, we discovered the functional form of language to be nonlinear */
/* This was solved by transforming the language variable (sqrt transformation) and rerunning the model */

DATA outest;
	SET outest_:;
RUN;

PROC SORT DATA=outest OUT=outest;
	BY _RSQ_;
RUN;


/* Model with all main effects */
%LET main_model = votes_12 whiteness bachelor language_sqrt poverty age18;

PROC GLM DATA=uspoll_training PLOTS=(DIAGNOSTICS RESIDUALS) ;
 	MODEL votes_16 = &main_model./ TOLERANCE;
	OUTPUT OUT=resid RESIDUAL=rmain ;
RUN;

/* Checking equality of variances */
PROC SGPLOT DATA=resid;
	SCATTER X=votes_16 Y=rmain;
	LOESS X=votes_16 Y=rmain;
RUN;

/* Check assumptions - Equal variance: cfr output proc reg */

/* Check assumptions - Normality: cfr output proc reg */

/* Check multicollinearity */
proc REG DATA=uspoll_training PLOTS=ALL;
 	MODEL votes_16 = &main_model. / VIF TOL COLLIN ;
	OUTPUT out=resid r=rmain PRESS=press COOKD=cookd;
RUN;

/* Check all interaction*/
/* Add interaction terms if adding it improves our selection criterion (BIC/ Adj R²)*/
/* Adjust later on for potential high VIF */
PROC DATASETS NOLIST;
	DELETE outest_int:;
RUN;

%MACRO interaction(int);
PROC REG DATA=uspoll_training outest=outest_&int.;
 	MODEL votes_16 = &main_model. &int./ VIF BIC ADJRSQ;
	TEST &int.=0;
RUN;
%MEND;

%interaction(int=intvoteswhit);
%interaction(int=intvotesage); 
%interaction(int=intvotesbach); 
%interaction(int=intvotespov); 
%interaction(int=intvoteslang); 
%interaction(int=intwhitage); 
%interaction(int=intwhitbach); 
%interaction(int=intwhitpov); 
%interaction(int=intwhitlang); 
%interaction(int=intagebach); 
%interaction(int=intagepov); 
%interaction(int=intagelang); 
%interaction(int=intpovlang);
%interaction(int=intpovbach); 
%interaction(int=intlangbach); 

DATA results;
	SET outest_int:;
RUN;
PROC SORT DATA=results OUT=results;
	BY _ADJRSQ_;
RUN;

/* Add intwhitlang */
PROC DATASETS NOLIST;
	DELETE outest_int:;
RUN;

%MACRO interaction(int);
PROC reg DATA=uspoll_training outest=outest_&int.;
 	MODEL votes_16 = &main_model. intwhitlang &int./ VIF BIC ADJRSQ;
	TEST &int.=0;
RUN;
%MEND;

%interaction(int=intvoteswhit);
%interaction(int=intvotesage); 
%interaction(int=intvotesbach); 
%interaction(int=intvotespov); 
%interaction(int=intvoteslang); 
%interaction(int=intwhitage); 
%interaction(int=intwhitbach); 
%interaction(int=intwhitpov);  
%interaction(int=intagebach); 
%interaction(int=intagepov); 
%interaction(int=intagelang); 
%interaction(int=intpovlang);
%interaction(int=intpovbach); 
%interaction(int=intlangbach); 


DATA results;
	SET outest_int:;
RUN;
PROC SORT data=results out=results;
	BY _ADJRSQ_;
RUN;

/* Add intvoteslang */
PROC DATASETS NOLIST;
	DELETE outest_int:;
RUN;
%MACRO interaction(int);
PROC reg DATA=uspoll_training outest=outest_&int.;
 	MODEL votes_16 = &main_model. intwhitlang intvoteslang &int./ VIF BIC ADJRSQ;
	TEST &int.=0;
RUN;
%MEND;

%interaction(int=intvoteswhit); 
%interaction(int=intvotesage); 
%interaction(int=intvotesbach); 
%interaction(int=intvotespov);
%interaction(int=intwhitage); 
%interaction(int=intwhitbach); 
%interaction(int=intwhitpov); 
%interaction(int=intagebach); 
%interaction(int=intagepov); 
%interaction(int=intagelang);
%interaction(int=intpovlang);
%interaction(int=intpovbach);
%interaction(int=intlangbach); 

DATA results;
	SET outest_int:;
RUN;
PROC SORT data=results out=results;
	BY _ADJRSQ_;
RUN;

/* Add intagelang */
PROC DATASETS NOLIST;
	DELETE outest_int:;
RUN;

%MACRO interaction(int);
PROC reg DATA=uspoll_training outest=outest_&int.;
 	MODEL votes_16 = &main_model. intwhitlang intvoteslang intagelang &int./ VIF BIC ADJRSQ;
	TEST &int.=0;
RUN;
%MEND;

%interaction(int=intvoteswhit);
%interaction(int=intvotesage); 
%interaction(int=intvotesbach); 
%interaction(int=intvotespov); 
%interaction(int=intwhitage); 
%interaction(int=intwhitbach);
%interaction(int=intwhitpov);
%interaction(int=intagebach); 
%interaction(int=intagepov); 
%interaction(int=intpovlang);
%interaction(int=intpovbach); 
%interaction(int=intlangbach);

DATA results;
	set outest_int:;
RUN;
PROC SORT data=results out=results;
	BY _ADJRSQ_;
RUN;

/* Add intvotesage */
PROC DATASETS NOLIST;
	DELETE outest_int:;
RUN;

%MACRO interaction(int);
PROC reg DATA=uspoll_training outest=outest_&int.;
 	MODEL votes_16 = &main_model. intwhitlang intvoteslang intagelang 
		intvotesage &int./ VIF BIC ADJRSQ;
	TEST &int.=0;
RUN;
%MEND;

%interaction(int=intvoteswhit);
%interaction(int=intvotesbach);
%interaction(int=intvotespov);
%interaction(int=intwhitage);
%interaction(int=intwhitbach);
%interaction(int=intwhitpov);
%interaction(int=intagebach);
%interaction(int=intagepov);
%interaction(int=intpovlang);
%interaction(int=intpovbach);
%interaction(int=intlangbach);

DATA results;
	SET outest_int:;
RUN;
PROC SORT data=results out=results;
	BY _ADJRSQ_;
RUN;

%LET full_model = &main_model. intwhitlang intvoteslang intagelang intvotesage;

/* Expanded model */
PROC REG data=uspoll_training;
	MODEL votes_16 =  &full_model. / VIF;
RUN;

/* Adapting for multicollinearity */
PROC STDIZE DATA=uspoll_training
				METHOD=mean
				OUT=uspoll_cent;
	VAR whiteness votes_12 age18 language_sqrt;
RUN;


DATA uspoll_cent;
	SET uspoll_cent;
	intvoteswhit = votes_12 * whiteness;
	intvotesage = votes_12 * age18;
	intvotesbach = votes_12 * bachelor;
	intvotespov = votes_12 * poverty;
	intvoteslang = votes_12 * sqrt(language);
	intvotesemp = votes_12 * employment;
	intwhitage = whiteness * age18;
	intwhitbach = whiteness * bachelor;
	intwhitpov = whiteness * poverty;
	intwhitlang= whiteness * sqrt(language);
	intwhitemp = whiteness * employment;
	intagebach = age18 * bachelor;
	intagepov = age18 * poverty;
	intageemp = age18 * employment;
	intagelang = age18 * sqrt(language);
	intpovlang = poverty * sqrt(language);
	intpovemp = poverty * employment;
	intpovbach = poverty * bachelor;
	intlangbach = sqrt(language) * bachelor;
	intlangemp = sqrt(language) * employment;
	whiteness_sq = whiteness*whiteness;
	whiteness_cube = whiteness*whiteness*whiteness;
	language_sq = language*language;
	language_sqrt = sqrt(language);
RUN;

PROC REG DATA=uspoll_cent;
	MODEL votes_16 = &full_model. / VIF;
RUN;


/****************  FINAL MODEL  ****************/

/* Step 9: Check the assumptions */

	/* Normality: verify qqplot of (studentised) residuals */
PROC GLM DATA=uspoll_cent PLOTS=(RESIDUALS DIAGNOSTICS );
	MODEL votes_16 = &full_model./ SOLUTION;
	OUTPUT OUT=resid RESIDUAL=resid RSTUDENT=rstud P=pred;
RUN;

/* Linearity: verify plot of (studentised) residuals vs predicted values*/
PROC SGPLOT DATA=resid;
	SCATTER X=pred Y=rstud;
RUN;

/* Homoscedasticity: verify (squared) residuals vs predicted values */
DATA resid2;
  SET resid;
  resid2=resid**2;
RUN;

PROC SGPLOT DATA=resid2;
  SCATTER x=pred y=resid2;
  LOESS x=pred y=resid2;
  REFLINE 0 / AXIS=y LINEATTRS=(COLOR=red);
RUN;

PROC GLM DATA=uspoll_cent PLOTS=(RESIDUALS DIAGNOSTICS );
	MODEL votes_16 = &full_model./ SOLUTION;
	OUTPUT OUT=resid RESIDUAL=resid RSTUDENT=rstud P=pred;
	WEIGHT population;
RUN;

PROC SGPLOT DATA=resid2;
  SCATTER X=pred Y=resid2;
  LOESS X=pred Y=resid2;
  REFLINE 0 / AXIS=y LINEATTRS=(COLOR=red);
RUN;

/* Check for outliers */
PROC REG DATA=uspoll_cent;
	MODEL votes_16 = &full_model./ R INFLUENCE;
	OUTPUT OUT=cookdis COOKD=cdist;
RUN;

DATA uspoll_cent2;
	SET cookdis;
	WHERE cdist < 0.003;
RUN;

PROC REG DATA=uspoll_cent;
	MODEL votes_16 = &full_model.;
RUN;

PROC REG DATA=uspoll_cent2;
	MODEL votes_16 = &full_model.;
RUN;

/*************** BONUS *****************/
/* Observations are not independent but nested */
/* Random intercept for state to correct for nested design */

PROC MIXED DATA=uspoll_cent2 PLOTS=residualpanel METHOD=ML;
	MODEL votes_16 = &full_model./ SOLUTION;
RUN;
/* BIC = -6886 */

/* Adding state as fixed effect */

PROC MIXED DATA=uspoll_cent2 PLOTS=residualpanel METHOD=ML;
	CLASS state;
	MODEL votes_16 = &full_model. state/ SOLUTION;
RUN;
/* BIC = -7252.8 */

/* State as a random effect */

PROC MIXED DATA=uspoll_cent2 PLOTS=residualpanel METHOD=ML;
	CLASS state;
 	MODEL votes_16 = &full_model./ SOLUTION;
	RANDOM INT/SUBJECT=state TYPE=UN ;
RUN;
/* BIC = -7448.2 */


/*************** CATEGORICAL MODEL *****************/
DATA uspoll_cent_cat;
	SET uspoll_cent;
	IF 0.48 <= votes_16 <= 0.52 THEN votes_16_bin = 1;
	ELSE votes_16_bin = 0;
RUN;
	
/* Add new descriptive analysis */
%MACRO box(var,cat=votes_16_bin);
PROC SGPLOT DATA = uspoll_cent_cat;
  VBOX &var/ CATEGORY = &cat;
RUN;
%MEND;

%box(votes_12);
%box(bachelor);
%box(whiteness);
%box(age18);
%box(poverty);
%box(language);

/* Build a model to predict our categorical outcome */
PROC LOGISTIC DATA=uspoll_cent_cat;
	MODEL votes_16_bin =&full_model.;
RUN;
/* A lot of the terms are insignificant, so we decide to build the model from the ground up */

/* Forward model selection */
DATA uspoll_training;
	SET uspoll_training;
	IF 0.48 <= votes_16 <= 0.52 THEN votes_16_bin = 1;
	ELSE votes_16_bin = 0;
RUN;

%MACRO modelselection(model_list);
%LET last_var = %SCAN(&model_list.,%SYSFUNC(COUNTW(&model_list.)));

PROC GENMOD DATA=uspoll_training ;
 	MODEL votes_16_bin = &model_list. / LINK=logit;
RUN;
%MEND;

%modelselection(votes_12); /* Lowest BIC score: -944 */
%modelselection(votes_12 bachelor); /* Lowest BIC score: -945 */
%modelselection(votes_12 bachelor whiteness);
%modelselection(votes_12 bachelor language_sqrt);
%modelselection(votes_12 bachelor poverty);
%modelselection(votes_12 bachelor age18);

/*Check interaction term bachelor and votes_12 */
%modelselection(votes_12 bachelor intvotesbach) /* Lowest BIC score: -954 */ 
/* Add the interaction term to the model */

/* Work further in R for the remainder */