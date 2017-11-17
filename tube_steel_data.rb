module EA_Extensions623
  module EASteelTools
    RADIUS_RULE = 2

    class TubeTool

      # The activate method is called by SketchUp when the tool is first selected.
      # it is a good place to put most of your initialization
      def initialize(data)
        @model = Sketchup.active_model
        # Activates the @model @entities for use
        @entities = @model.active_entities
        @selection = @model.selection
        @state = 0

        values = data[:data]
        @h     = values[:h].to_f #height of the tube
        @w     = values[:b].to_f #width of the tube

        case data[:wall_thickness]
        when '1/8'
          @tw = 0.125
        when '3/16'
          @tw = 0.1875
        when '1/4'
          @tw = 0.25
        when '5/16'
          @tw = 0.3125
        when '3/8'
          @tw = 0.375
        when '1/2'
          @tw = 0.5
        when '5/8'
          @tw = 0.625
        when '3/4'
          @tw = 0.75
        when '7/8'
          @tw = 0.875
        else
          @tw = 1
        end

        @r = @tw#*RADIUS_RULE

        # The Sketchup::InputPoint class is used to get 3D points from screen
        # positions.  It uses the SketchUp inferencing code.
        # In this tool, we will have two points for the end points of the beam.
        @ip1 = Sketchup::InputPoint.new
        @ip2 = Sketchup::InputPoint.new
        @ip = Sketchup::InputPoint.new
        @drawn = false

        @@pt1 = nil
        @@pt2 = nil

        @left_lock = nil
        @right_lock = nil
        @up_lock = nil

        @xdown = 0
        @ydown = 0

        @x_red = Geom::Vector3d.new 1,0,0
        @y_green = Geom::Vector3d.new 0,1,0
        @z_blue = Geom::Vector3d.new 0,0,1
        # This sets the label for the VCB
        Sketchup::set_status_text ("Length"), SB_VCB_LABEL
      end

      def get_cham(a, b)
        c = Math.sqrt(a**2 + b**2)
        return c
      end

      def onSetCursor
        cursor_path = Sketchup.find_support_file ROOT_FILE_PATH+"/icons/ts_cursor1.png", "Plugins/"
        cursor_id = UI.create_cursor(cursor_path, 0, 0)
        UI.set_cursor(cursor_id.to_i)
      end

      # The draw method is called whenever the view is refreshed.  It lets the
      # tool draw any temporary geometry that it needs to.
      def draw(view)
        if( @ip1.valid? )
          if( @ip1.display? )
            @ip1.draw(view)
            @drawn = true
          end

          if @ip2.valid? && @ip1.position != @ip2.position
            @ip2.draw(view) if( @ip2.display? )

            # The set_color_from_line method determines what color
            # to use to draw a line based on its direction.  For example
            # red, green or blue.
            view.set_color_from_line(@ip1, @ip2)
            self.draw_ghost(@ip1.position, @ip2.position, view)
            self.draw_control_line([@ip1.position, @ip2.position], view)
            @drawn = true
          end
        end
      end #Draw

      def draw_control_line(pts, view)
        view.line_width = 2
        view.line_stipple = "."
        view.drawing_color = "black"
        view.draw(GL_LINES, pts)
      end


      # The onLButtonUp method is called when the user releases the left mouse button.
      def onLButtonUp(flags, x, y, view)
        # If we are doing a drag, then create the Beam on the mouse up event
        if( @dragging && @ip2.valid? )
          @entities.add_line @pt1, @pt2
          self.reset(view)
        end
      end

      def draw_tube(vec)

        #points on tube, 8 of them
        @points = [
          pt1 = [@r,0,0],
          pt2 = [@w-@r,0,0],
          pt3 = [@w, 0, @r],
          pt4 = [@w, 0, @h-@r],
          pt5 = [@w-@r, 0, @h],
          pt6 = [@r, 0, @h],
          pt7 = [0, 0, @h-@r],
          pt8 = [0, 0, @r],
          pt1
        ]

        inside_points = [
          ip1 = [@tw, 0, @tw],
          ip2 = [@w-@tw, 0, @tw],
          ip3 = [@w-@tw, 0, @h-@tw],
          ip4 = [@tw, 0, @h-@tw],
          ip1
        ]

        radius_centers = [
          rc1 = [@r, 0, @r],
          rc2 = [(@w-@r), 0, @r],
          rc3 = [(@w-@r), 0, (@h-@r)],
          rc4 = [@r, 0, (@h-@r)]
        ]

        @ts_group = @entities.add_group


        outer_edges = @ts_group.entities.add_face(@points).edges

