/*
 * Mass_CA1_Lumped.h
 *
 *  Created on: Nov 24, 2015
 *      Author: mconnolly
 */

#ifndef MASS_CA1_LUMPED_H_
#define MASS_CA1_LUMPED_H_

#include "Mass_HPC_Lumped.h"
#include "Mass_CA3_Lumped.h"

class Mass_CA3_Lumped;

class Mass_CA1_Lumped : public Mass_HPC_Lumped {

	double v_E, i_E, dv_E, di_E;
	double v_Pyr, i_Pyr, dv_Pyr, di_Pyr;
	double v_IS1, i_IS1, dv_IS1, di_IS1;
	double v_IF1, i_IF1, dv_IF1, di_IF1;
	double v_IS2, i_IS2, dv_IS2, di_IS2;
	double v_IF2, i_IF2, dv_IF2, di_IF2;
	std::vector<Mass_CA3_Lumped *> 	schaffer_afferents;
	std::vector<double> 			schaffer_afferent_weight;

	std::vector<Mass_CA1_Lumped *> 	lateral_afferents;
	std::vector<double> 			lateral_afferent_weight;

public:
	Mass_CA1_Lumped();
	virtual ~Mass_CA1_Lumped();

	void update_ode();
	void update_state(double dt);

	double get_feedback_v();
	double get_lateral_v();
	double get_lfp();

	std::vector<Mass_CA3_Lumped *> 	get_schaffer_afferents();
	std::vector<double> 				get_schaffer_afferent_weight();
	std::vector<Mass_CA1_Lumped *> get_lateral_afferents();
	std::vector<double> get_lateral_afferent_weight();

	void set_schaffer_afferents(std::vector<Mass_CA3_Lumped *> schaffer_afferents);
	void set_schaffer_afferent_weight(std::vector<double> schaffer_afferent_weight);

	void add_schaffer_afferent(Mass_CA3_Lumped*, double);
	void add_lateral_afferent(Mass_CA1_Lumped* lateral_afferent, double lateral_afferent_weight);

};

#endif /* MASS_CA1_LUMPED_H_ */
