/*
 * Sigma.cpp
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#include <math.h>

#include "Sigma.h"

double Sigma::e0;
double Sigma::v0;
double Sigma::r;

Sigma::Sigma(){

}

Sigma::Sigma(double e0, double v0, double r) {
	this->e0 	= e0;
	this->v0 	= v0;
	this->r 	= r;
}

Sigma::~Sigma() {
	this->e0 	= 0;
	this->v0 	= 0;
	this->r 	= 0;
}

double Sigma::spike_density(double v){
    return 2*e0/(1+exp(r*(v0-v))) ;
}

double Sigma::get_e0(){
	return e0;
}

double Sigma::get_v0(){
	return this->v0;
}

double Sigma::get_r(){
	return this->r;
}

void Sigma::set_v0(double v0){
	Sigma::v0 = v0;
}

void Sigma::set_e0(double e0){
	Sigma::e0 = e0;
}

void Sigma::set_r(double r){
	Sigma::r = r;
}
