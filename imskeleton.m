%IMSKELETON Create draggable, resizable skeleton.

classdef imskeleton < imroi

methods
	function obj = imskeleton(varargin)
		%imskeleton constructor for imskeleton.

		[h_group, draw_api] = imskeletonAPI(varargin{:});
		obj = obj@imroi(h_group, draw_api);
	end

	function setPosition(obj, varargin)
		%setPosition  Set skeleton to new position.
        %
        %   setPosition(h,pos) sets the skeleton h to a new position. The
        %   new position, pos, has the form [X1 Y1; X2 Y2; ...].
        %
        %   setPosition(h,x,y) sets the skeleton h to a new
        %   position. x and y specify the endpoint
        %   positions of the skeleton in the form x = [x1 x2 ...], y = [y1 y2 ...].

        narginchk(2, 3);
        
        if length(varargin) == 1
            pos = varargin{1};
            invalidPosition = ~isequal(size(pos), [obj.draw_api.njoints 2]) || ~isnumeric(pos);
            if invalidPosition
                error(message('images:imskeleton:invalidPositionSizeOrClass'));
            end
        elseif length(varargin) == 2
            x = varargin{1};
            y = varargin{2};

            isInvalidXYVector = @(v) ~isvector(v) || length(v) ~= obj.draw_api.njoints || ~isnumeric(v);
            if isInvalidXYVector(x) || isInvalidXYVector(y)
                error(message('images:imskeleton:invalidPositionNotVector'));
            end
            
            pos = [reshape(x, obj.draw_api.njoints, 1), reshape(y, obj.draw_api.njoints, 1)];
        end

        obj.api.setPosition(pos);
	end

	function pos = getPosition(obj)
		%getPosition  Return current position of skeleton.
        %
        %   pos = getPosition(h) returns the current position of the
        %   skeleton h. The returned position, pos, is a njoints-by-2 array 
        %   [x1 y1; x2 y2; ...].

		pos = obj.api.getPosition();
	end

	function setConstrainedPosition(obj,pos)
        %setConstrainedPosition  Set ROI object to new position.
        %
        %   setConstrainedPosition(h,candidate_position) sets the ROI
        %   object h to a new position.  The candidate position is
        %   subject to the position constraint function.
        %   candidate_position is of the form expected by the
        %   setPosition method.
        
        obj.api.setConstrainedPosition(pos);
    end
    
    function setVerticesDraggable(obj, TF)
        %setVerticesDraggable Control whether vertices may be dragged.
        %
        %   setVerticesDraggable(h,TF) sets the interactive behavior of
        %   the vertices of the skeleton h. TF is a logical scalar. True
        %   means that the skeleton of the skeleton are draggable. False
        %   means that the skeleton of the skeleton are not draggable.
        obj.api.setVerticesDraggable(TF);
    end

    % dummy function
    %function BW = createMask(varargin)
        %createMask  Create a mask within an image.
        %
        %   BW = createMask(h) returns a mask that is associated with
        %   the point object h over the target image. The target image
        %   must be contained within the same axes as the point. BW is a
        %   logical image the same size as the target image. BW is false
        %   outside the region of interest and true inside.
        %
        %   BW = createMask(h,h_im) returns a mask that is associated
        %   with the point object h over the image h_im. This syntax is
        %   required when the parent of the point contains more than
        %   one image.
        
        % [obj,h_im] = parseInputsForCreateMask(varargin{:});
        % [roix,roiy,m,n] = obj.getPixelPosition(h_im);
        % [x,y] = iptui.intline(roix(1),roix(end), roiy(1), roiy(end));
        % x = round(x);
        % y = round(y);
        % BW = false(m,n);
        % ind = sub2ind([m n],y,x);
        % BW(ind) = true;
    %end
end

methods (Access = 'protected')

	function cmenu = getVertexContextMenu(obj)
		cmenu = obj.api.getVertexContextMenu();
	end

	function setVertexContextMenu(obj, cmenu)
		obj.api.setVertexContextMenu(cmenu);
    end
end

end

