/*
 * main.cpp
 *
 *  Created on: Aug 25, 2015
 *      Author: mconnolly
 */

#include "../simulation_engine/Sigma.h"
#include "../simulation_engine/Mass_CA3_Lumped.h"
#include "../simulation_engine/NoiseGenerator.h"
#include <stdio.h>
#include <vector>
#include <iostream>
#include <fstream>

int main(){
	std::vector<Mass_CA3_Lumped *> CA3_row(4);
	std::vector<Mass_CA1_Lumped *> CA1_row(4);

	double A1 = 3.5;
	double B1 = 20.;
	double G1 = 10.;

	double a = 100.;
	double b = 30.;
	double g = 350.;

	double C1 = 135.0;
	double C2 = 108.0;
	double C3 = 33.75;
	double C4 = 33.75;
	double C5 = 40.5;
	double C6 = 13.5;
	double C7 = 108.0;

	double schaffer_weight = 135;
	double feedback_weight = 135;
	double lateral_weight = 55;

	double amp 	= .005;
	double sfs 	= 110;
	int ch 		= 1;

	double t_end 	= 21;
	double fs 		= 3051;
	int n_samples 	= (int) t_end*fs;

	double 	v0 	= 6.0;
	double 	e0 	= 2.5;
	double 	r 	= 0.56;

	// ==CA3 Row==
	// -----1-----

	for(int c1 = 0; c1 < CA3_row.size(); c1++){
		CA3_row[c1] = new Mass_CA3_Lumped;
	}

	for(int c1 = 0; c1 < CA1_row.size(); c1++){
		CA1_row[c1] = new Mass_CA1_Lumped;
	}

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
	}

//	CA3_row[0]->set_A(A2);
//	CA3_row[0]->set_B(B2);
//	CA3_row[0]->set_G(G2);

	Sigma::set_v0(v0);
	Sigma::set_e0(e0);
	Sigma::set_r(r);

	FILE *myfile;
	myfile = fopen ("/Users/mconnolly/Google Drive/Research/Neural Mass Model/CA1-CA3_Model/example2.csv", "w");

	double time = 0;
	for(int c1 = 0; c1 < n_samples; c1++){
		time += 1./fs;

		if(time > 2 && time < 7){

			if(fmod(time,1./sfs) < 1./200){
				CA3_row[ch]->set_stimulation(amp);
			}else if(fmod(time,1./sfs) < 1./100){
				CA3_row[ch]->set_stimulation(-1.0*amp);
			}else{
				CA3_row[ch]->set_stimulation(0.0);
			}

		}else{
			CA3_row[0]->set_stimulation(0.0);
		}


		for(int c1 = 0; c1 < CA3_row.size(); c1++){
			CA3_row[c1]->update_ode();
		}

		for(int c1 = 0; c1 < CA1_row.size(); c1++){
			CA1_row[c1]->update_ode();
		}

		for(int c1 = 0; c1 < CA3_row.size(); c1++){
			CA3_row[c1]->update_state(1./fs);
		}

		for(int c1 = 0; c1 < CA1_row.size(); c1++){
			CA1_row[c1]->update_state(1./fs);
		}

		printf("%d\n", c1);
		if(c1 > fs){
			for(int c2 = 0; c2 < CA3_row.size(); c2++){
				fprintf(myfile, "%f,", CA3_row[c2]->get_lfp());
				printf("%f,", CA3_row[c2]->get_lfp());
			}

			for(int c2 = 0; c2 < CA1_row.size(); c2++){
				fprintf(myfile, "%f,", CA1_row[c2]->get_lfp());
				printf("%f,", CA1_row[c2]->get_lfp());
			}

			fprintf(myfile, "\n");
			printf("\n");
		}
	}
	printf("nsamp %d", n_samples);
	fclose(myfile);
}






