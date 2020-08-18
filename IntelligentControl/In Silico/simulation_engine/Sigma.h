/*
 * Sigma.h
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#ifndef SIGMA_H_
#define SIGMA_H_

class Sigma {

	static double e0;
	static double v0;
	static double r;

public:
	Sigma();
	Sigma(double e0, double v0, double r);
	virtual ~Sigma();

	static double spike_density(double v);

	double get_e0();
	double get_v0();
	double get_r();

	static void set_v0(double v0);
	static void set_e0(double e);
	static void set_r(double rs);
};

//double Sigma::e0;
//double Sigma::v0;
//double Sigma::r;

#endif /* SIGMA_H_ */
