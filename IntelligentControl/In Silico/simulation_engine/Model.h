/*
 * Model.h
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#ifndef MODEL_H_
#define MODEL_H_

#include "Mass.h"
#include "NoiseGenerator.h"
#include <vector>

class Model {

private:

public:
	Model();
	virtual ~Model();

	virtual void update_noise() = 0;
	virtual void update_ode() = 0;
	virtual void update_state(double dt) = 0;

};

#endif /* MODEL_H_ */
