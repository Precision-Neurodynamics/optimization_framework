classdef TPROT < handle
    %TPROT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FS
        
        time_since_last_read
        stimulation
        curr_index
        read_buffer_size
        
        stim_trig
        stim_done
    end
    
    methods
        
        function obj = TPROT()
            obj.FS = {6103.52};
            obj.curr_index = 1;
            obj.read_buffer_size = obj.FS{1}*1;
            obj.stimulation = cell(16,1);
        end
            
        function write(obj,tag, arg)
            if strcmp(tag, 'read_durr')
                  
                obj.read_buffer_size = arg;
                
            elseif length(tag) > 10 && strcmp(tag(1:10),'stim_buff~')
                
                channel = str2double(tag(11:end));  
                obj.stimulation{channel} = arg;
                
            elseif strcmp(tag, 'dur~');
                
            end 
        end
        
        function value = read(obj,tag, arg, n_buff_pts, varargin)
            
            if strcmp(tag,'read_index')
                
                value           = obj.curr_index;
                obj.curr_index  = mod(obj.curr_index + obj.read_buffer_size/5,obj.read_buffer_size);

                pause(obj.FS{1}/(obj.read_buffer_size/16)/10);
            
            elseif strcmp(tag, 'read_buff')
                    
                value = get_signal(obj,n_buff_pts);
                
            elseif strcmp(tag(1:9), 'not_done~')
%                 channel = str2double(tag(10:end));
%                 
%                 if isempty(obj.stimulation{channel})
%                     value = 0;
%                 else
%                     value = 1;
%                 end
%                     
            end   
        end
        
        function values = get_signal(obj, n_points)
            
            values = rand(16,n_points/16);
            
            stim_channels   = size(obj.stimulation,1);
            
            for c2 = 1:stim_channels
                stimulation_signal  = obj.stimulation{c2};
                stimulation_length  = size(stimulation_signal,2);
                
                stimulation_signal(stimulation_signal > 300) = 0;
                if  stimulation_length > n_points/16
                    
                    values(c2,:)        = values(c2,:) + stimulation_signal(:,1:n_points/16);
                    obj.stimulation{c2} = obj.stimulation{c2}(:,n_points/16+1:end);
               
                else
                    
                    if ~isempty(obj.stimulation{c2})
                        values(c2,1:stimulation_length) = values(c2,1:stimulation_length) + stimulation_signal(:,1:end);
                        obj.stimulation{c2}             = [];
                    end
                    
                end
            end
                values = reshape(values,1,n_points);
        end
        
        function trig(obj, tag)

        end
    end
    
    methods(Static)
        function record(~)
            
        end
    end
    
end

