/*
 * CA3CA1Model.h
 *
 *  Created on: Jan 12, 2016
 *      Author: mconnolly
 */

#ifndef SIMULATION_ENGINE_CA3CA1MODEL_H_
#define SIMULATION_ENGINE_CA3CA1MODEL_H_

#include "Model.h"
#include "mex.h"
#include "Mass_CA3_Lumped.h"
#include "Mass_CA1_Lumped.h"
#include "NoiseGenerator.h"
#include <vector>

class CA3_CA1_Model : public Model{

private:
	double *synaptic_gain, *synaptic_time_constants;
	double *internal_connectivities, *mass_connectivities;
	double *stimulation_parameters, *simulation_parameters;

	std::vector<Mass_CA3_Lumped *> CA3_row;
	std::vector<Mass_CA1_Lumped *> CA1_row;
	std::vector<Noise_Generator *> noise_generators;

	int n_channels;
public:
	CA3_CA1_Model();
	CA3_CA1_Model(const mxArray *prhs[]);
	virtual ~CA3_CA1_Model();

	void update_noise();
	void update_ode();
	void update_state(double dt);

	std::vector<Mass_CA3_Lumped *> get_CA3_row();
	std::vector<Mass_CA1_Lumped *> get_CA1_row();
	std::vector<Noise_Generator *> get_noise_generators();

	void get_lfp(double* lfp);
	int get_n_channels();
};

#endif /* SIMULATION_ENGINE_CA3CA1MODEL_H_ */
