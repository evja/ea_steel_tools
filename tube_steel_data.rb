module EA_Extensions623
  module EASteelTools

    class TubeTool
      include Control

      # The activate method is called by SketchUp when the tool is first selected.
      # it is a good place to put most of your initialization
      def initialize(data)
        @model = Sketchup.active_model
        # Activates the @model @entities for use
        @entities = @model.active_entities
        @selection = @model.selection
        @model_view = @model.active_view
        @definition_list = @model.definitions
        @materials = @model.materials
        @state = 0
        values     = data[:data]
        @base_type = data[:base_type]
        @base_thickness = data[:base_thick].to_f
        @@stud_spacing = data[:stud_spacing]
        @north_stud_selct = data[:north_stud_selct]
        @south_stud_selct = data[:south_stud_selct]
        @east_stud_selct = data[:east_stud_selct]
        @west_stud_selct = data[:west_stud_selct]

        @hss_is_rotated = data[:hss_is_rotated]

        @start_tolerance = data[:start_tolerance].to_f
        @end_tolerance = data[:end_tolerance].to_f

        @hss_type = data[:hss_type]
        @cap_thickness = data[:cap_thickness]
        @hss_has_cap = data[:hss_has_cap]

        @h = values[:h].to_f #height of the tube
        @w = values[:b].to_f #width of the tube


        # This rotates the orientation of the hss if it is a rectangle and you want the long side facing 90° rotation
        if @hss_is_rotated
          @h, @w = @w, @h
        end

        if @h == @w
          @square_tube = true
        end

        if @hss_type == 'Column'
          @is_column = true
        else
          @is_column = false
        end

        case data[:wall_thickness]
        when '1/8"'
          @tw = 0.125
        when '3/16"'
          @tw = 0.1875
        when '1/4"'
          @tw = 0.25
        when '5/16"'
          @tw = 0.3125
        when '3/8"'
          @tw = 0.375
        when '1/2"'
          @tw = 0.5
        when '5/8"'
          @tw = 0.625
        when '3/4"'
          @tw = 0.75
        when '7/8"'
          @tw = 0.875
        else
          @tw = 0.25
        end

        @tube_name = "HSS #{data[:height_class]}x#{data[:width_class]} x#{data[:wall_thickness]}"
        # p @tube_name
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

        @x_red = @model.axes.axes[0]
        @y_green = @model.axes.axes[1]
        @z_blue = @model.axes.axes[2]
        # This sets the label for the VCB
        Sketchup::set_status_text ("Length"), SB_VCB_LABEL
        selections = check_for_preselect(@selection, @model_view)
      end

      def check_for_preselect(*args, view)
        @bad_selections = []
        if args[0].nil?
          p 'no selection'
          return false
        else
          selection = args[0]
          selection.each do |ent|
            if ent.is_a? Sketchup::ConstructionLine
              #extract the start and end point of the ConstructionLine
              pt1 = ent.start
              pt2 = ent.end
            elsif ent.is_a? Sketchup::Edge
              #extract the start and end point of the Edge
              pt1 = ent.start.position
              pt2 = ent.end.position
            else
              @bad_selections << ent
            end
            if pt1 && pt2
              @vy = pt1.vector_to pt2
              not_a_zero_vec = @vy.length > 0
              @vx = @vy.axes[0] if not_a_zero_vec
              @vz = @vy.axes[1] if not_a_zero_vec

              @trans = Geom::Transformation.axes pt1, @vx, @vy, @vz.reverse
              @trans2 = Geom::Transformation.axes pt2, @vx, @vy, @vz.reverse

              # Create the member in Sketchup
              self.create_geometry(pt1, pt2, view)
              self.reset(view)
            end
          end
        end
        if @bad_selections.any?
          UI.beep
          @model.selection.remove @bad_selections
          Sketchup.status_text = "There were #{@bad_selections.count} selections that do not work with the tool"
        end
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

      def draw_beam_caps(length)
        begin
          cap = @hss_outer_group.entities.add_group
          pts = [
            pt1 = [0,0,0],
            pt2 = [@w, 0,0],
            pt3 = [@w, @h, 0],
            pt4 = [0, @h, 0]
          ]

          cap_face = cap.entities.add_face pts
          cap_face.reverse!
          cap_face.pushpull @cap_thickness

          v3 = Z_AXIS.clone
          v3.length = -@cap_thickness

          sld = Geom::Transformation.new(v3)
          @hss_outer_group.entities.transform_entities sld, cap
          classify_as_plate(cap)

          cap2 = cap.copy

          v3.length = length.length + @cap_thickness
          copy_away = Geom::Transformation.new(v3.reverse!)
          @hss_outer_group.entities.transform_entities copy_away, cap2

          color_by_thickness(cap, @cap_thickness)
          color_by_thickness(cap2, @cap_thickness)
          # classify_as_plate(cap2)
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the end caps")
        end
      end

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

      def set_groups
        @hss_outer_group = @entities.add_group
        @hss_outer_group.name = 'HSS Member'

        @hss_inner_group = @hss_outer_group.entities.add_group
        @hss_inner_group.name = @tube_name
        @hss_inner_group.definition.behavior.no_scale_mask = 123
      end

      def clear_groups
        @hss_outer_group = nil
        @hss_inner_group = nil
      end

      ######################################
      ######################################

      def draw_tube(vec)
        set_groups
        #points on tube, 8 of them
        @points = [
          pt1 = [@r,0,0],
          pt2 = [@w-@r,0,0],
          pt3 = [@w, @r, 0],
          pt4 = [@w, (@h-@r), 0],
          pt5 = [@w-@r, @h, 0],
          pt6 = [@r, @h, 0],
          pt7 = [0, (@h-@r), 0],
          pt8 = [0, @r, 0],
          pt1
        ]

        # print @points

        inside_points = [
          ip1 = [@tw, @tw, 0],
          ip2 = [@w-@tw, @tw, 0],
          ip3 = [@w-@tw, (@h-@tw), 0],
          ip4 = [@tw, (@h-@tw), 0],
          ip1
        ]

        radius_centers = [
          rc1 = [@r, @r, 0],
          rc2 = [(@w-@r), @r, 0],
          rc3 = [(@w-@r), (@h-@r), 0],
          rc4 = [@r, (@h-@r), 0]
        ]

        outer_edges = @hss_inner_group.entities.add_face(@points)


        ##################################################################
        ### THIS CODE CHANGES THE CHAMFER TO A RADIUS WHEN UNCOMMENTED ###
        ##################################################################

        # ##Erases the chamfers before placing the rounded endges on the tube steel
        # edges = outer_edges.edges
        # edges_to_delete = []
        # edges.each_with_index do |e, i|
        #   if i.odd?
        #     e.erase!
        #     edges_to_delete << e
        #   end
        # end

        # edges_to_delete.each do |e|
        #   edges.delete(e)
        # end

        # ## Rotates the rounded corners into place
        # d1 = 180
        # d2 = 270
        # radius_centers.each do |rc|
        #   edges.push @hss_inner_group.entities.add_arc(rc, X_AXIS, Z_AXIS, @r, d1.degrees, d2.degrees, 3)
        #   d1 += 90
        #   d2 += 90
        # end

        # new_edges = @hss_inner_group.entities.add_face(edges.first.all_connected)


        #####################################################################
        #####################################################################
        #####################################################################

        g1 = @hss_inner_group.entities.add_group #this group houses the inner offset of the tube steel
        inner_edges = g1.entities.add_edges(inside_points)

        ents = g1.explode.collect{|e| e if e.is_a? Sketchup::Edge}.compact
        # UI.messagebox("#{ents}")

        face_to_delete = ents[0].common_face ents[1]
        face_to_delete.erase! if face_to_delete

        centerpoint_group = @hss_outer_group.entities.add_group
        main_face = @hss_inner_group.entities.select{|e| e.is_a? Sketchup::Face}[0].reverse!
        @center_of_column = centerpoint_group.entities.add_cpoint(@hss_outer_group.bounds.center)
        centerpoint_group.locked = true

        slide_face = Geom::Transformation.translation(Geom::Vector3d.new(0,-@h, 0))

        rot_face = Geom::Transformation.rotation(ORIGIN, X_AXIS, 270.degrees)
        @entities.transform_entities rot_face*slide_face, @hss_outer_group

        v1 = X_AXIS.clone.reverse
        v1.length = @w * 0.5
        sld_t_cx = Geom::Transformation.translation(v1)

        v2 = Z_AXIS.clone.reverse
        v2.length = @h* 0.5
        sld_t_cy = Geom::Transformation.translation(v2)

        mv_prof_to_c = sld_t_cx * sld_t_cy

        @entities.transform_entities mv_prof_to_c, @hss_outer_group
        @material_names = @materials.map {|color| color.name}

        extrude_length = vec.clone
        if @is_column
          extrude_length.length = (vec.length - (@base_thickness*2)) - (@start_tolerance+@end_tolerance) #This thickness is accouting for bot top and bottom plate. if the top plates thickness is controlled it will need to be accounted for if it varies from the base thickness
          extrude_tube(extrude_length, main_face)
          add_reference_cross(inside_points, extrude_length)
          add_studs(extrude_length.length, @@stud_spacing)
          add_up_arrow(extrude_length.length, @@stud_spacing)
          add_name_label(vec)
          add_direction_labels()
          align_tube(vec, @hss_outer_group)

          insert_base_plates(@base_type, @center_of_column.position)
          insert_top_plate(@center_of_column.position, extrude_length)
        else
          if @hss_has_cap
            extrude_length.length = (vec.length - (@cap_thickness*2))
          else
            extrude_length.length = vec.length
          end
          extrude_tube(extrude_length, main_face)
          add_reference_cross(inside_points, extrude_length)
          add_name_label(extrude_length)
          add_studs_beam(extrude_length.length, @@stud_spacing)
          add_hss_beam_direction_labels(extrude_length)
          add_beam_up_arrow(vec, extrude_length)
          cap = draw_beam_caps(extrude_length) if @hss_has_cap
          align_tube(vec, @hss_outer_group)
        end
      end

      def add_reference_cross(pts, seperation_dist)
        #draw the x in the middle of the tube, top & bottom
        reference_cross = @hss_inner_group.entities.add_group
        cl1 = reference_cross.entities.add_line(pts[0], pts[2])
        cl2 = reference_cross.entities.add_line(pts[1], pts[3])

        reference_cross2 = reference_cross.copy
        v = Z_AXIS.clone
        v.length = seperation_dist.length
        @hss_inner_group.entities.transform_entities(v, reference_cross2)
      end

      def add_beam_up_arrow(vec, length)
        begin
          up_group = @hss_outer_group.entities.add_group()

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{UP_DRCTN_SM}", "Plugins/"
          up_direction = @definition_list.load file_path

          up_arrow1 = up_group.entities.add_instance(up_direction, @center_of_column.position)

          rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 90.degrees )
          sld_vec = X_AXIS.clone
          sld_vec.length = @w/2
          slide = Geom::Transformation.translation(sld_vec)
          @hss_outer_group.entities.transform_entities(rot, up_arrow1)
          @hss_outer_group.entities.transform_entities(slide, up_arrow1)

          up_arrow1_copy = up_arrow1.copy
          r_to_o_side = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 180.degrees)
          @hss_outer_group.entities.transform_entities(r_to_o_side, up_arrow1_copy)

          rot_direct = 90 - Z_AXIS.angle_between(vec).radians
          # p rot_direct.degrees
          rot_vert = Geom::Transformation.rotation(@center_of_column.position, X_AXIS, rot_direct.degrees)
          @hss_outer_group.entities.transform_entities(rot_vert, up_group)

          sld_vec = Z_AXIS.clone
          sld_vec.length = (length.length/2) + 24
          slide_to_pos = Geom::Transformation.translation(sld_vec)
          @hss_outer_group.entities.transform_entities(slide_to_pos, up_group)
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the up arrow on the hss beam")
        end
      end

      def add_hss_beam_direction_labels(vec)
        begin

          start_direction_group = @hss_outer_group.entities.add_group
          start_ents = start_direction_group.entities
          end_direction_group = @hss_outer_group.entities.add_group
          end_ents = end_direction_group.entities
          up_direction_group = @hss_outer_group.entities.add_group
          up_ents = up_direction_group.entities

          beam_direction = vec
          # p vec
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
          file_path1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{direction1}.skp", "Plugins/"
          end_direction = @definition_list.load file_path1
          file_path2 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{direction2}.skp", "Plugins/"
          start_direction = @definition_list.load file_path2

          start_dir_beam1 = start_direction_group.entities.add_instance start_direction, @center_of_column.position
          start_dir_beam2 = start_direction_group.entities.add_instance start_direction, @center_of_column.position
          end_dir_beam1 = end_direction_group.entities.add_instance end_direction, @center_of_column.position
          end_dir_beam2 = end_direction_group.entities.add_instance end_direction, @center_of_column.position

          rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 90.degrees)
          @hss_outer_group.entities.transform_entities rot, start_dir_beam1
          @hss_outer_group.entities.transform_entities rot, end_dir_beam1

          vec_slide1 = Geom::Vector3d.new(@w/2,0,0)
          slide1 = Geom::Transformation.translation(vec_slide1)
          @hss_outer_group.entities.transform_entities slide1, start_dir_beam1
          @hss_outer_group.entities.transform_entities slide1, end_dir_beam1

          vec2 = Geom::Vector3d.new(0,0,6)
          slide_to_start = Geom::Transformation.translation(vec2)

          rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 270.degrees)
          @hss_outer_group.entities.transform_entities rot, start_dir_beam2
          @hss_outer_group.entities.transform_entities rot, end_dir_beam2

          vec_slide2 = Geom::Vector3d.new(-@w/2,0,0)
          slide1 = Geom::Transformation.translation(vec_slide2)
          @hss_outer_group.entities.transform_entities slide1, start_dir_beam2
          @hss_outer_group.entities.transform_entities slide1, end_dir_beam2

          vec2 = Geom::Vector3d.new(0,0,6)

          @hss_outer_group.entities.transform_entities slide_to_start, start_direction_group

          vec3 = Geom::Vector3d.new(0,0,(vec.length)-6)
          slide_to_end = Geom::Transformation.translation(vec3)
          @hss_outer_group.entities.transform_entities slide_to_end, end_direction_group
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem with the hss direction labels")
        end
      end #hss beam lables

      def array_studs(copies, part, dist)
        studs = []
        distance = dist.length
        copies.times do
          trns = Geom::Transformation.translation(dist)
          stud_copy = part.copy
          part.parent.entities.transform_entities trns, stud_copy
          studs << stud_copy
          dist.length += distance
        end

        return studs
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
          p 'left_lock'
          if( @state == 1 && @ip1.valid? )
            if @left_lock == true
              view.lock_inference
              @left_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              pt = @ip1.position
              y_axes = view.model.axes.axes[1]
              inference_y_point = Geom::Point3d.new(pt[0]+y_axes[0], pt[1]+y_axes[1], pt[2]+y_axes[2])
              green_axis = Sketchup::InputPoint.new(inference_y_point)
              view.lock_inference green_axis, @ip1
              @left_lock = true
              @right_lock = false
              @up_lock = false
            end
          end

        elsif (key == VK_RIGHT && repeat == 1)
          p 'right_lock'
          if( @state == 1 && @ip1.valid? )
            if @right_lock == true
              view.lock_inference
              @right_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              pt = @ip1.position
              x_axes = view.model.axes.axes[0]
              inference_x_point = Geom::Point3d.new(pt[0]+x_axes[0], pt[1]+x_axes[1], pt[2]+x_axes[2])
              red_axis = Sketchup::InputPoint.new(inference_x_point)
              view.lock_inference red_axis, @ip1
              @left_lock = false
              @right_lock = true
              @up_lock = false
            end
          end

        elsif (key == VK_UP && repeat == 1)
          p 'up_lock'
          if( @state == 1 && @ip1.valid? )
            if @up_lock == true
              view.lock_inference
              @up_lock = false
            elsif( @state == 1 &&  @ip1.valid? )
              pt = @ip1.position
              z_axes = view.model.axes.axes[2]
              inference_z_point = Geom::Point3d.new(pt[0]+z_axes[0], pt[1]+z_axes[1], pt[2]+z_axes[2])
              blue_axis = Sketchup::InputPoint.new(inference_z_point)
              view.lock_inference blue_axis, @ip1
              @left_lock = false
              @right_lock = false
              @up_lock = true
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

      def add_studs_beam(length, spread)
        begin
          length = length.to_f
          max_dist_from_hss_end = spread*0.75

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{HLF_INCH_STD}", "Plugins"
          @half_inch_stud = @definition_list.load file_path
          copies = (length/spread).to_i - 1
          start_dist = (length - (copies * spread))/2

          if @east_stud_selct
            e_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(e_stud, 0.5)
            rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 90.degrees)
            @hss_outer_group.entities.transform_entities rot, e_stud

            vec = Geom::Vector3d.new(@w/2,0,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, e_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, e_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, e_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}
          end

          if @west_stud_selct
            w_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(w_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 270.degrees)
            @hss_outer_group.entities.transform_entities rot, w_stud

            vec = Geom::Vector3d.new(-@w/2,0,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, w_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, w_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, w_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}

          end

          if @north_stud_selct
            n_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(n_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, X_AXIS, 270.degrees)
            @hss_outer_group.entities.transform_entities rot, n_stud

            vec = Geom::Vector3d.new(0,@h/2,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, n_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, n_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, n_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}

          end

          if @south_stud_selct
            s_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(s_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, X_AXIS, 90.degrees)
            @hss_outer_group.entities.transform_entities rot, s_stud
            # s_stud.move! rot

            vec = Geom::Vector3d.new(0,-@h/2,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, s_stud
            # s_stud.move! slide1

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, s_stud
            # s_stud.move! slide_to_start

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, s_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}

          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the half_inch_stud into the model")
        end
      end

      def insert_top_plate(center, vec)
        begin
          top_plate = @hss_outer_group.entities.add_group

          if @w <= STANDARD_TOP_PLATE_SIZE
            file_path2 = Sketchup.find_support_file "#{COMPONENT_PATH}/Top Plate.skp", "Plugins"

            top_plate_def = @definition_list.load file_path2

            @tp = top_plate.entities.add_instance top_plate_def, center

            slide_tpl_up = Geom::Transformation.translation(Geom::Vector3d.new(0,0,vec.length))
            top_plate.entities.transform_entities slide_tpl_up, @tp
            etch_plate(@tp, @hss_inner_group)
            @tp.explode
          else
            top_plate = draw_parametric_plate(sq_plate(@w, @h))
            slide_tpl_up = Geom::Transformation.translation(Geom::Vector3d.new(0,0,vec.length+STANDARD_BASE_PLATE_THICKNESS))
            @hss_outer_group.entities.transform_entities slide_tpl_up, top_plate

            rot = Geom::Transformation.rotation(top_plate.bounds.center, Y_AXIS, 180.degrees)
            top_plate.transform! rot
            etch_plate(top_plate, @hss_inner_group)
            add_plate_compass(top_plate, ORIGIN)
          end
          color_by_thickness(top_plate, STANDARD_BASE_PLATE_THICKNESS)
          classify_as_plate(top_plate)
          return top_plate
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the top plate")
        end
      end

      def add_plate_compass(plate, center)
        compass_group = plate.entities.add_group()
        file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/PlateCompass.skp", "Plugins"
        compass_def = @definition_list.load file_path
        compass = compass_group.entities.add_instance compass_def, center

        compass.explode
      end

      def etch_plate(plate, hss)
        begin
          ents = plate.definition.entities
          etch_group = ents.add_group
          etch_group.name = 'etch'
          ege = etch_group.entities
          temp_etch_group = ege.add_group

          col_corner = hss.bounds.min
          col_corner[2] = 0

          p1a = [0,0,0]
          p2a = [ETCH_LINE,0,0]
          p3a = [0,ETCH_LINE,0]

          p1b = [@w, 0,0]
          p2b = [@w-ETCH_LINE,0,0]
          p3b = [@w, ETCH_LINE,0]

          temp_etch_group.entities.add_line(p1a, p2a)
          temp_etch_group.entities.add_line(p1a, p3a)
          temp_etch_group.entities.add_line(p1b, p2b)
          temp_etch_group.entities.add_line(p1b, p3b)

          temp_group_copy = temp_etch_group.copy
          rot = Geom::Transformation.rotation([@w/2, @h/2, 0], Z_AXIS, 180.degrees)
          ege.transform_entities(rot, temp_group_copy)

          temp_etch_group.explode
          temp_group_copy.explode

          tp1 = etch_group.definition.bounds.center
          tp2 = hss.definition.bounds.min
          v = tp2 - tp1
          place_etch = Geom::Transformation.translation(v)
          @entities.transform_entities place_etch, etch_group


        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem etching the plate")
        end
      end

      def draw_parametric_plate(pts)
        begin
          temp_faces = []
          temp_edges = []
          temp_groups = []
          arcs = []

          @baseplate_group = @hss_outer_group.entities.add_group
          face = @baseplate_group.entities.add_face pts
          vec = @center_of_column.position - @baseplate_group.bounds.center
          center = Geom::Transformation.translation(vec)
          @hss_outer_group.entities.transform_entities(center, @baseplate_group)

          #chamfer the corner
          crnr1 = face.vertices[-1]
          crnr2 = face.vertices[0]
          crn_pos1 = crnr1.position
          crn_pos2 = crnr2.position
          # p crn_pos1
          gr = @baseplate_group.entities.add_group
          arc1 = gr.entities.add_arc([crn_pos1[0]-0.5, crn_pos1[1]-0.5, crn_pos1[2]], X_AXIS, Z_AXIS, BOTTOM_PLATE_CORNER_RADIUS, 0.degrees ,90.degrees)
          arc1 = gr.entities.add_arc([crn_pos2[0]-0.5, crn_pos2[1]+0.5, crn_pos2[2]], Y_AXIS.reverse, Z_AXIS, BOTTOM_PLATE_CORNER_RADIUS, 0.degrees ,90.degrees)
          # arc1.faces

          dg = 180.degrees

          1.times do |t|
            grc = gr.copy
            rot = Geom::Transformation.rotation(ORIGIN, Z_AXIS, dg)
            @baseplate_group.entities.transform_entities(rot, grc)
            arcs << grc.explode
          end
          pcs = gr.explode

          @baseplate_group.entities.each do |e|
            if e.class == Sketchup::Edge
              if e.length == BOTTOM_PLATE_CORNER_RADIUS
                e.erase!
              end
            else
              next
            end
          end
          pcs.each do |pc|
            if pc.class == Sketchup::Edge
              face = pc.faces[0]
              break
            end
          end

          face.pushpull STANDARD_BASE_PLATE_THICKNESS

          @baseplate_group.entities.each do |e|
            if e.class == Sketchup::Edge
              if e.length == 0.75
                e.soft = true
                e.smooth = true
              else
                next
              end
            else
              next
            end
          end

          color_by_thickness(@baseplate_group, 0.75)

          bh_file = Sketchup.find_support_file("#{COMPONENT_PATH}/#{THRTN_SXTNTHS_HOLE}", "Plugins")
          bh_def = @definition_list.load bh_file

          big_hole = @baseplate_group.entities.add_instance bh_def, ORIGIN

          v1 = X_AXIS.clone
          v2 = Y_AXIS.clone

          v1.length = (@w/2)+(STANDARD_BASE_MARGIN.to_f/2)
          v2.length = (@h/2)+(STANDARD_BASE_MARGIN.to_f/2)
          tr1 = Geom::Transformation.translation(v1)
          tr2 = Geom::Transformation.translation(v2)
          scl_hole = Geom::Transformation.scaling(ORIGIN, 1,1,STANDARD_BASE_PLATE_THICKNESS/2)
          @baseplate_group.entities.transform_entities scl_hole, big_hole

          @baseplate_group.entities.transform_entities tr1, big_hole
          bh2 = big_hole.copy
          @baseplate_group.entities.transform_entities tr2, big_hole

          tr1 = Geom::Transformation.translation(v2.reverse)
          @baseplate_group.entities.transform_entities tr1, bh2

          bh3 = bh2.copy
          bh4 = big_hole.copy

          v3 = v1.clone.reverse
          v3.length = @w+STANDARD_BASE_MARGIN

          tr3 = Geom::Transformation.translation(v3)

          @baseplate_group.entities.transform_entities tr3, [bh3, bh4]

          return @baseplate_group
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the base plate")
        end
      end

      def getExtents
        bb = @model.bounds
        bbp1 = Geom::Point3d.new(1000,1000,0)
        bbp2 = Geom::Point3d.new(1000,-1000,0)
        bbp3 = Geom::Point3d.new(-1000,1000,0)
        bbp4 = Geom::Point3d.new(-1000,-1000,0)
        bb.add(bbp1, bbp2, bbp3, bbp4)
        return bb
      end

      def insert_base_plates(type, center)
        begin
          # UI.messagebox("@h is #{@h}, @w is #{@w}")
          h = [@h,@w].sort
          case type
          when 'SQ'
            base_type = "#{h[-1].to_i}_ SQ"
          when 'OC'
            base_type = "#{h[-1].to_i}_ OC"
          when 'IL'
            base_type = "#{h[-1].to_i}_ IL"
          when 'IC'
            base_type = "#{h[-1].to_i}_ IC"
          when 'EX'
            base_type = "#{h[-1].to_i}_ EX"
          when 'DR'
            base_type = "#{h[-1].to_i}_ DR"
          when 'DL'
            base_type = "#{h[-1].to_i}_ DL"
          when 'DI'
            base_type = "#{h[-1].to_i}_ DI"
          else
            p 'selected blank'
            plate = draw_parametric_plate(sq_plate(@w, @h))
            # etch_plate(plate, @hss_inner_group)
          end
          p "base type after is #{base_type}"

          file_path1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{base_type}.skp", "Plugins"
          if plate
            p 'drawing parametric baseplate'
            etch_plate(plate, @hss_inner_group)
            add_plate_compass(plate, ORIGIN)
            color_by_thickness(plate, STANDARD_BASE_PLATE_THICKNESS.to_f)
            classify_as_plate(plate)

          else
            p 'grabbed plate from library'
            @base_group = @hss_outer_group.entities.add_group
            @base_group.name = 'Base Plate'

            @base_plate = @definition_list.load file_path1

            slide_vec = Geom::Vector3d.new(@w/2, @h/2, 0)
            slide_base = Geom::Transformation.translation(slide_vec)
            @bp = @base_group.entities.add_instance @base_plate, center
            etch_plate(@bp, @hss_inner_group)
            color_by_thickness(@base_group, STANDARD_BASE_PLATE_THICKNESS.to_f)
            classify_as_plate(@base_group)
            @bp.explode
          end
          #NEEDS#

          #Conditions if the hss is different sizes
          #conditions if the hss is rectangular (probs build from scratch, or use defualt and make group for editing)
          #add Etch marks that fit appropriate size
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the base plate")
        end
      end

      def sq_plate(w, h)
        points = [
          p1 = [(-(w/2)-STANDARD_BASE_MARGIN), (-(h/2)-STANDARD_BASE_MARGIN), 0],
          p2 = [((w/2)+STANDARD_BASE_MARGIN), (-(h/2)-STANDARD_BASE_MARGIN), 0],
          p3 = [(w/2)+STANDARD_BASE_MARGIN, ((h/2)+STANDARD_BASE_MARGIN), 0],
          p4 = [(-(w/2)-STANDARD_BASE_MARGIN), ((h/2)+STANDARD_BASE_MARGIN), 0]
        ]
        return points
      end

      def add_name_label(vec)
       begin
        @name_label_group = @hss_outer_group.entities.add_group
        @name_label_group.name = @tube_name
        ####################
        beam_direction = vec
        heading = Geom::Vector3d.new beam_direction
        heading[2] = 0
        angle = heading.angle_between NORTH

         #Adds in the label of the name of the beam at the center on both sides
        component_names = []
        @definition_list.map {|comp| component_names << comp.name}
        if component_names.include? @tube_name
          # p 'includes name'
          comp_def = @definition_list["#{@tube_name}"]
        else
          # p 'created name'
          comp_def = @definition_list.add "#{@tube_name}"
          comp_def.description = "#{@tube_name} label"
          ents = comp_def.entities
          _3d_text = ents.add_3d_text("#{@tube_name}", TextAlignCenter, "1CamBam_Stick_7", false, false, LABEL_HEIGHT, 3.0, 0.0, false, 0.0)
          # p "loaded CamBam_Stick_7: #{_3d_text}"
          save_path = Sketchup.find_support_file "Components", ""
          comp_def.save_as(save_path + "/#{@tube_name}.skp")
        end

        hss_name_label = @name_label_group.entities.add_instance comp_def, ORIGIN

        rot_to_pos = Geom::Transformation.rotation(ORIGIN, Y_AXIS, 270.degrees)
        hss_name_label.transform! rot_to_pos

        dist_to_slide = ((@h - hss_name_label.bounds.height)/2)
        # p dist_to_slide
        y_copy = Y_AXIS.clone
        y_copy.length = dist_to_slide
        slide_to_center = Geom::Transformation.translation(y_copy)
        hss_name_label.transform! slide_to_center

        if @hss_is_rotated
          #set to wide face of hss
          rot_again = Geom::Transformation.rotation(@center_of_column.position, Z_AXIS, 90.degrees)
          hss_name_label.transform! rot_again
          vctr = Y_AXIS.clone.reverse
          vctr.length = (@h - @w)/2
          # p vctr
          adjust = Geom::Transformation.translation(vctr)
          hss_name_label.transform! adjust
        end

        labels = []
        if @is_column
          if @h == @w #square column
            for n in 1..3
              labels.push hss_name_label.copy
              rotation_incrememnts = 90.degrees
            end
          elsif @w >= 3 && !@hss_is_rotated
            label2 = hss_name_label.copy
            labels.push label2
            rot1 = Geom::Transformation.rotation @center_of_column.position, Z_AXIS, 90.degrees
            @name_label_group.entities.transform_entities rot1, label2

            dist = (@h-@w)/2

            sld = Geom::Transformation.translation Geom::Vector3d.new(0,-dist,0)
            @name_label_group.entities.transform_entities sld, label2
            rotation_incrememnts = 180.degrees
            labels.push hss_name_label
            labels.push hss_name_label.copy
            label2.copy
          elsif @w < 3 && @hss_is_rotated
            labelcop = hss_name_label.copy
            labels.push labelcop

            rot_again = Geom::Transformation.rotation(@center_of_column.position, Z_AXIS, 90.degrees)
            rot_cop = hss_name_label.copy
            rot_cop.transform! rot_again
            vctr = Y_AXIS.clone.reverse
            vctr.length = (@h - @w)/2
            # p vctr
            adjust = Geom::Transformation.translation(vctr)
            rot_cop.transform! adjust

          else
            labels.push hss_name_label.copy
            rotation_incrememnts = 180.degrees
          end
        else #hss is a beam so only do 2 labels
          name_copy =  hss_name_label.copy
          labels.push name_copy
          rotation_incrememnts = 180.degrees

          flip1 = Geom::Transformation.rotation(hss_name_label.bounds.center, Z_AXIS, 180.degrees)
          flip2 = Geom::Transformation.rotation(hss_name_label.bounds.center, Y_AXIS, 180.degrees)
          if @hss_is_rotated
            flip = flip2
          else
            flip = flip1 * flip2
          end
          @name_label_group.entities.transform_entities flip, name_copy
        end

        labels.each_with_index do |l,i|
          # p rotation_incrememnts.radians
          rot = Geom::Transformation.rotation(@center_of_column.position, Z_AXIS, (rotation_incrememnts*(i+1)))
          l.transform! rot
        end

        dist_to_slide2 = (vec.length - @name_label_group.bounds.depth) / 2
        z_copy = Z_AXIS.clone
        z_copy.length = dist_to_slide2
        slide_to_mid = Geom::Transformation.translation(z_copy)

        @name_label_group.transform! slide_to_mid

        ####################
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading the labels")
        end
      end

      def add_studs(length, spread)
        begin
          max_dist_from_hss_end = spread*0.75

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{HLF_INCH_STD}", "Plugins"
          @half_inch_stud = @definition_list.load file_path
          start_dist = MINIMUM_STUD_DIST_FROM_HSS_ENDS
          copies = ((length - (start_dist*2))/spread).to_i

          remaining_working_space = (length - ((spread*copies)+start_dist))

          if remaining_working_space > max_dist_from_hss_end
            start_dist = (length - (copies*spread))/2
          end

          if @east_stud_selct
            e_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(e_stud, 0.5)
            rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 90.degrees)
            @hss_outer_group.entities.transform_entities rot, e_stud

            vec = Geom::Vector3d.new(@w/2,0,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, e_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, e_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, e_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}
          end

          if @west_stud_selct
            w_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(w_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, Y_AXIS, 270.degrees)
            @hss_outer_group.entities.transform_entities rot, w_stud

            vec = Geom::Vector3d.new(-@w/2,0,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, w_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, w_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, w_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}
          end

          if @north_stud_selct
            n_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(n_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, X_AXIS, 270.degrees)
            @hss_outer_group.entities.transform_entities rot, n_stud

            vec = Geom::Vector3d.new(0,@h/2,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, n_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, n_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, n_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}
          end

          if @south_stud_selct
            s_stud = @hss_outer_group.entities.add_instance @half_inch_stud, @center_of_column.position
            color_by_thickness(s_stud, 0.5)

            rot = Geom::Transformation.rotation(@center_of_column.position, X_AXIS, 90.degrees)
            @hss_outer_group.entities.transform_entities rot, s_stud

            vec = Geom::Vector3d.new(0,-@h/2,0)
            slide1 = Geom::Transformation.translation(vec)
            @hss_outer_group.entities.transform_entities slide1, s_stud

            vec2 = Geom::Vector3d.new(0,0,start_dist)
            slide_to_start = Geom::Transformation.translation(vec2)

            @hss_outer_group.entities.transform_entities slide_to_start, s_stud

            copy_dist = vec2.clone
            copy_dist.length = spread

            list = array_studs(copies, s_stud, copy_dist)
            list.each {|c| color_by_thickness(c, 0.5)}
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the @half_inch_stud into the model")
        end
      end # end add_studs

      def add_up_arrow(length, spread)
        begin

          up_arrow_group = @hss_outer_group.entities.add_group()

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{UP_DRCTN}", "Plugins"
          up_d = @definition_list.load file_path

          up_arrow = up_arrow_group.entities.add_instance up_d, ORIGIN

          rot = Geom::Transformation.rotation ORIGIN, X_AXIS, 90.degrees
          rot1 = Geom::Transformation.rotation ORIGIN, Y_AXIS, 270.degrees
          up_arrow_group.entities.transform_entities rot*rot1, up_arrow

          slgp = Geom::Transformation.translation (Geom::Vector3d.new(0,@h/2,0))
          @hss_outer_group.entities.transform_entities slgp, up_arrow_group

          up_copy1 = up_arrow.copy

          pt = Geom::Point3d.new(@w/2,0,0)
          rot = Geom::Transformation.rotation pt, Z_AXIS, 180.degrees
          up_arrow_group.entities.transform_entities rot, up_copy1

          if @w >= 3
            up_arrow2 = up_arrow.copy
            rot1 = Geom::Transformation.rotation pt, Z_AXIS, 90.degrees
            up_arrow_group.entities.transform_entities rot1, up_arrow2

            dist = (@h-@w)/2

            sld = Geom::Transformation.translation Geom::Vector3d.new(0,-dist,0)
            up_arrow_group.entities.transform_entities sld, up_arrow2

            up_arrow_group.entities.transform_entities rot, up_arrow2.copy

          end

          # start_dist = ((length.to_inch%spread))/2
          # copies = (length.to_i/spread)

          # if start_dist < MINIMUM_STUD_DIST_FROM_HSS_ENDS
          #   start_dist += spread/2
          #   copies -= 1
          # end

          dist = length-16

          up_vec = Geom::Vector3d.new(0,0,dist)
          slide_up = Geom::Transformation.translation(up_vec)

          @hss_outer_group.entities.transform_entities slide_up, up_arrow_group

        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting up arrow")
        end
      end

      def add_direction_labels()

        begin

          drctn_lbls_group = @hss_outer_group.entities.add_group()

          #Gets the file paths for the labels
          f1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{NORTH_LABEL}", "Plugins/"
          f2 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{SOUTH_LABEL}", "Plugins/"
          f3 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{EAST_LABEL}", "Plugins/"
          f4 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{WEST_LABEL}", "Plugins/"
          n = @definition_list.load f1
          s = @definition_list.load f2
          e = @definition_list.load f3
          w = @definition_list.load f4

          north = drctn_lbls_group.entities.add_instance(n, ORIGIN)
          south = drctn_lbls_group.entities.add_instance(s, ORIGIN)
          east = drctn_lbls_group.entities.add_instance(e, ORIGIN)
          west = drctn_lbls_group.entities.add_instance(w, ORIGIN)


          n_traj = Geom::Vector3d.new(@w/2, @h, 10)
          n_rot_x = Geom::Transformation.rotation([0,0,0], X_AXIS, 90.degrees)
          n_rot_z = Geom::Transformation.rotation([0,0,0], Z_AXIS, 180.degrees)
          north.transform! (n_rot_z*n_rot_x)
          north.transform! n_traj

          s_traj = Geom::Vector3d.new(@w/2, 0, 10)
          s_rot_x = Geom::Transformation.rotation([0,0,0], X_AXIS, 90.degrees)
          s_rot_z = Geom::Transformation.rotation([0,0,0], Z_AXIS, 180.degrees)
          south.transform! (s_rot_x)
          south.transform! s_traj

          e_traj = Geom::Vector3d.new(@w, @h/2, 10)
          e_rot_x = Geom::Transformation.rotation([0,0,0], X_AXIS, 90.degrees)
          e_rot_z = Geom::Transformation.rotation([0,0,0], Y_AXIS, 90.degrees)
          east.transform! (e_rot_x*e_rot_z)
          east.transform! e_traj

          w_traj = Geom::Vector3d.new(0, @h/2, 10)
          w_rot_x = Geom::Transformation.rotation([0,0,0], X_AXIS, 90.degrees)
          w_rot_z = Geom::Transformation.rotation([0,0,0], Y_AXIS, 270.degrees)
          west.transform! (w_rot_x*w_rot_z)
          west.transform! w_traj
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the direction labels")
        end
      end

      def align_tube(vec, group)
        begin

          group.transform! @trans #Fixed this so the column is not scaled
          adjustment_vec = vec.clone
          if @is_column
            adjustment_vec.length = (@base_thickness+@start_tolerance) #this ,ight also need to account for the height from slab (1 1/2")
          else
            if @hss_has_cap
              adjustment_vec.length = @cap_thickness #this ,ight also need to account for the height from slab (1 1/2")
            else
              adjustment_vec.length = 0 #this ,ight also need to account for the height from slab (1 1/2")
            end
          end
          slide_up = Geom::Transformation.translation(adjustment_vec)
          @entities.transform_entities(slide_up, group)

          if vec[2] < 0 && @is_column
            if vec.parallel? Z_AXIS
              rot_vec = X_AXIS
            else
              rot_vec = vec.cross(Z_AXIS)
            end
            rot_upright = Geom::Transformation.rotation(@vec_center, rot_vec, 180.degrees)
            group.transform! rot_upright
            # p 'FLIPPED'
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem aligning the tube with the slected points")
        end
      end

      def extrude_tube(vec, face)
        face.pushpull(vec.length)
      end

      def create_geometry(pt1, pt2, view)
        model = view.model
        model.start_operation("Draw TS", true)

        vec = pt2 - pt1
        if( vec.length < 2 )
            UI.beep
            UI.messagebox("Please draw a HSS longer than 2")
            return
        end

        @vec_center = Geom::Point3d.new((pt1[0]+pt2[0])/2,(pt1[1]+pt2[1])/2,(pt1[2]+pt2[2])/2)

        draw_tube(vec)

        model.commit_operation
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
        @trans = Geom::Transformation.axes @ip1.position, @vx, @vy, @vz.reverse if @ip1.valid? && not_a_zero_vec
        @trans2 = Geom::Transformation.axes @ip2.position, @vx, @vy, @vz.reverse if @ip1.valid? && not_a_zero_vec
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

          @drawn = true
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
              h1 = Geom::Point3d.new(0, 0, @r),
              # a1,
              ip1 = Geom::Point3d.new(@tw, 0, @tw),
              ip2 = Geom::Point3d.new(@w-@tw, 0, @tw),
              ip3 = Geom::Point3d.new(@w-@tw, 0, @h-@tw),
              ip4 = Geom::Point3d.new(@tw, 0, @h-@tw)
            ]

            mlp = Geom::Point3d.new(-@w*0.5,0,0) #mlp is move left
            mdp = Geom::Point3d.new(0,0,-@h*0.5) #mdp is move down point

            move_left = Geom::Transformation.new(mlp)
            move_down = Geom::Transformation.new(mdp)

            move_ghost_points = move_left*move_down

            @ip1points.each{|p| p.transform! move_ghost_points}

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