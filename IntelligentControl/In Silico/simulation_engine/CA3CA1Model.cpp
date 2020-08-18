/*
 * CA3CA1Model.cpp
 *
 *  Created on: Jan 12, 2016
 *      Author: mconnolly
 */

#include "CA3CA1Model.h"

CA3_CA1_Model::CA3_CA1_Model() {
	// TODO Auto-generated constructor stub

}

CA3_CA1_Model::CA3_CA1_Model(const mxArray *prhs[]) {

	synaptic_gain 				= mxGetPr(prhs[0]);
	synaptic_time_constants 	= mxGetPr(prhs[1]);
	internal_connectivities 	= mxGetPr(prhs[2]);
	mass_connectivities 		= mxGetPr(prhs[3]);
	stimulation_parameters		= mxGetPr(prhs[4]);
	simulation_parameters 		= mxGetPr(prhs[5]);

	double A1 = synaptic_gain[0];
	double B1 = synaptic_gain[1];
	double G1 = synaptic_gain[2];

	double a = synaptic_time_constants[0];
	double b = synaptic_time_constants[1];
	double g = synaptic_time_constants[2];

	double C1 = internal_connectivities[0];
	double C2 = internal_connectivities[1];
	double C3 = internal_connectivities[2];
	double C4 = internal_connectivities[3];
	double C5 = internal_connectivities[4];
	double C6 = internal_connectivities[5];
	double C7 = internal_connectivities[6];

	double schaffer_weight 	= mass_connectivities[0];
	double feedback_weight 	= mass_connectivities[1];
	double lateral_weight 	= mass_connectivities[2];
	double dentate_weight 	= mass_connectivities[3];
	double perforant_weight = mass_connectivities[4];
	int n_layers 			= (int) mass_connectivities[5];
	n_channels 				= n_layers*2;

	double stimulation_start 		= stimulation_parameters[0];
	double stimulation_stop			= stimulation_parameters[1];
	double stimulation_amplitude 	= stimulation_parameters[2];
	double f_stimulation 			= stimulation_parameters[3];
	double stimulation_channel		= stimulation_parameters[4];

	double t_end 	= simulation_parameters[0];
	double f_sample = simulation_parameters[1];
	int n_samples 	= (int) t_end*f_sample;

	double 	v0 	= 6.0;
	double 	e0 	= 2.5;
	double 	r 	= 0.56;

	Noise_Generator *dentate_afferent, *perforant_afferent;

	for(int c1 = 0; c1 < n_layers; c1++){
			CA3_row.push_back(new Mass_CA3_Lumped);
	}

	for(int c1 = 0; c1 < n_layers; c1++){
		CA1_row.push_back(new Mass_CA1_Lumped);
	}

	dentate_afferent 	= new Noise_Generator();
	perforant_afferent 	= new Noise_Generator();

	noise_generators.push_back(dentate_afferent);
	noise_generators.push_back(perforant_afferent);

	for(int c1 = 0; c1 < CA3_row.size(); c1++){

		CA3_row[c1]->set_A(A1);
		CA3_row[c1]->set_B(B1);
		CA3_row[c1]->set_G(G1);
		CA3_row[c1]->set_a(a);
		CA3_row[c1]->set_b(b);
		CA3_row[c1]->set_g(g);

		CA3_row[c1]->set_C1(C1);
		CA3_row[c1]->set_C2(C2);
		CA3_row[c1]->set_C3(C3);
		CA3_row[c1]->set_C4(C4);
		CA3_row[c1]->set_C5(C5);
		CA3_row[c1]->set_C6(C6);
		CA3_row[c1]->set_C7(C7);

		CA3_row[c1]->add_feedback_afferent(CA1_row[c1], feedback_weight);

		if(c1 < CA3_row.size() - 1){
			CA3_row[c1]->add_lateral_afferent(CA3_row[c1 + 1], lateral_weight);
		}

		if (c1 > 0 ){
			CA3_row[c1]->add_lateral_afferent(CA3_row[c1 - 1], lateral_weight);
		}

		CA3_row[c1]->add_noise_afferent(dentate_afferent, dentate_weight);

	}


	for(int c1 = 0; c1 < CA1_row.size(); c1++){

		CA1_row[c1]->set_A(A1);
		CA1_row[c1]->set_B(B1);
		CA1_row[c1]->set_G(G1);
		CA1_row[c1]->set_a(a);
		CA1_row[c1]->set_b(b);
		CA1_row[c1]->set_g(g);

		CA1_row[c1]->set_C1(C1);
		CA1_row[c1]->set_C2(C2);
		CA1_row[c1]->set_C3(C3);
		CA1_row[c1]->set_C4(C4);
		CA1_row[c1]->set_C5(C5);
		CA1_row[c1]->set_C6(C6);
		CA1_row[c1]->set_C7(C7);

		CA1_row[c1]->add_schaffer_afferent(CA3_row[c1], schaffer_weight);

		if(c1 < CA1_row.size() - 1){
			CA1_row[c1]->add_lateral_afferent(CA1_row[c1 + 1], lateral_weight);
		}

		if (c1 > 0 ){
			CA1_row[c1]->add_lateral_afferent(CA1_row[c1 - 1], lateral_weight);
		}

		CA1_row[c1]->add_noise_afferent(perforant_afferent, perforant_weight);
	}
}

CA3_CA1_Model::~CA3_CA1_Model() {
	// TODO Auto-generated destructor stub
}

void CA3_CA1_Model::update_noise(){
	for(int c1 = 0; c1 < this->get_noise_generators().size(); c1++){
		this->noise_generators[c1]->update_gaussian();
	}
}

void CA3_CA1_Model::update_ode(){

	for(int c1 = 0; c1 < this->get_CA3_row().size(); c1++){
		this->get_CA3_row()[c1]->update_ode();
	}

	for(int c1 = 0; c1 < this->get_CA1_row().size(); c1++){
		this->get_CA1_row()[c1]->update_ode();
	}
}

void CA3_CA1_Model::update_state(double dt){
	for(int c1 = 0; c1 < this->get_CA3_row().size(); c1++){
		this->get_CA3_row()[c1]->update_state(dt);
	}

	for(int c1 = 0; c1 < this->get_CA1_row().size(); c1++){
		this->get_CA1_row()[c1]->update_state(dt);
	}
}


std::vector<Mass_CA3_Lumped *> CA3_CA1_Model::get_CA3_row(){
	return this->CA3_row;
}

std::vector<Mass_CA1_Lumped *> CA3_CA1_Model::get_CA1_row(){
	return this->CA1_row;
}

std::vector<Noise_Generator *> CA3_CA1_Model::get_noise_generators(){
	return this->noise_generators;
}

void CA3_CA1_Model::get_lfp(double *lfp){
	for(int c1 = 0; c1 < this->get_CA3_row().size(); c1++){
		lfp[c1] = this->get_CA3_row()[c1]->get_lfp();
	}

	for(int c1 = 0; c1 < this->get_CA1_row().size(); c1++){
		lfp[c1+get_CA3_row().size()] = this->get_CA1_row()[c1]->get_lfp();
	}

}

int CA3_CA1_Model::get_n_channels(){
	return this->n_channels;
}