function [h_group, draw_api] = imskeletonAPI(varargin)

    commonArgs = roiParseInputs(0, 2, varargin, mfilename, {});

    xy_position_vectors_specified = (nargin > 2) && ...
                                    isnumeric(varargin{2}) && ...
                                    isnumeric(varargin{3});
    
    if xy_position_vectors_specified
        error(message('images:imskeleton:invalidPosition'))
    end

    position              = commonArgs.Position;
    interactive_placement = commonArgs.InteractivePlacement;
    h_parent              = commonArgs.Parent;
    h_axes                = commonArgs.Axes;
    h_fig                 = commonArgs.Fig;

    position_constraint_function = commonArgs.PositionConstraintFcn;

    if isempty(position_constraint_function)
        % constraint_function is used by dragMotion() to give a client the
        % opportunity to constrain where the skeleton can be dragged.
        position_constraint_function = identityFcn;
    end

    try
        h_group = hggroup('Parent', h_parent,...
                          'Tag','imskeleton',...
                          'DeleteFcn',@deleteContextMenu);
    catch ME
        error(message('images:imskeleton:failureToParent'));
    end

    draw_api = skeletonSymbol();
    
    basicAPI = basicSkeleton(h_group, draw_api, position_constraint_function);
    
    % Handles to each of the skeleton vertices
    h_vertices = {};
    
    % Handle to currently active vertex
    h_active_vertex = [];
    
    % Alias functions defined in basicSkeletonAPI to shorten calling syntax
    % in imskeleton.
    setPosition             = basicAPI.setPosition;
    setConstrainedPosition  = basicAPI.setConstrainedPosition;
    getPosition             = basicAPI.getPosition;
    setVisible              = basicAPI.setVisible;
    updateView              = basicAPI.updateView;
    addNewPositionCallback  = basicAPI.addNewPositionCallback;
    deleteSkeleton          = basicAPI.delete;
    
    if interactive_placement
        setVisible(true);
    else
        setPosition(position);
        
        h_vertices = cell(1, draw_api.njoints);
        
        for i = 1:draw_api.njoints
            h_vertices{i} = iptui.impolyVertex(h_group, position(i, 1), position(i, 2));
        
            % Re-tag impoint vertices to allow for workaround
            set(h_vertices{i}, 'tag', 'imskeleton vertex');

            children = get(h_vertices{i}, 'Children');
            set(children(1), 'Marker', 'o');
            
            % This is necessary to ensure that vertices are drawn with the
            % right color when setPosition alters the number of vertices
            % via updateVertexPositions
            h_vertices{i}.setColor([0 0 0]); % set color
            
            % This pattern is done twice, however performance is better inline
            % than as a separate subfunction.
            addlistener(h_vertices{i}, 'ImpointButtonDown', ...
                @(vert,data) vertexButtonDown(getVertexHGGroup(vert)));
            
            addlistener(h_vertices{i}, 'ImpointDragged', ...
                @(vert,data) vertexDragged(vert.getPosition()));
            
%             iptSetPointerBehavior(h_vertices{i},...
%                 @(h_fig,loc) set(h_fig,'Pointer','circle'));
        end
    end
    
    if ~isempty(position) && ~isequal(size(position), [draw_api.njoints 2])
        error(message('images:imskeleton:invalidPosition'));   
    end

    % Set up listener to store current mouse position on button down. Need to
    % consistently use two argument form of hittest with same current position
    % information to ensure that mouse affordances and button down gestures
    % are in sync.

    % button down listener on the figure to cache current point
    %setappdata(h_group,'ButtonDownListener',...
    %    iptui.iptaddlistener(h_fig,...
    %    'WindowMousePress',@buttonDownEventFcn));

    %setappdata(h_group,'ButtonUpListener',...
    %    iptui.iptaddlistener(h_fig,...
    %    'WindowMouseRelease',@buttonUpEventFcn));
    %buttonUp = false;

    % Function scope variable used to generalize stopDrag.
