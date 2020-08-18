/*
 * MassHippocampal.cpp
 *
 *  Created on: Aug 24, 2015
 *      Author: mconnolly
 */

#include "Mass_CA3.h"

Mass_CA3::Mass_CA3(){

	double A = 5.;
	double B = 20.;
	double G = 10.;

	double a = 100.;
	double b = 30.;
	double g = 350.;

	double C1 = 135.0;
	double C2 = 108.0;
	double C3 = 33.75;
	double C4 = -33.75;
	double C5 = 40.5;
	double C6 = -13.5;
	double C7 = -108.0;

	Population *excitatory 	= new Population();
	Population *pyramidal 	= new Population();
	Population *fast_gaba 	= new Population();
	Population *slow_gaba_1 = new Population();
	Population *slow_gaba_2 = new Population();

	populations.push_back(excitatory);
	populations.push_back(pyramidal);
	populations.push_back(slow_gaba_1);
	populations.push_back(slow_gaba_2);
	populations.push_back(fast_gaba);

	excitatory->set_index(99);
	pyramidal->set_index(95);
	fast_gaba->set_index(80);
	slow_gaba_1->set_index(75);
	slow_gaba_2->set_index(50);

	//
	// excitatory
	//
	excitatory->set_gain(A);
	excitatory->set_time_const(a);

	std::vector<Population*> excitatory_afferents;
	excitatory_afferents.push_back(pyramidal);
	excitatory->set_afferents(excitatory_afferents);

	std::vector<double> excitatory_afferent_weights;
	excitatory_afferent_weights.push_back(C1);
	excitatory->set_afferent_weight(excitatory_afferent_weights);
	excitatory->set_noise_weight(1.0);

	//
	// pyramidal
	//
	pyramidal->set_gain(A);
	pyramidal->set_time_const(a);

	std::vector<Population*> pyramidal_afferents;
	pyramidal_afferents.push_back(excitatory);
	pyramidal_afferents.push_back(slow_gaba_1);
	pyramidal_afferents.push_back(fast_gaba);
	pyramidal->set_afferents(pyramidal_afferents);

	std::vector<double> pyramidal_afferent_weights;
	pyramidal_afferent_weights.push_back(C2);
	pyramidal_afferent_weights.push_back(C4);
	pyramidal_afferent_weights.push_back(C7);
	pyramidal->set_afferent_weight(pyramidal_afferent_weights);

	//
	// slow_gaba_1
	//
	slow_gaba_1->set_gain(B);
	slow_gaba_1->set_time_const(b);

	std::vector<Population*> slow_gaba_1_afferents;
	slow_gaba_1_afferents.push_back(pyramidal);
	slow_gaba_1->set_afferents(slow_gaba_1_afferents);

	std::vector<double> slow_gaba_1_afferent_weights;
	slow_gaba_1_afferent_weights.push_back(C3);
	slow_gaba_1->set_afferent_weight(slow_gaba_1_afferent_weights);

	//
	// slow_gaba_2
	//
	slow_gaba_2->set_gain(B);
	slow_gaba_2->set_time_const(b);

	std::vector<Population*> slow_gaba_2_afferents;
	slow_gaba_2_afferents.push_back(pyramidal);
	slow_gaba_2->set_afferents(slow_gaba_2_afferents);

	std::vector<double> slow_gaba_2_afferent_weights;
	slow_gaba_2_afferent_weights.push_back(C3);
	slow_gaba_2->set_afferent_weight(slow_gaba_2_afferent_weights);

	//
	// fast_gaba
	//
	fast_gaba->set_gain(G);
	fast_gaba->set_time_const(g);

	std::vector<Population*> fast_gaba_afferents;
	fast_gaba_afferents.push_back(pyramidal);
	fast_gaba_afferents.push_back(slow_gaba_2);
	fast_gaba->set_afferents(fast_gaba_afferents);

	std::vector<double> fast_gaba_afferent_weights;
	fast_gaba_afferent_weights.push_back(C5);
	fast_gaba_afferent_weights.push_back(C6);
	fast_gaba->set_afferent_weight(fast_gaba_afferent_weights);

}

Mass_CA3::Mass_CA3(double *gain_ptr, double *time_constant_ptr, double *connectivity_ptr) {


//	double 	A = gain_ptr[0];
//	double 	B = gain_ptr[1];
//	double 	G = gain_ptr[2];
//
//	double 	a = time_constant_ptr[0];
//	double 	b = time_constant_ptr[1];
//	double 	g = time_constant_ptr[2];
//
//	double 	C1 = connectivity_ptr[0];
//	double 	C2 = connectivity_ptr[1];
//	double 	C3 = connectivity_ptr[2];
//	double 	C4 = connectivity_ptr[3];
//	double 	C5 = connectivity_ptr[4];
//	double 	C6 = connectivity_ptr[5];
//	double 	C7 = connectivity_ptr[6];

//	double 	*afferents;
//	int 	n_afferents;
//
//	double 	e0;
//	double 	v0;
//	double 	r;
}

Mass_CA3::~Mass_CA3() {
	// TODO Auto-generated destructor stub

}

double Mass_CA3::get_LFP(){
	printf("LFP = %f\n", this->get_populations()[0]->get_v()
				- this->get_populations()[2]->get_v()
				- this->get_populations()[3]->get_v());

	return this->get_populations()[0]->get_v()
				- this->get_populations()[2]->get_v()
				- this->get_populations()[3]->get_v();
}

