/*
 * Mass.cpp
 *
 *  Created on: Aug 24, 2015
 *      Author: mconnolly
 */

#include "Mass.h"

Mass::Mass() {

}

Mass::~Mass() {

}

void Mass::update_ode(){
	for(int c1 = 0; c1 < this->get_populations().size(); c1++){
//		printf("mass populations size = %lu\n", this->get_populations().size() );
//		printf("pop 0 has index %d \n", this->get_populations()[c1]->get_index());
		this->get_populations()[c1]->update_ode();
	}

}

void Mass::update_state(double dt){
	for(int c1 = 0; c1 < this->get_populations().size(); c1++){
		this->get_populations()[c1]->update_state(dt);
	}
}

std::vector<Population *> Mass::get_populations(){
	return this->populations;
}
