*! 1.1 Alvaro Carril 04apr2017
program define texresults3
version 9
syntax [using], ///
	TEXmacro(string) ///
	[ ///
		replace Append ///
		ROund(real 0.01) UNITzero ///
		Result(string) ///
		coef(varname) ///
		se(varname) ///
		tstat(varname) ///
		pvalue(varname) ///
	]


* Initial checks and processing
*------------------------------------------------------------------------------
// Parse file action
if !missing("`replace'") & !missing("`append'") {
	di as error "{bf:replace} and {bf:append} may not be specified simultaneously"
	exit 198
}
local action `replace' `append'

// Add backslash to macroname and issue warning if doesn't contain only alph
local isalph = regexm("`texmacro'","^[a-zA-Z ]*$")
local texmacro = "\" + "`texmacro'"
if `isalph' == 0 di as text `""`texmacro'" may not be a valid LaTeX macro name"'


* Process and store [rounded] result
*------------------------------------------------------------------------------

local hascomma = regexm("`result'",",")
local isalph = regexm("`result'","^[a-zA-Z ]*$")

// general result (scalar, local, etc.)
if !missing("`result'") {
	if `isalph' == 0 & `hascomma' == 0 {
		local result = string(`result', "%12.`round'f")
	}
	else if `isalph' == 1 & `hascomma' == 1 {
		local result = "`result'"
	}
	else if `isalph' == 1 & `hascomma' == 0 {
		local result = "`result'"
	}
	else if `isalph' == 0 & `hascomma' == 1 {
		local result = "`result'"
	}
}

// coefficient
if !missing("`coef'") {
	local result = string(_b[`coef'], "%12.`round'f") 
}
// standard error
if !missing("`se'") {
	local result = string(_se[`se'], "%12.`round'f") 
}
// t-stat
if !missing("`tstat'") {
	local result = string(_b[`tstat']/_se[`tstat'], "%12.`round'f")
}
// p-value - tstat
if !missing("`pvalue'") {
	local result = string(2 * ttail(e(df_r), abs(_b[`pvalue']/_se[`pvalue'])), "%12.`round'f")
}

// p-value - zstat
if !missing("`pvaluez'") {
	local result = string(2 * (1 - normal(abs(_b[`pvaluez']/_se[`pvaluez']))), "%12.`round'f") 
}

// lb
if !missing("`lb'") {
	local result = string(_b[`lb'] - invttail(e(df_r), 0.025)*_se[`lb'], "%12.`round'f") 
}

// ub
if !missing("`ub'") {
	local result = string(_b[`ub'] + invttail(e(df_r), 0.025)*_se[`ub'], "%12.`round'f") 
}

// lbz
if !missing("`lbz'") {
	local result = string(_b[`lbz'] - 1.96 *_se[`lbz'], "%12.`round'f") 
}

// ubz
if !missing("`ubz'") {
	local result = string(_b[`ubz'] + 1.96*_se[`ubz'], "%12.`round'f") 
}

// Add unit zero if option is specified and result qualifies
if `isalph' == 0 & `hascomma' == 0 {
	if (!missing("`unitzero'") & abs(`result') < 1 & `result' > 0) {
		local result 0`result'
	}
	else if (!missing("`unitzero'") & abs(`result') < 1 & `result' < 0) {
		local result = "-0"+"`=abs(`result')'"
	}
}

* Create or modify macros file
*------------------------------------------------------------------------------
file open texresultsfile `using', write `action'
file write texresultsfile "\newcommand{`texmacro'}{$`result'$}" _n
file close texresultsfile
*di as text `" Open {browse results.txt}"'

end
