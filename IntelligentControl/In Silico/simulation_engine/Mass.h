/*
 * Mass.h
 *
 *  Created on: Aug 24, 2015
 *      Author: mconnolly
 */


#ifndef MASS_H_
#define MASS_H_

#include <vector>
#include "Population.h"

class Mass {

private:

protected:
	std::vector<Population *> populations;

public:
	Mass();
	virtual ~Mass();

	void 						update_ode();
	void 						update_state(double dt);
	std::vector<Population *> 	get_populations();
	double 						get_lfp();
};

#endif /* MASS_H_ */
