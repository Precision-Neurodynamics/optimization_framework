function [animal_id, experiment_name] = get_experiment_info(DEBUG)
default_ans         = {'000', 'test_experiment'};

if DEBUG
    animal_id       = default_ans{1};
    experiment_name = [default_ans{2} 'DEBUG'];
else
    prompt          = {'Animal ID:', 'Experiment Name:'};
    dlg_title       = 'Experiment Information';
    answer          = inputdlg(prompt, dlg_title,1,default_ans );

    animal_id       = answer{1};
    experiment_name = answer{2};
end

end