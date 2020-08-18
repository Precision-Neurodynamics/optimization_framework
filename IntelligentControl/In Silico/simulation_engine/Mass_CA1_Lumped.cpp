/*
 * Mass_CA1_Lumped.cpp
 *
 *  Created on: Nov 24, 2015
 *      Author: mconnolly
 */

#include "Mass_CA1_Lumped.h"
#include "NoiseGenerator.h"

Mass_CA1_Lumped::Mass_CA1_Lumped() {
    this->v_Pyr 	= 0;
    this->i_Pyr	= 0;
    this->v_E 	= 0;
    this->i_E 	= 0;
    this->v_IS1 	= 0;
    this->i_IS1 	= 0;
    this->v_IF1 	= 0;
    this->i_IF1 	= 0;
    this->v_IS2 	= 0;
    this->i_IS2 	= 0;
    this->v_IF2 	= 0;
    this->i_IF2 	= 0;

    this->dv_Pyr 	= 0;
    this->di_Pyr	= 0;
    this->dv_E 	= 0;
    this->di_E 	= 0;
    this->dv_IS1 	= 0;
    this->di_IS1 	= 0;
    this->dv_IF1 	= 0;
    this->di_IF1 	= 0;
    this->dv_IS2 	= 0;
    this->di_IS2 	= 0;
    this->dv_IF2 	= 0;
    this->di_IF2 	= 0;
}

Mass_CA1_Lumped::~Mass_CA1_Lumped() {
	// TODO Auto-generated destructor stub
}


void Mass_CA1_Lumped::update_ode(){
	double afferent_input = 0;
	double p = this->get_noise_afferent()->get_noise() * this->get_noise_afferent_weight();
	double stimulation = this->get_stimulation();

	double A = this->get_A();
	double B = this->get_B();
	double G = this->get_G();

	double a = this->get_a();
	double b = this->get_b();
	double g = this->get_g();

	double C1 = this->get_C1();
	double C2 = this->get_C2();
	double C3 = this->get_C3();
	double C4 = this->get_C4();
	double C5 = this->get_C5();
	double C6 = this->get_C6();
	double C7 = this->get_C7();

	for(int c1 = 0; c1 < this->get_schaffer_afferents().size(); c1++){
		afferent_input += this->schaffer_afferents[c1]->get_schaffer_v()  * this->get_schaffer_afferent_weight()[c1];
	}

	for(int c1 = 0; c1 < this->get_lateral_afferents().size(); c1++){
//             mexPrintf("afferent_input = %f\n", afferent_input);

		afferent_input += this->lateral_afferents[c1]->get_lateral_v()  * this->get_lateral_afferent_weight()[c1];
	}

//    dv_Pyr 	= i_Pyr;
//    di_Pyr	= A*a*(Sigma::spike_density(v_E - v_IS1 - v_IF1 + stimulation)) - 2*a*i_Pyr - a*a*v_Pyr;
//
//    dv_E 	= i_E;
//    di_E 	= A*a*(p + C2*Sigma::spike_density(C1*v_Pyr + afferent_input  + stimulation) ) - 2*a*i_E - a*a*v_E;
//
//    dv_IS1 	= i_IS1;
//    di_IS1 	= B*b*C4*(Sigma::spike_density(C3*v_Pyr  + stimulation)) - 2*b*i_IS1 - b*b*v_IS1;
//
//    dv_IF1 	= i_IF1;
//    di_IF1 	= G*g*C7*(Sigma::spike_density(C5*v_Pyr - C6*v_IS2  + stimulation)) - 2*g*i_IF1 - g*g*v_IF1;
//
//    dv_IS2 	= i_IS2;
//    di_IS2 	= B*b*(Sigma::spike_density(C3*v_Pyr  + stimulation) ) - 2*b*i_IS2 - b*b*v_IS2;
//
//    dv_IF2 	= i_IF2;
//    di_IF2 	= G*g*Sigma::spike_density(C5*v_Pyr + stimulation) - 2*g*i_IF2 - g*g*v_IF2;

    dv_Pyr 	= i_Pyr;
    di_Pyr	= A*a*(Sigma::spike_density(v_E - v_IS1 - v_IF1)) - 2*a*i_Pyr - a*a*v_Pyr;

    dv_E 	= i_E;
    di_E 	= A*a*(p+ this->get_stimulation() + C2*Sigma::spike_density(C1*v_Pyr + afferent_input ) ) - 2*a*i_E - a*a*v_E;
       
    dv_IS1 	= i_IS1;
    di_IS1 	= B*b*C4*(Sigma::spike_density(C3*v_Pyr )) - 2*b*i_IS1 - b*b*v_IS1;

    dv_IF1 	= i_IF1;
    di_IF1 	= G*g*C7*(Sigma::spike_density(C5*v_Pyr - C6*v_IS2 )) - 2*g*i_IF1 - g*g*v_IF1;

    dv_IS2 	= i_IS2;
    di_IS2 	= B*b*(Sigma::spike_density(C3*v_Pyr ) ) - 2*b*i_IS2 - b*b*v_IS2;

    dv_IF2 	= i_IF2;
    di_IF2 	= G*g*Sigma::spike_density(C5*v_Pyr) - 2*g*i_IF2 - g*g*v_IF2;
}

