function api = basicSkeleton(h_group, draw_api, positionConstraintFcn)

    %h_fig = iptancestor(h_group,'figure');
    %h_axes = iptancestor(h_group,'axes');

    position = [];
    
    dispatchAPI = roiCallbackDispatcher(@getPosition);
    
    draw_api.initialize(h_group);
    
    color_choices = iptui.getColorChoices();
    draw_api.setColor(color_choices(1).Color);
    
    % Alias updateView.
    updateView = draw_api.updateView;
    
    api.addNewPositionCallback    = dispatchAPI.addNewPositionCallback;
    api.removeNewPositionCallback = dispatchAPI.removeNewPositionCallback;
    api.setPosition               = @setPosition;
    api.setConstrainedPosition    = @setConstrainedPosition;
    api.getPosition               = @getPosition;
    api.delete                    = @deleteSkeleton;
    api.getPositionConstraintFcn  = @getPositionConstraintFcn;
    api.setPositionConstraintFcn  = @setPositionConstraintFcn;
    api.updateView                = draw_api.updateView;
    api.setVisible                = draw_api.setVisible;
    
    %----------------------------------------------------------------------
    function deleteSkeleton(varargin)
        
        if ishghandle(h_group)
            delete(h_group)
        end
    end

    function pos = getPosition
        
        pos = position;
    end

    function setPosition(pos)
        
        position = pos;
        updateView(pos);
        
        try
            dispatchAPI.dispatchCallbacks('newPosition');
        catch ME
            rethrow(ME);
        end
    end

    function setConstrainedPosition(pos)
        
        pos = positionConstraintFcn(pos);
        setPosition(pos);        
    end

    function setPositionConstraintFcn(fun)
        
        positionConstraintFcn = fun;        
    end

    function fh = getPositionConstraintFcn
        
        fh = positionConstraintFcn;
    end
end