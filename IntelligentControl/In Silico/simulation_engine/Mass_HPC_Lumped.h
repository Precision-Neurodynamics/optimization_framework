/*
 * Mass_Lumped HPC.h
 *
 *  Created on: Nov 24, 2015
 *      Author: mconnolly
 */

#ifndef MASS_HPC_LUMPED_H_
#define MASS_HPC_LUMPED_H_

#include "Mass.h"
#include "NoiseGenerator.h"

class Mass_HPC_Lumped : public Mass {

	double A, B, G;
	double a, b, g;

	double C1, C2, C3, C4, C5, C6, C7;

	double stimulation;
	double lfp;

	std::vector<Mass_HPC_Lumped *> 	lateral_afferents;
	std::vector<double> 			lateral_afferent_weight;

	Noise_Generator 				*noise_afferent;
	double 							noise_afferent_weight;
public:
	Mass_HPC_Lumped();
	virtual ~Mass_HPC_Lumped();

	void set_A(double A);
	void set_B(double B);
	void set_G(double G);

	void set_a(double a);
	void set_b(double b);
	void set_g(double g);

	void set_C1(double C1);
	void set_C2(double C2);
	void set_C3(double C3);
	void set_C4(double C4);
	void set_C5(double C5);
	void set_C6(double C6);
	void set_C7(double C7);

	void set_stimulation(double stimulation);

	void set_lateral_afferents(std::vector<Mass_HPC_Lumped *> lateral_afferents);
	void set_lateral_afferent_weight(std::vector<double> lateral_afferent_weight);

	double get_A();
	double get_B();
	double get_G();

	double get_a();
	double get_b();
	double get_g();

	double get_C1();
	double get_C2();
	double get_C3();
	double get_C4();
	double get_C5();
	double get_C6();
	double get_C7();

	double get_stimulation();
	virtual double get_lfp() = 0;
	virtual double get_lateral_v() = 0;
	std::vector<Mass_HPC_Lumped *>& get_lateral_afferents();
	std::vector<double> get_lateral_afferent_weight();

	Noise_Generator* get_noise_afferent();
	double get_noise_afferent_weight();

	void add_lateral_afferent(Mass_HPC_Lumped* lateral_afferent, double lateral_afferent_weight);
	void add_noise_afferent(Noise_Generator* noise_afferent, double noise_afferent_weight);
};


#endif /* MASS_HPC_LUMPED_H_ */
