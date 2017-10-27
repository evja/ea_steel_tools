module EA_Extensions623
  module EASteelTools

    class TubeTool

      RADIUS_RULE = 1.6
      # The activate method is called by SketchUp when the tool is first selected.
      # it is a good place to put most of your initialization
      def initialize
        @model = Sketchup.active_model
        # Activates the @model @entities for use
        @entities = @model.active_entities
        @state = 0

        # The Sketchup::InputPoint class is used to get 3D points from screen
        # positions.  It uses the SketchUp inferencing code.
        # In this tool, we will have two points for the end points of the beam.
        @ip1 = Sketchup::InputPoint.new
        @ip2 = Sketchup::InputPoint.new
        @ip = Sketchup::InputPoint.new
        @drawn = false

        @left_lock = nil
        @right_lock = nil
        @up_lock = nil

        @xdown = 0
        @ydown = 0
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
            # self.draw_ghost(@ip1.position, @ip2.position, view)
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

      # The onLButtonDOwn method is called when the user presses the left mouse button.
      def onLButtonDown(flags, x, y, view)
        # When the user clicks the first time, we switch to getting the
        # second point.  When they click a second time we create the Beam
        if( @state == 0 )
          @ip1.pick view, x, y
          if @ip1.valid?
            @state = 1


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
            @entities.add_line @@pt1, @@pt2
            self.create_geometry(@ip1.position, @ip2.position, view)
            self.reset(view)
          end
        end

        # Clear any inference lock
        view.lock_inference if view.inference_locked?
      end

      # The onLButtonUp method is called when the user releases the left mouse button.
      def onLButtonUp(flags, x, y, view)
        # If we are doing a drag, then create the Beam on the mouse up event
        if( @dragging && @ip2.valid? )
          @entities.add_line @@pt1, @@pt2
          self.reset(view)
        end
      end

      def draw_tube
        values = data[:data]
        @h     = values[:d].to_f #height of the tube
        @w     = values[:bf].to_f #width of the tube
        @tw    = values[:tw].to_f #wall thickness of the tube
        @r     = values[:r].to_f #radius of the tube

        w = 4
        h = 4
        tw = 0.25
        r = tw*RADIUS_RULE

        #points on tube, 8 of them
        @points = [
          pt1 = [r,0,0],
          pt2 = [w-r,0,0],
          pt3 = [w,r,0],
          pt4 = [w,h-r,0],
          pt5 = [w-r,h,0],
          pt6 = [r,h,0],
          pt7 = [0,h-r,0],
          pt8 = [0,r,0],
          pt1
        ]

        edges = @entities.add_edges(@points)

        edges.each_with_index do |e, i|
          e.erase! if i.odd?
        end

        radius_centers = [
          rc1 = [r,r,0],
          rc2 = [(w-r), r, 0],
          rc3 = [(w-r), (h-r), 0],
          rc4 = [r,(h-r), 0]
        ]

        d1 = 180
        d2 = 270
        radius_centers.each do |rc|
          edges.push @entities.add_arc(rc, X_AXIS, Z_AXIS, r, d1.degrees, d2.degrees, 3)
          d1 += 90
          d2 += 90
        end

        new_edges = edges.first.all_connected
        @entities.add_face(new_edges)

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

          draw_tube
          # align_steel(pt1, pt2, vec, @outer_group)

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
          @vx = @vy.axes[0]
          @vz = @vy.axes[1]
        end
        @trans = Geom::Transformation.axes @ip1.position, @vx, @vy, @vz if @ip1.valid?
        @trans2 = Geom::Transformation.axes @ip2.position, @vx, @vy, @vz if @ip1.valid?
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


    end

  end
end