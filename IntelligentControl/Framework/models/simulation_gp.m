classdef simulation_gp < handle
    %SIMULATION_GP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gp_model
        current_state
        
        min_state
        max_state
        
        lower_bound
        upper_bound
    end
    
    methods
        
        function initialize_data(obj, x_data, y_data, lower_bound, upper_bound)
            obj.gp_model = gp_object;
            obj.gp_model.initialize_data(x_data, y_data, min(x_data), max(x_data))
            
            obj.min_state   = min(x_data(:,1));
            obj.max_state   = max(x_data(:,1));
            
            obj.lower_bound = lower_bound;
            obj.upper_bound = upper_bound;
            obj.set_initial_state();
        end
        
        function initialize(obj, gp_model)
            
            obj.gp_model            = gp_model;           
            obj.set_initial_state();

            obj.lower_bound         = min(gp_model.x_data(:,2:end));
            obj.upper_bound         = max(gp_model.x_data(:,2:end));
            
            obj.min_state           = min(gp_model.x_data(:,1));
            obj.max_state           = max(gp_model.x_data(:,1));
        end
        
        function set_initial_state(obj)
            [y_mean, y_std, mu_ci]  = normfit(obj.gp_model.x_data(:,1));            
            obj.current_state       = normrnd(y_mean, y_std/2);
        end
        
        function new_state = sample(obj, stim_params)
            
            new_state             = obj.gp_model.sample([obj.current_state stim_params]);
            
%             new_state               = obj.current_state + delta_state;
            new_state               = max(new_state, obj.min_state);
            new_state               = min(new_state, obj.max_state);
            
            obj.current_state       = new_state;
        end
        
        function state_est = predict_state(obj, stim_params)
            current_state           = repmat(obj.current_state,size(stim_params,1),1);
           
            delta_state             = obj.gp_model.predict([current_state stim_params]);
            new_state               = obj.current_state + delta_state;
            state_est               = max(new_state, obj.min_state);
        end
        
        function max_stim = state_aquisition(obj, current_state)
            t1 = linspace(obj.lower_bound(1),obj.upper_bound(1),100);
            t2 = linspace(obj.lower_bound(2),obj.upper_bound(2),100);
            t  = combvec(t1,t2)';
            
            current_state           = repmat(current_state,size(t,1),1);

            
            [y_prediction, y_standard_deviation, fmu, fs2] = obj.gp_model.predict([current_state t]);
            yp              = reshape(y_prediction, 100, 100)';
           
            y_acquisition   = obj.gp_model.upper_confidence_bound([current_state t],obj.gp_model, .2);
            ya              = reshape(y_acquisition, 100, 100)';
            
            [max_aq, max_aq_idx] = min(y_acquisition);
            max_stim = t(max_aq_idx,:);
        end
        
        function max_stim = state_extrema(obj, current_state)
            t1 = linspace(obj.lower_bound(1),obj.upper_bound(1),100);
            t2 = linspace(obj.lower_bound(2),obj.upper_bound(2),100);
            t  = combvec(t1,t2)';
            
            current_state           = repmat(current_state,size(t,1),1);

            
            [y_prediction, y_standard_deviation, fmu, fs2] = obj.gp_model.predict([current_state t]);
            
            [max_yp, max_yp_idx] = max(y_prediction);
            max_stim = t(max_yp_idx,:);
        end
    end
    
end

