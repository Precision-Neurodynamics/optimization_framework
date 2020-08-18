/*
 * Mass_Lumped_HPC.cpp
 *
 *  Created on: Nov 24, 2015
 *      Author: mconnolly
 */

#include "Mass_HPC_Lumped.h"


Mass_HPC_Lumped::Mass_HPC_Lumped() {
	stimulation = 0;
}

Mass_HPC_Lumped::~Mass_HPC_Lumped() {
	// TODO Auto-generated destructor stub
}

// Getters
double Mass_HPC_Lumped::get_A()  	{return this->A;}
double Mass_HPC_Lumped::get_B()  	{return this->B;}
double Mass_HPC_Lumped::get_G()  	{return this->G;}

double Mass_HPC_Lumped::get_a()  	{return this->a;}
double Mass_HPC_Lumped::get_b()  	{return this->b;}
double Mass_HPC_Lumped::get_g() 	{return this->g;}

double Mass_HPC_Lumped::get_C1()  	{return this->C1;}
double Mass_HPC_Lumped::get_C2()  	{return this->C2;}
double Mass_HPC_Lumped::get_C3()  	{return this->C3;}
double Mass_HPC_Lumped::get_C4()  	{return this->C4;}
double Mass_HPC_Lumped::get_C5()  	{return this->C5;}
double Mass_HPC_Lumped::get_C6()  	{return this->C6;}
double Mass_HPC_Lumped::get_C7()  	{return this->C7;}

double Mass_HPC_Lumped::get_stimulation() {return this->stimulation;}
std::vector<Mass_HPC_Lumped *>& Mass_HPC_Lumped::get_lateral_afferents(){
	return this->lateral_afferents;
}

std::vector<double> Mass_HPC_Lumped::get_lateral_afferent_weight(){
	return this->lateral_afferent_weight;
}

Noise_Generator* Mass_HPC_Lumped::get_noise_afferent(){
	return this->noise_afferent;
}

double Mass_HPC_Lumped::get_noise_afferent_weight(){
	return this->noise_afferent_weight;
}

// Setters
void Mass_HPC_Lumped::set_A(double A) {this->A = A;}
void Mass_HPC_Lumped::set_B(double B) {this->B = B;}
void Mass_HPC_Lumped::set_G(double G) {this->G = G;}

void Mass_HPC_Lumped::set_a(double a) {this->a = a;}
void Mass_HPC_Lumped::set_b(double b) {this->b = b;}
void Mass_HPC_Lumped::set_g(double g) {this->g = g;}

void Mass_HPC_Lumped::set_C1(double C1) {this->C1 = C1;}
void Mass_HPC_Lumped::set_C2(double C2) {this->C2 = C2;}
void Mass_HPC_Lumped::set_C3(double C3) {this->C3 = C3;}
void Mass_HPC_Lumped::set_C4(double C4) {this->C4 = C4;}
void Mass_HPC_Lumped::set_C5(double C5) {this->C5 = C5;}
void Mass_HPC_Lumped::set_C6(double C6) {this->C6 = C6;}
void Mass_HPC_Lumped::set_C7(double C7) {this->C7 = C7;}

void Mass_HPC_Lumped::set_stimulation(double stimulation){this->stimulation = stimulation;}

void Mass_HPC_Lumped::set_lateral_afferents(std::vector<Mass_HPC_Lumped *> lateral_afferents){
	this->lateral_afferents = lateral_afferents;
}

void Mass_HPC_Lumped::set_lateral_afferent_weight(std::vector<double> lateral_afferent_weight){
	this->lateral_afferent_weight = lateral_afferent_weight;
}

void Mass_HPC_Lumped::add_lateral_afferent(Mass_HPC_Lumped* lateral_afferent, double lateral_afferent_weight){
	// TODO - Initialize vector if not created
	this->lateral_afferents.push_back(lateral_afferent);
	this->lateral_afferent_weight.push_back(lateral_afferent_weight);

}

void Mass_HPC_Lumped::add_noise_afferent(Noise_Generator* noise_afferent, double noise_afferent_weight){
	// TODO - generalize into vector
	this->noise_afferent = noise_afferent;
	this->noise_afferent_weight = noise_afferent_weight;
}
