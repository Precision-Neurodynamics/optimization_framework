function block_name = get_block_name_opto(tank_name)
    TT = actxserver('TTANK.X');
    TT.ConnectServer('Local', 'Me');
    TT.OpenTank([tank_name],'R');
    block_name = '';
    while strcmp(block_name, '')        
        block_name = TT.GetHotBlock
    end
end
