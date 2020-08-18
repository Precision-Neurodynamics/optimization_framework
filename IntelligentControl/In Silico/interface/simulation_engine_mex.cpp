/*
 * mexmodelwrapper.cpp
 *
 *  Created on: Aug 23, 2015
 *      Author: mconnolly
 */

#include "mex.h"
#include "../simulation_engine/Sigma.h"
#include "../simulation_engine/Mass_CA3_Lumped.h"
#include "../simulation_engine/NoiseGenerator.h"
#include "../simulation_engine/CA3CA1Model.h"
#include <stdio.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <fenv.h>

void mexFunction(
		 int          nlhs,
		 mxArray      *plhs[],
		 int          nrhs,
		 const mxArray *prhs[]
		 )
{
	if (nrhs != 6) {
	mexErrMsgIdAndTxt("MATLAB:mexcpp:nargin",
			"MEXCPP requires three input arguments.");
	}

	double *simulation_parameters = mxGetPr(prhs[5]);

	double t_end 	= simulation_parameters[0];
	double f_sample = simulation_parameters[1];
	int n_samples 	= (int) t_end*f_sample;

	double 	v0 	= 6.0;
	double 	e0 	= 2.5;
	double 	r 	= 0.56;

	Sigma::set_v0(v0);
	Sigma::set_e0(e0);
	Sigma::set_r(r);

	CA3_CA1_Model ca3_ca1_model(prhs);

	int n_channels = ca3_ca1_model.get_n_channels();

	plhs[0]   				= mxCreateDoubleMatrix(n_samples, n_channels, mxREAL);
	double * outputMatrix 	= (double *)mxGetData(plhs[0]);
//
//	// Allow system to stabilize

	double lfp[n_channels];

	for(int c1 = 0; c1 < f_sample;c1++){
		ca3_ca1_model.update_noise();
		ca3_ca1_model.update_ode();
		ca3_ca1_model.update_state(1./f_sample);
	}

	for(int c1 = 0; c1 < n_samples;c1++){
		ca3_ca1_model.update_noise();
		ca3_ca1_model.update_ode();
		ca3_ca1_model.update_state(1./f_sample);

		ca3_ca1_model.get_lfp(lfp);

		for(int c2 = 0; c2 < n_channels; c2++){
			outputMatrix[c1 + c2*n_samples] = lfp[c2];
              if(lfp[c2] != lfp[c2])
                        return;
		}

	}
//

	return;
}


//		if(sim_time > stimulation_start && sim_time < stimulation_stop){
//
//			printf("time = %f \n", sim_time);
//
//			if(fmod(sim_time,1./f_stimulation) < 1./200){
//				CA3_row[stimulation_channel]->set_stimulation(stimulation_amplitude);
//			}else if(fmod(sim_time,1./f_stimulation) < 1./100){
//				CA3_row[stimulation_channel]->set_stimulation(-1.0*stimulation_amplitude);
//			}else{
//				CA3_row[stimulation_channel]->set_stimulation(0.0);
//			}
//
//		}else{
//			CA3_row[stimulation_channel]->set_stimulation(0.0);
//		}