void Mass_CA1_Lumped::update_state(double dt){
//     mexPrintf("dt = %f\n", dt);
	v_Pyr 	+= dv_Pyr*dt ;
	i_Pyr 	+= di_Pyr*dt;
	v_E 	+= dv_E*dt;
	i_E 	+= di_E*dt;
	v_IS1 	+= dv_IS1*dt;
	i_IS1 	+= di_IS1*dt;
	v_IF1 	+= dv_IF1*dt;
	i_IF1 	+= di_IF1*dt;
	v_IS2 	+= dv_IS2*dt;
	i_IS2 	+= di_IS2*dt;
	v_IF2 	+= dv_IF2*dt;
	i_IF2 	+= di_IF2*dt;
}

double Mass_CA1_Lumped::get_lfp(){
	return (this->v_E - this->v_IF1 - this->v_IS1);
}

std::vector<double> Mass_CA1_Lumped::get_schaffer_afferent_weight(){
	return this->schaffer_afferent_weight;
}

std::vector<Mass_CA3_Lumped *>	Mass_CA1_Lumped::get_schaffer_afferents(){
	return this->schaffer_afferents;
}

std::vector<double> Mass_CA1_Lumped::get_lateral_afferent_weight(){
	return this->lateral_afferent_weight;
}

std::vector<Mass_CA1_Lumped *> Mass_CA1_Lumped::get_lateral_afferents(){
	return this->lateral_afferents;
}

double Mass_CA1_Lumped::get_lateral_v(){
	return this->v_Pyr;
}

double Mass_CA1_Lumped::get_feedback_v(){
	return this->v_IF2;
}

void Mass_CA1_Lumped::set_schaffer_afferents(std::vector<Mass_CA3_Lumped *> schaffer_afferents){
	this->schaffer_afferents = schaffer_afferents;
}

void Mass_CA1_Lumped::set_schaffer_afferent_weight(std::vector<double> schaffer_afferent_weight){
	this->schaffer_afferent_weight = schaffer_afferent_weight;
}

void Mass_CA1_Lumped::add_schaffer_afferent(Mass_CA3_Lumped* schaffer_afferent, double schaffer_afferent_weight){

	this->schaffer_afferents.push_back(schaffer_afferent);
	this->schaffer_afferent_weight.push_back(schaffer_afferent_weight);

}

void Mass_CA1_Lumped::add_lateral_afferent(Mass_CA1_Lumped* lateral_afferent, double lateral_afferent_weight){

	this->lateral_afferents.push_back(lateral_afferent);
	this->lateral_afferent_weight.push_back(lateral_afferent_weight);

}
