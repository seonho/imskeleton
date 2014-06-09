function draw_api = skeletonSymbol

	[h_top_line, h_bottom_line, h_patch, h_group, ...
        mode_invariant_obj, mode_variant_obj, all_obj, ...
        show_vertices, buttonDown, line_width, ...
        current_color, h_fig] = deal([]);
    
	draw_api.getColor     = @getColor;
	draw_api.setColor     = @setColor;
    draw_api.initialize   = @initialize;
    draw_api.setVisible   = @setVisible;
	draw_api.updateView   = @updateView;
	draw_api.showVertices = @showVertices;
	draw_api.njoints      = 15;
    draw_api.topology     = [1 2;
                            2 3;
                            3 4;
                            1 5;
                            5 6;
                            6 7;
                            1 8;
                            8 9;
                            9 10;
                            10 11;
                            8 12;
                            12 13;
                            13 14;
                            8 15];
    draw_api.jointnames   = {''};

	%----------------------
	function initialize(h)

		% The line objects should have a width of one screen pixel.
		line_width = getPointsPerScreenPixel;
        h_group = h;
		show_vertices = true;

		% This is a workaround to an HG bug
		buttonDown = getappdata(h_group, 'buttonDown');

		h_patch = patch('FaceColor', 'none',...
			'EdgeColor', 'none', ...
			'HitTest', 'on', ...
			'Parent', h_group,...
			'ButtonDown', buttonDown,...
			'Tag','patch',...
			'Visible','off');

		h_fig = iptancestor(h_group, 'figure');
        
        % ...
		for i = 1:draw_api.njoints
			h_bottom_line(i) = makeBottomLine();
			h_top_line(i) = makeTopLine();
		end
    end

	%----------------------
	function setVisible(TF)

		mode_invariant_obj = [h_bottom_line, h_top_line, h_patch];
		
		if TF
			set(mode_invariant_obj,'Visible','on');
			drawModeAffordances();
		else
			mode_variant_obj = [getVertices()'];
			all_obj = [mode_invariant_obj, mode_variant_obj];
			set(all_obj,'Visible','off');
		end
	end

	function showVertices(TF)
		show_vertices = TF;
		drawModeAffordances();
	end

	function vertices = getVertices
		% This is the only way to find all impoints within h_group until
        % impoint is a real object.
		vertices = findobj(h_group,'tag','imskeleton vertex');
	end

	%-------------------
	function drawModeAffordances

		h_vertices = getVertices();

		if show_vertices
			set(h_vertices, 'Visible', 'on');
		else
			set(h_vertices, 'Visible', 'off');
		end
	end

	function h_line = makeTopLine
		h_line = line('LineStyle', '-', ...
            'LineWidth', line_width, ...
            'Color', 'r',...
            'HitTest', 'on', ...
            'ButtonDown',buttonDown,...
            'Parent', h_group,...
            'Tag','top line',...
            'Visible','on');
	end

	function h_line = makeBottomLine
		h_line = line('Color', 'w', ...
            'LineStyle', '-', ...
            'LineWidth', 3 * line_width, ...
            'HitTest', 'on', ...
            'ButtonDown', buttonDown, ...
            'Parent', h_group,...
            'Tag','bottom line',...
            'Visible','on');
	end

	%-------------------
	function setColor(c)
		%if ishghandle(h_top_line)
		%  set([h_top_line, h_end_points],'Color', c);
		%end
        
		%current_color = c;
		h_vertices = getVertices();
		set([h_top_line, h_bottom_line], 'Color', c);

		for i = 1:numel(h_vertices)
			vertex_api = iptgetapi(h_vertices(i));
			vertex_api.setColor(c);
		end
	end

	%--------------------
	function c = getColor
	 
		c = get(h_top_line,'Color');
	end

	%----------------------------
	function updateView(position)

		if ~isempty(position)
			set(h_patch, ...
				'XData', position(:, 1), ...
				'YData', position(:, 2));
		else
			set(h_patch, 'XData', [], ...
						 'YData', []);
		end

		for i = 1:draw_api.njoints - 1
			set([h_bottom_line(i), h_top_line(i)], ...
				'XData', [position(draw_api.topology(i, 1), 1), position(draw_api.topology(i, 2), 1)], ...
				'YData', [position(draw_api.topology(i, 1), 2), position(draw_api.topology(i, 2), 2)]);
		end

	    %if ~ishghandle(h_group)
	    %    return;
	    %end
	    
	    %x_pos = position(:,1);
	    %y_pos = position(:,2);
	    
	    %line_handles=[h_under_line, h_top_line];

	    %if ~isequal(get(h_top_line, 'XData'), x_pos) || ...
		%			~isequal(get(h_top_line, 'YData'), y_pos)
	    %    set(line_handles,'XData', x_pos,...
	    %        'YData', y_pos);
	        
	        %set(h_end_points(1),'XData',x_pos(1),'YData',y_pos(1));
	        %set(h_end_points(2),'XData',x_pos(2),'YData',y_pos(2));
	        
	    %end

	end
end