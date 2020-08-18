/*
 * Population.cpp
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#include "Population.h"
#include "NoiseGenerator.h"

Population::Population(){
	this->W 				= 0.0;
	this->w 				= 0.0;
	this->noise_weight		= 0.0;

	this->v 	= 0;
	this->i 	= 0;
	this->dv 	= 0;
	this->di 	= 0;
}

Population::Population(	double W, double w, std::vector<Population*> afferents,
						std::vector<double> afferent_weight, double noise_weight)
{
	this->W 				= W;
	this->w 				= w;
	this->afferents 		= afferents;
	this->afferent_weight 	= afferent_weight;
	this->noise_weight		= noise_weight;

	this->v 	= 0;
	this->i 	= 0;
	this->dv 	= 0;
	this->di 	= 0;
}

Population::~Population() {
}

void Population::update_ode() {

//	double afferent_input = 0;
//	double p = this->get_noise_afferent()->get_noise() *this->get_noise_afferent_weight();
//
//	for(int c1 = 0; c1 < afferents.size(); c1++){
//		afferent_input += this->get_afferents()[c1]->get_v()  * this->get_afferent_weight()[c1];
////		printf("Afferent input = %.4f(v) * %.4f(c)\n", this->get_afferents()[c1]->get_v(), this->get_afferent_weight()[c1]);
//	}
//
//	dv 	= i;
//    di 	= W*w*(Sigma::spike_density(afferent_input) + this->get_noise_weight()*p) - 2*w*i - w*w*v;
//
//    printf("------\np = %f\n", this->get_noise_weight()*p);
//    printf("Sigma::spike_density(%f) = %f\n", afferent_input, Sigma::spike_density(afferent_input));
//    printf("v = %f\n", v);
//    printf("i = %f\n", i);
//    printf("dv = %f\n", dv);
//    printf("di = %f\n", di);
//    printf("A = %f\n", W);
//    printf("a = %f\n", w);
}

void Population::update_state(double dt) {
	v = v + dv*dt;
	i = i + di*dt;
	printf("dv = %f\n", dv);
	printf("di = %f\n", di);
}

double Population::get_v(){
	return this->v;
}

double Population::get_gain(){
	return this->W;
}

double Population::get_time_const(){
	return this->w;
}

double Population::get_noise_weight(){
	return this->noise_weight;
}

std::vector<Population *> Population::get_afferents(){
	return this->afferents;
}

int Population::get_index(){
	return this->index;
}
std::vector<double> Population::get_afferent_weight(){
	return this->afferent_weight;
}

void Population::set_gain(double W){
	this->W = W;
}

void Population::set_time_const(double w){
	this->w = w;
}

void Population::set_afferents(std::vector<Population*>& afferents){
	this->afferents = afferents;
}

void Population::set_afferent_weight(std::vector<double> afferent_weight){
	this->afferent_weight = afferent_weight;
}

void Population::set_noise_weight(double noise_weight){
	this->noise_weight = noise_weight;
}

void Population::set_index(int index){
	this->index = index;
}

