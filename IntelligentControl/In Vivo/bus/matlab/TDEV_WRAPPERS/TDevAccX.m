TD = actxcontrol('TDevAcc.X');
TD.ConnectServer('Local');
if (TD.GetSysMode == 2 || TD.GetSysMode == 3) 
    TD.SetSysMode(3)
    pause(3)
end
TD.CloseConnection