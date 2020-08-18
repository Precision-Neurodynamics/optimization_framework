/*
 * MassHippocampal.h
 *
 *  Created on: Aug 24, 2015
 *      Author: mconnolly
 */

#ifndef MASS_CA3_H_
#define MASS_CA3_H_

#include "Mass.h"

class Mass_CA3: public Mass {

public:
	Mass_CA3();
	Mass_CA3(double *gain_ptr, double *time_constant_ptr, double *connectivity_ptr);
	double	get_LFP();
	virtual ~Mass_CA3();
};

#endif /* MASS_CA3_H_ */
