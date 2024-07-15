*! 1.1.0 NJC 2 June 2004
*! 1.0.0 NJC 17 May 2004
program _goutside 
	version 8.0
	syntax newvarname =/exp [if] [in] ///
		[, BY(varlist) FACTor(numlist max=1 >=0) ] 
	quietly {
		tempvar touse group 
		tempname u l 
		mark `touse' `if' `in'
		sort `touse' `by'
		by `touse' `by' : gen long `group' = _n == 1 if `touse'
		replace `group' = sum(`group')
		local max = `group'[_N]
		gen double `varlist' = .
		if "`factor'" == "" local factor = 1.5 
		
		forval i = 1/`max' {
			su `exp' if `group' == `i', detail
			scalar `u' = r(p75) + `factor' * (r(p75) - r(p25)) 
			scalar `l' = r(p25) - `factor' * (r(p75) - r(p25)) 
			replace `varlist' = `exp' ///
				if `group' == `i' & (`exp' > `u' | `exp' < `l')
		}
	}
end