#################################################################################################################
##            COMMENT THIS OUT TO ONY DO CHAMFERS, UNCOMMENT TO DO RADIUS EDGES ON HSS                    #######
#################################################################################################################
        ### Erases the chamfers before placing the rounded endges on the tube steel ###


        # outer_edges.each_with_index do |e, i|
        #   e.erase! if i.odd?
        # end

        ### Rotates the rounded corners into place ###


        # d1 = 180
        # d2 = 270
        # radius_centers.each do |rc|
        #   outer_edges.push @ts_group.entities.add_arc(rc, X_AXIS, Y_AXIS.reverse, @r, d1.degrees, d2.degrees, 3)
        #   d1 += 90
        #   d2 += 90
        # end

        # new_edges = outer_edges.first.all_connected
        # @ts_group.entities.add_face(new_edges)

###################################################################################################################
###################################################################################################################

        g1 = @ts_group.entities.add_group #this group houses the inner offset of the tube steel
        inner_edges = g1.entities.add_edges(inside_points)

        ents = g1.explode.collect{|e| e if e.is_a? Sketchup::Edge}.compact
        # UI.messagebox("#{ents}")

        face_to_delete = ents[0].common_face ents[1]
        face_to_delete.erase! if face_to_delete

        main_face = @ts_group.entities.select{|e| e.is_a? Sketchup::Face}[0].reverse!

        align_tube(vec, @ts_group)
        extrude_tube(vec, main_face)

      end

      def add_hss_directin_labels(vec, length)
          beam_direction = vec
          heading = Geom::Vector3d.new beam_direction
          heading[2] = 0
          angle = heading.angle_between NORTH

          #Sets the direction labels according to the beam vec
          #Single Directions
          case angle
          when (0.degrees)..(30.degrees)
            direction1 = 'N'
            direction2 = 'S'
          when (60.degrees)..(120.degrees)
            if vec[0] >= 0
            direction1 = 'E'
            direction2 = 'W'
          else
            direction1 = 'W'
            direction2 = 'E'
          end
          when (150.degrees)..(180.degrees)
            direction1 = 'S'
            direction2 = 'N'
          #Compound Directions
          when (30.degrees)..(60.degrees)
            if vec[0] >= 0
              direction1 = 'NE'
              direction2 = 'SW'
            else
              direction1 = 'NW'
              direction2 = 'SE'
            end
          when (120.degrees)..(150.degrees)
            if vec[0] >= 0
              direction1 = 'SE'
              direction2 = 'NW'
            else
              direction1 = 'SW'
              direction2 = 'NE'
            end
          end

          #Gets the file paths for the labels
          file_path1 = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{direction1}.skp", "Plugins/"
          end_direction = @definition_list.load file_path1
          file_path2 = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{direction2}.skp", "Plugins/"
          start_direction = @definition_list.load file_path2

      end

      def align_tube(vec, group)
        group.transform! @trans
      end

      def extrude_tube(vec, face)
        face.pushpull(vec.length)
      end

      def create_geometry(pt1, pt2, view)
          model = view.model
          # model.start_operation("Draw TS", true)

          vec = pt2 - pt1
          if( vec.length < 2 )
              UI.beep
              UI.messagebox("Please draw a beam longer than 2")
              return
          end

          if vec.parallel? Z_AXIS
            column = true
          else
            column = false
          end

          draw_tube(vec)

          # model.commit_operation

        end

        def onMouseMove(flags, x, y, view)
        @vx = Geom::Vector3d.new 1,0,0
        @vy = Geom::Vector3d.new 0,1,0
        @vz = Geom::Vector3d.new 0,0,1

        if( @state == 0 )
          # We are getting the first end of the line.  Call the pick method
          # on the InputPoint to get a 3D position from the 2D screen position
          # that is passed as an argument to this method.
          @ip.pick view, x, y
          if( @ip != @ip1 )
            # if the point has changed from the last one we got, then
            # see if we need to display the point.  We need to display it
            # if it has a display representation or if the previous point
            # was displayed.  The invalidate method on the view is used
            # to tell the view that something has changed so that you need
            # to refresh the view.
            view.invalidate if( @ip.display? or @ip1.display? )
            @ip1.copy! @ip

            # set the tooltip that should be displayed to this point
            view.tooltip = @ip1.tooltip
          end
        else
          # Getting the second end of the line
          # If you pass in another InputPoint on the pick method of InputPoint
          # it uses that second point to do additional inferencing such as
          # parallel to an axis.
          @ip2.pick view, x, y, @ip1
          view.tooltip = @ip2.tooltip if( @ip2.valid? )
          view.invalidate

          # Update the length displayed in the VCB
          if( @ip2.valid? )
            length = @ip1.position.distance(@ip2.position)
            Sketchup::set_status_text length.to_s, SB_VCB_VALUE
          end


          # Check to see if the mouse was moved far enough to create a line.
          # This is used so that you can create a line by either dragging
          # or doing click-move-click
          if( (x-@xdown).abs > 10 || (y-@ydown).abs > 10 )
            @dragging = true
          end
        end


        if @ip1.valid? && @ip2.valid?
          @vy = @ip1.position.vector_to @ip2.position
          not_a_zero_vec = @vy.length > 0
          @vx = @vy.axes[0] if not_a_zero_vec
          @vz = @vy.axes[1] if not_a_zero_vec
        end
        @trans = Geom::Transformation.axes @ip1.position, @vx, @vy, @vz if @ip1.valid? && not_a_zero_vec
        @trans2 = Geom::Transformation.axes @ip2.position, @vx, @vy, @vz if @ip1.valid? && not_a_zero_vec
      end

      # onUserText is called when the user enters something into the VCB
      # In this implementation, we create a line of the entered length if
      # the user types a length while selecting the second point
      def onUserText(text, view)
        # The user may type in something that we can't parse as a length
        # so we set up some exception handling to trap that
        begin
          value = text.to_l
        rescue
          # Error parsing the text
          UI.beep
          puts "Cannot convert #{text} to a Length"
          value = nil
          Sketchup::set_status_text "", SB_VCB_VALUE
        end
        return if !value

        if @state == 1
          # Compute the direction and the second point
          @@pt1 = @ip1.position
          @@vec = @ip2.position - @@pt1
          if( @@vec.length == 0.0 )
            UI.beep
            return
          end
          @@vec.length = value
          @@pt2 = @@pt1 + @@vec

          # Create the beam in Sketchup
          self.create_geometry(@@pt1, @@pt2, view)
          self.reset(view)
        end
      end

      # The onLButtonDOwn method is called when the user presses the left mouse button.
      def onLButtonDown(flags, x, y, view)
        # When the user clicks the first time, we switch to getting the
        # second point.  When they click a second time we create the Beam
        if( @state == 0 )
          @ip1.pick view, x, y
          if @ip1.valid?
            @state = 1

            @ip1points = [
              a1 = Geom::Point3d.new(@r,0,0),
              b1 = Geom::Point3d.new(@w-@r,0,0),
              c1 = Geom::Point3d.new(@w, 0, @r),
              d1 = Geom::Point3d.new(@w, 0, @h-@r),
              e1 = Geom::Point3d.new(@w-@r, 0, @h),
              f1 = Geom::Point3d.new(@r, 0, @h),
              g1 = Geom::Point3d.new(0, 0, @h-@r),
              h1 = Geom::Point3d.new(0, 0, @r)
            ]

            Sketchup::set_status_text ("Select second end"), SB_PROMPT
            @xdown = x
            @ydown = y
            @@ip1 = @ip1

          end
        else
          # create the line on the second click
          if( @ip2.valid? )
            @@vec = @ip2.position - @ip1.position
            @@pt1 = @ip1.position
            @@pt2 = @ip2.position
            # @entities.add_line @@pt1, @@pt2
            self.create_geometry(@ip1.position, @ip2.position, view)
            self.reset(view)
          end
        end

        # Clear any inference lock
        view.lock_inference if view.inference_locked?
      end

      # Draw the geometry
      def draw_ghost(pt1, pt2, view)

        vec = pt1 - pt2

        if vec.parallel? @x_red
          ghost_color = "Red"
        elsif vec.parallel? @y_green
          ghost_color = "Lime"
        elsif vec.parallel? @z_blue
          ghost_color = "Blue"
        elsif pt1[0] == pt2[0] || pt1[1] == pt2[1] || pt1[2] == pt2[2]
          ghost_color = "Yellow"
        else
          ghost_color = "Gray"
        end

        a = []
        @ip1points.each {|p| a << p.transform(@trans)}
        b = []
        @ip1points.each {|p| b << p.transform(@trans2)}

        pts = a.zip(b).flatten

        fc1 = a.each_with_index do |p ,i|
          if i < (a.count - 1)
            pts.push a[i], a[i+1]
          else
            pts.push a[i], a[0]
          end
        end

        fc2 = b.each_with_index do |p ,i|
          if i < (b.count - 1)
            pts.push b[i], b[i+1]
          else
            pts.push b[i], b[0]
          end
        end
        # @ip1points.push pt1,pt2
        # returns a view
        view.line_width = 0.1
        view.drawing_color = ghost_color
        view.draw(GL_LINES, pts)
      end

      # onKeyDown is called when the user presses a key on the keyboard.
      # We are checking it here to see if the user pressed the shift key
      # so that we can do inference locking
      def onKeyDown(key, repeat, flags, view)
        if( key == CONSTRAIN_MODIFIER_KEY && repeat == 1 )
          # if we already have an inference lock, then unlock it
          if( view.inference_locked? )
            # calling lock_inference with no arguments actually unlocks
            view.lock_inference
          elsif( @state == 0 && @ip1.valid? )
            view.lock_inference @ip1
          elsif( @state == 1 && @ip2.valid? )
            view.lock_inference @ip2, @ip1
          end

        elsif (key == VK_LEFT && repeat == 1)
          p 'left'
          if( @state == 1 && @ip1.valid? )
            if @left_lock == true
              view.lock_inference
              @left_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              p = @ip1.position
              plus_1_y = Geom::Point3d.new(p[0], p[1]+10, p[2])
              green_axis = Sketchup::InputPoint.new(plus_1_y)
              view.lock_inference green_axis, @ip1
              @left_lock = true
              @right_lock = false
              @up_lock = false
            end
          end

        elsif (key == VK_RIGHT && repeat == 1)
          p 'right'
          if( @state == 1 && @ip1.valid? )
            if @right_lock == true
              view.lock_inference
              @right_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              p = @ip1.position
              plus_1_x = Geom::Point3d.new(p[0]+10, p[1], p[2])
              red_axis = Sketchup::InputPoint.new(plus_1_x)
              view.lock_inference red_axis, @ip1
              @left_lock = false
              @right_lock = true
              @up_lock = false
            end
          end

        elsif (key == VK_UP && repeat == 1)
          p 'up'
          if( @state == 1 && @ip1.valid? )
            if @up_lock == true
              view.lock_inference
              @up_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              p = @ip1.position
              plus_1_z = Geom::Point3d.new(p[0], p[1], p[2]+10)
              blue_axis = Sketchup::InputPoint.new(plus_1_z)
              view.lock_inference blue_axis, @ip1
              @left_lock = false
              @right_lock = false
              @up_lock = true
            end
          end
        end
      end

      # onKeyUp is called when the user releases the key
      # We use this to unlock the inference
      # If the user holds down the shift key for more than 1/2 second, then we
      # unlock the inference on the release.  Otherwise, the user presses shift
      # once to lock and a second time to unlock.
      def onKeyUp(key, repeat, flags, view)
        if( key == CONSTRAIN_MODIFIER_KEY && view.inference_locked?)
          view.lock_inference
        end
      end

      # Reset the tool back to its initial state
      def reset(view)
        # This variable keeps track of which point we are currently getting
        @state = 0

        # Display a prompt on the status bar
        Sketchup::set_status_text(("Select first end"), SB_PROMPT)

        # clear the InputPoints
        @ip1.clear if @ip1
        @ip2.clear if @ip2

        if( view )
          view.tooltip = nil
          view.invalidate if @drawn
        end

        @drawn = false
        @dragging = false

      end

      def deactivate(view)
        view.invalidate if @drawn
        view.lock_inference if view.inference_locked?
      end

    end

  end
end