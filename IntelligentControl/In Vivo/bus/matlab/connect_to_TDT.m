function TD = connect_to_TDT()
    device_name = '';
    counter = 1;
    while strcmp(device_name,'')
        TD = actxserver('TDevAcc.X');
        TD.ConnectServer('Local');
        device_name = TD.GetDeviceName(0)
        pause(0.1);
        counter
        counter = counter + 1;
    end
end