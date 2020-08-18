/*
 * Solver.h
 *
 *  Created on: Aug 30, 2015
 *      Author: mconnolly
 */

#ifndef SOLVER_H_
#define SOLVER_H_

#include "Model.h"

class Solver {
public:
	Solver();
	virtual ~Solver();

	void euler(Model m);
};

#endif /* SOLVER_H_ */
