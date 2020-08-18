/*
 * Mass_CA1.h
 *
 *  Created on: Aug 24, 2015
 *      Author: mconnolly
 */

#ifndef MASS_CA1_H_
#define MASS_CA1_H_

#include "Mass.h"

class Mass_CA1: public Mass {

public:
	Mass_CA1();
	Mass_CA1(double *gain_ptr, double *time_constant_ptr, double *connectivity_ptr);
	double 	get_LFP();
	virtual ~Mass_CA1();
};

#endif /* MASS_CA1_H_ */
