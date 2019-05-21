module EA_Extensions623
  module EASteelTools
    # require FNAME+'/'+'plate_observer.rb'
    # extend MyPlateObserver

    module Control
      # deactivate is called when the tool is deactivated because
      # a different tool was selected
      def deactivate(view)
        view.invalidate if @drawn
        view.lock_inference if view.inference_locked?
      end

      def set_layer(part, layer)
        part.layer = layer[0]
      end

      def classify_as_plate(plate)
        plate.definition.add_classification(CLSSFR_LIB, CLSSFY_PLT)
        plate.add_observer(EASteelTools::MyPlateObserver.new(plate))
        set_layer(plate, STEEL_LAYER)
        return plate
      end

      def check_for_existing_layer(meth, *args, &blk)

      end

      def get_plate()

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
          not_a_zero_vec = @vy.length > 0
          @vx = @vy.axes[0] if not_a_zero_vec
          @vz = @vy.axes[1] if not_a_zero_vec
        end
        @trans = Geom::Transformation.axes @ip1.position, @vx, @vy, @vz if @ip1.valid? && not_a_zero_vec
        @trans2 = Geom::Transformation.axes @ip2.position, @vx, @vy, @vz if @ip1.valid? && not_a_zero_vec
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
          # p 'left_lock'
          if( @state == 1 && @ip1.valid? )
            if @left_lock == true
              view.lock_inference
              @left_lock = false
            else
              pt = @ip1.position
              y_axes = view.model.axes.axes[1]
              inference_y_point = Geom::Point3d.new(pt[0]+y_axes[0], pt[1]+y_axes[1], pt[2]+y_axes[2])
              green_axis = Sketchup::InputPoint.new(inference_y_point)
              view.lock_inference green_axis, @ip1
              # @left_lock = true
              # @right_lock = false
              # @up_lock = false
            end
          end

        elsif (key == VK_RIGHT && repeat == 1)
          # p 'right_lock'
          if( @state == 1 && @ip1.valid? )
            if @right_lock == true
              view.lock_inference
              @right_lock = false
            else
              pt = @ip1.position
              x_axes = view.model.axes.axes[0]
              inference_x_point = Geom::Point3d.new(pt[0]+x_axes[0], pt[1]+x_axes[1], pt[2]+x_axes[2])
              red_axis = Sketchup::InputPoint.new(inference_x_point)
              view.lock_inference red_axis, @ip1
              # @left_lock = false
              # @right_lock = true
              # @up_lock = false
            end
          end

        elsif (key == VK_UP && repeat == 1)
          # p 'up_lock'
          # p "left lock = #{@left_lock}"
          # p "right lock = #{@right_lock}"
          # p "up lock = #{@up_lock}"
          if( @state == 1 && @ip1.valid? )
            if @up_lock == true
              view.lock_inference if !view.inference_locked?
              @up_lock = false
            else
              pt = @ip1.position
              z_axes = view.model.axes.axes[2]
              inference_z_point = Geom::Point3d.new(pt[0]+z_axes[0], pt[1]+z_axes[1], pt[2]+z_axes[2])
              blue_axis = Sketchup::InputPoint.new(inference_z_point)
              view.lock_inference blue_axis, @ip1
              # @left_lock = false
              # @right_lock = false
              # @up_lock = true
            end
          end
        end

        # if key == VK_ALT && repeat == 1

        #   p 'start rotation incriments'
        #   if @state == 1 && @ip1.valid?
        #     vec = @ip1.position - @ip2.position
        #     rot = Geom::Transformation.rotation(@ip1.position, vec, 45.degrees)
        #     @ip1points.each{|ip| ip.transform! rot}
        #   end
        # end

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

      def color_by_thickness(obj, thickness)
        begin
          materials = Sketchup.active_model.materials
          materials_names = materials.map{|m| m.name}
          thickness = thickness.to_s.to_r.to_f

          case thickness
           when 0.25
             color = STEEL_COLORS[:purple][:rgba]
             clr_name = STEEL_COLORS[:purple][:name]
           when 0.3125
             color = STEEL_COLORS[:indigo][:rgba]
             clr_name = STEEL_COLORS[:indigo][:name]
           when 0.375
             color = STEEL_COLORS[:blue][:rgba]
             clr_name = STEEL_COLORS[:blue][:name]
           when 0.5
             color = STEEL_COLORS[:green][:rgba]
             clr_name = STEEL_COLORS[:green][:name]
           when 0.625
             color = STEEL_COLORS[:yellow][:rgba]
             clr_name = STEEL_COLORS[:yellow][:name]
           when 0.75
             color = STEEL_COLORS[:orange][:rgba]
             clr_name = STEEL_COLORS[:orange][:name]
           else
             color = STEEL_COLORS[:red][:rgba]
             clr_name = STEEL_COLORS[:red][:name]
           end

            if materials_names.include? clr_name
              obj.material = materials[clr_name]
            else
              new_mat = materials.add clr_name
              new_mat.color = color
              obj.material = new_mat
            end
           return obj
         rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem coloring some parts")
        end
      end

    end #Class
  end #Module
end #module