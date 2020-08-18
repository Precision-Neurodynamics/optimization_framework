/*
 * NoiseGenerator.cpp
 *
 *  Created on: Aug 27, 2015
 *      Author: mconnolly
 */

#include "NoiseGenerator.h"


Noise_Generator::Noise_Generator() {
	m 			= 3;
	sigma 		= 1;
	coeff_mult 	= 30;
	noise 		= 0;
}

Noise_Generator::~Noise_Generator() {
	// TODO Auto-generated destructor stub
}

void Noise_Generator::set_m(double m){
	this->m = m;
}

void Noise_Generator::set_sigma(double sigma){
	this->sigma = sigma;
}

void Noise_Generator::set_coeff_mult(double coeff_mult){
	this->coeff_mult = coeff_mult;
}

void Noise_Generator::set_noise(double noise){
 	this->noise = noise;
}

double Noise_Generator::get_m(){
	return this->m;
}

double Noise_Generator::get_sigma(){
	return this->sigma;
}

double Noise_Generator::get_coeff_mult(){
	return this->coeff_mult;
}

double Noise_Generator::get_noise(){
	return this->noise;
}

void Noise_Generator::update_gaussian(){
    double gauss;
    double rand1;
    double rand2;
    double pi = 3.141592653589793238462643383;

    rand1 = (double)rand()/(double)(RAND_MAX + 1);
    rand2 = (double)rand()/(double)(RAND_MAX + 1);
    gauss = sigma * sqrt(-2.0*log(1.0-rand1)) * cos(2.0*pi*rand2)+m;

    this->set_noise(coeff_mult*gauss);
}

