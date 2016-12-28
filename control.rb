module EA_Extensions623
  module EASteelTools

    class Control
      def onSetCursor
        cursor_path = Sketchup.find_support_file ROOT_FILE_PATH+"/icons/wfs_cursor(2).png", "Plugins/"
        cursor_id = UI.create_cursor(cursor_path, 0, 0)
        UI.set_cursor(cursor_id.to_i)
      end

      # deactivate is called when the tool is deactivated because
      # a different tool was selected
      def deactivate(view)
        view.invalidate if @drawn
        view.lock_inference if view.inference_locked?
      end

      # The onMouseMove method is called whenever the user moves the mouse.
      # because it is called so often, it is important to try to make it efficient.
      # In a lot of tools, your main interaction will occur in this method.
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

        if @ip1.valid? || @ip2.valid?
          @vy = @ip1.position.vector_to @ip2.position
          @vx = @vy.axes[0]
          @vz = @vy.axes[1]
        end
        @trans = Geom::Transformation.axes @ip1.position, @vx, @vy, @vz if @ip1.valid?
        @trans2 = Geom::Transformation.axes @ip2.position, @vx, @vy, @vz if @ip1.valid?
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

      # onCancel is called when the user hits the escape key
      def onCancel(flag, view)
        self.reset(view)
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

    end #Class
  end #Module
end #module