%   dragFcn = [];

    % cmenu needs to be in an initialized state for setColor to be called within
    % createROIContextMenu
    cmenu_skeleton = [];
    cmenu_vertices = [];

    cmenu_skeleton = createROIContextMenu(h_fig, getPosition, @setColor);
    setContextMenu(cmenu_skeleton);
    
    cmenu_vertices = createVertexContextMenu();
    setVertexContextMenu(cmenu_vertices);
    
    % Alias functions defined in skeletonAPI to shorten calling syntax in
    % imskeleton
    api.setPosition                 = setPosition;
    api.setConstrainedPosition      = setConstrainedPosition;
    api.getPosition                 = getPosition;
    api.addNewPositionCallback      = addNewPositionCallback;
    api.delete                      = deleteSkeleton;
    api.setVerticesDraggable        = draw_api.showVertices;
    api.removeNewPositionCallback   = basicAPI.removeNewPositionCallback;
    api.getPositionConstraintFcn    = basicAPI.getPositionConstraintFcn;
    api.setPositionConstraintFcn    = basicAPI.setPositionConstraintFcn;
    api.setColor                    = @setColor;

    % Undocumented API methods
    api.setContextMenu             = @setContextMenu;
    api.getContextMenu             = @getContextMenu;
    api.setVertexContextMenu       = @setVertexContextMenu;
    api.getVertexContextMenu       = @getVertexContextMenu;

    % Grandfathered API methods
    %api.setDragConstraintFcn      = @setPositionConstraintFcn;
    %api.getDragConstraintFcn      = @getPositionConstraintFcn;

    iptsetapi(h_group, api)

    updateView(getPosition());

    % Create update function that knows how to get the position it needs when it
    % will be called from HG contexts where it may not have access to the position
    % otherwise.
    %update_fcn = @(varargin) updateView(api.getPosition());

    %updateAncestorListeners(h_group, update_fcn);
    
    %----------------------------------------------------------------------
    function setColor(color)
        if ishghandle(getContextMenu())
            updateColorContextMenu(getVertexContextMenu(), color);
            updateColorContextMenu(getContextMenu(), color);
        end
        draw_api.setColor(color);
    end
      
    %--------------------------------- 
    function setContextMenu(cmenu_new)
       
       %In order for IMDISTLINE to be draggable in IMTOOL, the HitTest property
       %of the hg objects created by SekeletonSymbol() must be set to 'on'.
       %this requires that the context menu be associated with the skeleton objects
       %rather than the h_group.
       cmenu_obj = findobj(h_group, 'Type', 'skeleton'); 
       set(cmenu_obj, 'uicontextmenu', cmenu_new);
       
       cmenu_skeleton = cmenu_new;
    end
    
    %-------------------------------------
    function context_menu = getContextMenu
       
        context_menu = cmenu_skeleton;
    end

    function setVertexContextMenu(cmenu_new)
       
        for i = 1:draw_api.njoints
           set(getVertexHGGroup(h_vertices{i}),'UIContextMenu',cmenu_new); 
        end
        
        cmenu_vertices = cmenu_new;
    end

    function vertex_cmenu = getVertexContextMenu
        
        % All of the vertices in the skeleton shares the same UIContextMenu
        % object. Obtain the shared uicontextmenu from the first vertex in
        % the skeleton.
        vertex_cmenu = get(getVertexHGGroup(h_vertices{1}), 'UIContextMenu');
    end

    %-----------------------------------
    function deleteContextMenu(varargin)
        
        if ishghandle(cmenu_skeleton)
            delete([cmenu_skeleton cmenu_vertices]);
        end
    end
    
    %--------------------------------------------
    function completed = placeSkeleton(x, y)
         %shoh
    end

    %function setVertexPointerBehavior
    %    
    %    for i = 1:draw_api.njoints
    %        iptSetPointerBehavior(h_vertices{i}, ...
    %            @(h_fig, loc) set(h_fig, 'Pointer', 'circle'));
    %    end
    %end

    function h_group = getVertexHGGroup(p)
        
        h_group = findobj(p, 'type', 'hggroup');
    end

    function updateVertexPositions(pos)
        % This function is called whenever the position of the skeleton
        % changes. This function manages each impoint vertex instance to
        % keep each vertex in the appropriate position.
        
        if size(pos, 1) == draw_api.njoints
            for i = 1:draw_api.njoints
                h_vertices{i}.setPosition(pos(i, :));
            end
        end
    end

    %----------------------------------------------------------------------
    function idx = getActiveVertexIndex
        getActiveVertexIndex = @(p) isequal(getVertexHGGroup(p), h_active_vertex);
        idx = cellfun(getActiveVertexIndex, h_vertices);
    end

    function vertexDragged(pos)
        
        candidate_position = getPosition();
        candidate_position(getActiveVertexIndex(), :) = pos;
        
        setConstrainedPosition(candidate_position);
    end

    function vertexButtonDown(vert)
        
        h_active_vertex = vert;
    end

    function vertex_cmenu = createVertexContextMenu
        % createVertexContextMenu creates a single context menu at the figure level
        % that is shared by all of the impoint instances used to define
        % vertices.
        
        vertex_cmenu = createROIContextMenu(h_fig, getPosition, @setColor);
    end
end