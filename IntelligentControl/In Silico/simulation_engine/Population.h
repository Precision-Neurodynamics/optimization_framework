/*
 * Population.h
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#ifndef POPULATION_H_
#define POPULATION_H_

#include <vector>
#include <stdlib.h>

#include "Sigma.h"

class Population {
private:
	int 		index;
	double 		W;
	double 		w;
	double 		noise_weight;

	double 		v;
	double  	i;
	double 		dv;
	double  	di;

	std::vector<Population *> 	afferents;
	std::vector<double> 		afferent_weight;
public:
	Population(double A, double a, std::vector<Population*> afferents,
			std::vector<double> afferent_weight, double noise_weight);

	Population();
	virtual 		~Population();

	void 			update_ode();
	void 			update_state(double dt);

	double 						get_v();
	double 						get_gain();
	double 						get_time_const();
	double						get_noise_weight();
	std::vector<Population*>	get_afferents();
	std::vector<double> 		get_afferent_weight();
	int 						get_index();

	void 	set_gain(double A);
	void 	set_time_const(double a);
	void 	set_noise_weight(double noise_weight);
	void 	set_afferents(std::vector<Population*>& afferents);
	void 	set_afferent_weight(std::vector<double> afferent_weight);
	void 	set_index(int index);
};

#endif /* POPULATION_H_ */
