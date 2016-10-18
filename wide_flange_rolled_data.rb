module EA_Extensions623
  module EASteelTools

    class RolledSteel < RolledDialog
      include BeamLibrary
      ###############
      ## CONSTANTS ##
      ###############

      def initialize(data)
        @explode = lambda {|e| e.explode}
        @erase   = lambda {|e| e.erase! }

        @radius             = 3 #root radius of the steel
        @segment_length     = 8 #length of the center of rolled steel segments
        @model              = Sketchup.active_model
        @entities           = @model.active_entities
        @selected_curve     = @model.selection # This is the predetermined curve that the will be rolled to
        @materials          = @model.materials
        @material_names     = @materials.map {|color| color.name}
        @definition_list    = @model.definitions

        @@beam_name         = data[:name]               #String 'W(height_class)X(weight_per_foot)'
        @@height_class      = data[:height_class]       #String 'W(number)'
        @@beam_data         = data[:data]               #Hash   {:d=>4.16, :bf=>4.06, :tf=>0.345, :tw=>0.28, :r=>0.2519685039370079, :width_class=>4}"
        @@placement         = data[:placement]          #String 'TOP' or 'BOTTOM'
        @@has_holes         = data[:has_holes]          #Boolean
      # @@hole_spacing      = data[:stagger]            #Integer 16 or 24
        @@flange_holes      = data[:flange_holes]       #Boolean
        @@web_holes         = data[:web_holes]          #Boolean
        @@cuts_holes        = data[:cuts_holes]         #Boolean
        @@has_stiffeners    = data[:stiffeners]         #Boolean
        @@has_shearplates   = data[:shearplates]        #Boolean
        @@stiff_thickness   = data[:stiff_thickness]    #String '1/4' or '3/8' or '1/2'
        @@shearpl_thickness = data[:shearpl_thickness]  #String '1/4' or '3/8' or '1/2'
        @@roll_type         = data[:roll_type]
        @@radius_offset     = data[:radius_offset]

        colors = {
          orange:  {name: ' C ¾" Thick',    rgb: [225,135,50]},
          yellow:  {name: ' D ⅝" Thick',    rgb: [225,225,50]},
          green:   {name: ' E ½" Thick',    rgb: [50,225,50 ]},
          blue:    {name: ' F ⅜" Thick',    rgb: [50,118,225]},
          indigo:  {name: ' G 5/16" Thick', rgb: [118,50,225]},
          purple:  {name: ' H ¼" Thick',    rgb: [186,50,225]}
        }

        case @@stiff_thickness
        when '1/4'
          @stiff_scale = 2 #this doubles the size of the plate from it's standard 1/8" to 1/4"
          clr1 = colors[:purple][:name]
          rgb  = colors[:purple][:rgb]
        when '5/16'
          @stiff_scale = 2.5
          clr1 = colors[:indigo][:name]
          rgb  = colors[:indigo][:rgb]
        when '3/8'
          @stiff_scale = 3
          clr1 = colors[:blue][:name]
          rgb  = colors[:blue][:rgb]
        when '1/2'
          @stiff_scale = 4
          clr1 = colors[:green][:name]
          rgb  = colors[:green][:rgb]
        when '5/8'
          @stiff_scale = 5
          clr1 = colors[:yellow][:name]
          rgb  = colors[:yellow][:rgb]
        when '3/4'
          @stiff_scale = 6
          clr1 = colors[:orange][:name]
          rgb  = colors[:orange][:rgb]
        end

        if @material_names.include? clr1
          @stiff_color = clr1
        else
          @stiff_color = @materials.add clr1
          culler = Sketchup::Color.new rgb
          @stiff_color.color = culler
        end

        case @@shearpl_thickness
        when '1/4'
          @shear_scale = 2
          clr2 = colors[:purple][:name]
          rgb2  = colors[:purple][:rgb]
        when '3/8'
          @shear_scale = 3
          clr2 = colors[:blue][:name]
          rgb2  = colors[:blue][:rgb]
        when '1/2'
          @shear_scale = 4
          clr2 = colors[:green][:name]
          rgb2  = colors[:green][:rgb]
        when '5/8'
          @shear_scale = 5
          clr2 = colors[:yellow][:name]
          rgb2  = colors[:yellow][:rgb]
        when '3/4'
          @shear_scale = 6
          clr2 = colors[:orange][:name]
          rgb2  = colors[:orange][:rgb]
        end

        if @material_names.include? clr2
          @shear_color = clr2
        else
          @shear_color = @materials.add clr2
          culler2 = Sketchup::Color.new rgb2
          @shear_color.color = culler2
        end

        values = data[:data]
        @hc    = data[:height_class].split('W').last.to_i #this gets just the number in the height class
        @h     = values[:d].to_f
        @w     = values[:bf].to_f
        @tf    = values[:tf].to_f
        @tw    = values[:tw].to_f
        @wc    = values[:width_class].to_f
        @r     = values[:r].to_f
        @number_of_sheer_holes = ((((@h - (2*@tf)) - 3).to_i / 3) +1)

        # Sets the stagger distance between the web holes
        if @hc < 14
          @webhole_stagger = @hc/2
        else
          @webhole_stagger = 6
        end

        #determines if the beam width is small enough to stagger the holes or not
        if @wc < 6.75
          @flange_hole_stagger = true
          # p 'Staggered'
        else
          @flange_hole_stagger = false
          # p 'i-5/8" from edge'
        end

        #the thirteen points on a beam
        @points = [
          pt1 = [0,0,0],
          pt2 = [@w,0,0],
          pt3 = [@w,0,@tf],
          pt4 = [(0.5*@w)+(0.5*@tw)+@r, 0, @tf],
          pt5 = [(0.5*@w)+(0.5*@tw), 0, (@tf+@r)],
          pt6 = [(0.5*@w)+(0.5*@tw), 0, (@h-@tf)-@r],
          pt7 = [(0.5*@w)+(0.5*@tw)+@r, 0, @h-@tf],
          pt8 = [@w,0,@h-@tf],
          pt9 = [@w,0,@h],
          pt10= [0,0,@h],
          pt11= [0,0,@h-@tf],
          pt12= [(0.5*@w)-(0.5*@tw)-@r, 0, @h-@tf],
          pt13= [(0.5*@w)-(0.5*@tw), 0, (@h-@tf)-@r],
          pt14= [(0.5*@w)-(0.5*@tw), 0, @tf+@r],
          pt15= [(0.5*@w)-(0.5*@tw)-@r, 0, @tf],
          pt16= [0,0,@tf]
        ]

      end

      def activate()
        model = @model
        model.start_operation("Roll Steel", true)

        set_groups(model)
        load_parts

        arc = draw_new_arc(@selected_curve)
        profile = draw_beam(@@beam_data)

        facearc = align_profile(profile, arc) #this returns an array. The FACE that has been aligned and the ARC

        # @@has_holes = false # uncomment this to toggle holes
        if @@has_holes
          web_holes    = add_web_holes(arc)    if @@web_holes
          flange_holes = add_flange_holes(arc) if @@flange_holes
          @c.erase! if !@@web_holes; @c2.erase! if !@@web_holes

          if @@cuts_holes
            @solid_group.explode
            web_holes.each(&@explode) if @@web_holes
            flange_holes.each(&@explode) if @@flange_holes
          end
        end

        point = Geom::Point3d.new(@top_edge.start.position)
        extrude_face(facearc[0], facearc[1])

        # Adds in the labels for the steel
        add_labels(point)

        erase_arc(arc)

        model.commit_operation

        Sketchup.send_action "selectSelectionTool:"
      end

      def load_parts
        file_path1 = Sketchup.find_support_file "ea_steel_tools/Beam Components/9_16 Hole Set.skp", "Plugins"
        file_path2 = Sketchup.find_support_file "ea_steel_tools/Beam Components/13_16 Hole Set.skp", "Plugins"
        file_path3 = Sketchup.find_support_file "ea_steel_tools/Beam Components/2½ x½_ Studs.skp", "Plugins"
        file_path4 = Sketchup.find_support_file "ea_steel_tools/Beam Components/UP.skp", "Plugins/"

        @nine_sixteenths_hole     = @definition_list.load file_path1
        @thirteen_sixteenths_hole = @definition_list.load file_path2
        @half_inch_stud           = @definition_list.load file_path3
        @up_arrow                 = @definition_list.load file_path4
      end

      def get_segment_count(percentage, radius, segment_length)
        pi = Math::PI*percentage
        seg_count = (2*pi*radius)/segment_length
        rounded_up = (seg_count.to_i)+1
        rounded_up += 1 if rounded_up.even?
        return rounded_up
      end

      def draw_new_arc(selected_arc)
        # Selected Arc Data
        arc = selected_arc[0].curve
        seg1 = arc.first_edge
        seg2 = arc.last_edge
        vertex1 = seg1.start
        vertex2 = seg2.end

        radius = arc.radius
        p radius
        p radius.class
        centerpoint = arc.center
        vec = arc.normal
        x_axis = arc.xaxis

        angle1 = arc.start_angle
        angle2 = arc.end_angle
        @inner_group.entities.add_cpoint centerpoint
        percent = angle2/360.degrees

        p @@roll_type

        # New Arc Data
        if @@roll_type == 'EASY'
          case @@placement[1]
          when 'O'
            extra = -1*(@w/2)
          when 'C'
            extra = 0
          when 'I'
            extra = (@w/2)
          end
          new_radius = radius+@@radius_offset+extra
        else
          case @@placement[0]
          when 'T'
            offset = -1*(@h/2)
          when 'B'
            offset = @h/2
          end
          new_radius = radius+@@radius_offset+offset

          if new_radius < @h*10
            UI.messagebox('WARNING: the radius you are attempting may not be achiveable by current camber rolling methods')
          end
        end

        @segment_count = get_segment_count(percent, radius, @segment_length)
        p @segment_count
        value = (@segment_length/2.0)/new_radius
        seg_angle = Math.asin(value)
        @hole_rotation_angle = seg_angle*4

        #this sets the web and flange hole counts
        @web_holes_count = ((@segment_count)/4).to_i
        @flange_hole_stagger ? @flange_hole_count = @web_holes_count : @flange_hole_count = @web_holes_count*2

        new_angle = (2.0*seg_angle*@segment_count)
        new_path = @solid_group.entities.add_arc centerpoint, x_axis, arc.normal, new_radius, angle1, new_angle, @segment_count
        new_arc = new_path[0].curve

        tune_new_arc(new_path, selected_arc)
        return new_arc
      end

      def tune_new_arc(new_arc, old_arc)
        curve = new_arc[0].curve
        old_curve = old_arc[0].curve
        center = curve.center

        a_old = old_curve.end_angle
        a_new = curve.end_angle

        angle = a_new - a_old

        # a_sel = old_arc.first.start.position
        b_sel = old_curve.last_edge.end.position
        referencepoint = Geom::Point3d.new b_sel[0], b_sel[1], b_sel[2]
        # a_new = new_arc.first.start.position
        b_new = curve.last_edge.end.position

        check_dist = b_new.distance referencepoint
        rot = Geom::Transformation.rotation center, curve.normal, angle
        @entities.transform_entities rot, curve

        new_dist = curve.last_edge.end.position.distance referencepoint

        if new_dist > check_dist
          reverse_rot = Geom::Transformation.rotation center, curve.normal, (angle*-1.5)
          @entities.transform_entities reverse_rot, curve
        end
      end

      def align_profile(face, arc)
        face.normal
        path = arc
        center = path.center
        start_edge = path.first_edge
        start_point = start_edge.start.position
        x_vec = path.xaxis
        arc_normal = path.normal
        x_direction_from_start = start_point - Geom::Point3d.new(start_point[0]+1, start_point[1], start_point[2])

        place2nd = Geom::Transformation.translation start_point
        @entities.transform_entities place2nd, face
        start_vec = start_edge.end.position - start_point

        x = Geom::Vector3d.new(1,0,0)
        y = Geom::Vector3d.new(0,1,0)
        z = Geom::Vector3d.new(0,0,1)

        xy_only_vector = Geom::Vector3d.new(start_vec[0], start_vec[1], 0)

        if @@roll_type == 'EASY'
          align_easy(face, xy_only_vector, z, start_point)
          align_hard(face, start_vec, @bottom_edge.line[1], start_point)
          align_combo(face, arc_normal, start_vec, start_point)
        else
          align_easy(face, xy_only_vector, z, start_point)
          align_hard(face, start_vec, @bottom_edge.line[1], start_point)
          align_harder(face, arc_normal, start_vec, start_point, center)
          position_hroll(face, center)
        end

        if face.normal.samedirection? start_vec
          face_loop = face.outer_loop
          r = Geom::Transformation.rotation start_point, @side_line.line[1], 180.degrees
          @entities.transform_entities r, face
        end

        position_arc(path)

        @hole_point = Geom::Point3d.new @face_handles[:top_inside].position
        v = start_edge.end.position - start_edge.start.position
        v.length = @segment_length/2

        v2 = @side_line.line[1]
        v2.length = @hc/4

        @top_edge_vector = @top_edge.start.position - @top_edge.end.position

        temp_group = @entities.add_group
        corners = [@top_edge.start.position, @top_edge.end.position, @bottom_edge.start.position, @bottom_edge.end.position]

        corners.each {|point| temp_group.entities.add_cpoint point }

        if @@has_holes
          @c = @solid_group.entities.add_cpoint temp_group.bounds.center

          t = Geom::Transformation.new(v)
          t2 = Geom::Transformation.new(v2)
          go = t*t2
          @entities.transform_entities go, @c
          @c2 = @solid_group.entities.add_cpoint @c.position
          v2.reverse!
          v2.length = @hc/2
          t = Geom::Transformation.new(v2)
          @entities.transform_entities t, @c2
        end

        @start_direction_vector = face.normal
        temp_group.entities.clear!
        temp_group.erase!

        return face, path
      end

      def extrude_face(face, path)
        face.followme(path.edges)
      end

      def erase_arc(arc)
         arc.edges.each(&@erase)
      end

      def position_hroll(face, centerpoint)
        vec = (@face_handles[:bottom_inside].position) - @face_handles[:top_inside].position
        vec.length = @h/2
        slide_down = Geom::Transformation.new(vec)
        #moves the beam down inside the arc when you want the cure on top
        @entities.transform_entities slide_down, face
      end

      def position_arc(path)
        vec = path.normal
        vec.length = @h*2
        slide_out = Geom::Transformation.new(vec)
        @entities.transform_entities slide_out, path
      end

      def align_combo(face, vector, rotational_axis, point_of_rotation)
        vec = @side_line.line[1]
        check = vec.parallel? vector
        if not check
          angle = vec.angle_between vector
          rot = Geom::Transformation.rotation point_of_rotation, rotational_axis, angle
          @entities.transform_entities rot, face
          align_combo(face, vector, rotational_axis, point_of_rotation)
        else
          return
        end
      end

      def align_easy(face, vector, rotational_axis, point_of_rotation)
        face_normal = face.normal
        if not face_normal.parallel? vector
          angle = face_normal.angle_between vector
          rot1 = Geom::Transformation.rotation point_of_rotation, rotational_axis, angle
          @entities.transform_entities rot1, face
          align_easy(face, vector, rotational_axis, point_of_rotation)
        else
          return
        end
      end

      def align_hard(face, vector, rotational_axis, point_of_rotation)
        check1 = face.normal.parallel? vector
        if not check1
          angle = face.normal.angle_between vector
          rot = Geom::Transformation.rotation point_of_rotation, rotational_axis, angle
          @entities.transform_entities rot, face
          align_hard(face, vector, rotational_axis, point_of_rotation)
        else
          return
        end
      end

      def align_harder(face, vector, rotational_axis, point_of_rotation, arc_center)
        vec = @top_edge.line[1]
        check = vec.parallel? vector
        if not check
          angle = vec.angle_between vector
          rot = Geom::Transformation.rotation point_of_rotation, rotational_axis, angle
          @entities.transform_entities rot, face
          align_harder(face, vector, rotational_axis, point_of_rotation, arc_center)
        elsif (@top_edge.start.position.distance arc_center) < (point_of_rotation.distance arc_center)
          # puts 'inside, GET OUT!'
          rot = Geom::Transformation.rotation point_of_rotation, rotational_axis, 180.degrees
          @entities.transform_entities rot, face
        else
          return
        end
      end

      def draw_beam(data)
        # temporarily groups the face so other geometry wont interere with operations
        beam_ents = @solid_group.entities
        #set variable for the Name, Height Class, Height, Width, flange thickness, web thickness and radius for the beams
        segs = @radius
        #sets the working guage width for the beam
        case @wc
        when 4
          @guage_width = 2.25
        when 5, 5.25, 5.75
          @guage_width = 2.75
        when 5.5 .. 7.5
          @guage_width = 3.5
        when 8 .. 11.5
          @guage_width = 5.5
        when 12 .. 16.5
          if @hc > 36 && @hc < 40
            @guage_width = 7.5
          else
            @guage_width = 5.5
          end
        end

        #sets the center of the radius for each beam radius
        arc_radius_points = [
          [(@w*0.5)+(@tw*0.5)+@r, 0, @tf+@r], [(@w*0.5)+(@tw*0.5)+@r, 0, (@h-@tf)-@r], [(@w*0.5)-(@tw*0.5)-@r, 0, (@h-@tf)-@r], [(@w*0.5)-(@tw*0.5)-@r, 0, @tf+@r]
        ]

        #sets the information for creating the radius @points
        normal = [0,1,0]
        zero_vec = [0,0,1]
        @radius = []
        turn = 180
        #draws the arcs and rotates them into position
        arc_radius_points.each do |center|
          a = beam_ents.add_arc center, zero_vec, normal, @r, 0, 90.degrees, segs
          rotate = Geom::Transformation.rotation center, [0,1,0], turn.degrees
          beam_ents.transform_entities rotate, a
          @radius << a
          turn += 90
        end

        #draws the wire frame outline of the beam to create a face
        @segments = []
        count = 1
        beam_outline = @points.each do |pt|
           a = beam_ents.add_line pt, @points[count.to_i]
            count < 15 ? count += 1 : count = 0
            @segments << a
        end

        #erases the unncesary lines created in the outline
        @segments.each_with_index do |line, i|
          @top_edge = line if i == 8
          @bottom_edge = line if i == 0
          @side_line = line if i == 4

          if i == 3 || i == 5 || i == 11 || i == 13
            @segments.slice(i)
            line.erase!
          end
        end

        # get handles to control the placement of the profile
        @face_handles = {
          top_inside: @top_edge.end,
          top_outside: @top_edge.start,
          bottom_inside: @bottom_edge.start,
          bottom_outside: @bottom_edge.end
        }

        #adds the radius arcs into the array of outline @segments
        @radius.each do |r|
          @segments << r
        end

        @control_segment = beam_ents.add_line @points[0], @points[1]

        #sets all of the connected @segments of the outline into a variable
        segs = @segments.first.all_connected

        #move the beam outline to center on the axes
        m = Geom::Transformation.new [-0.5*@w, 0, 0]
        beam_ents.transform_entities m, segs

        #rotate the beam 90° to align with the red axes before grouping
        r = Geom::Transformation.rotation [0,0,0], [0,0,1], 90.degrees
        beam_ents.transform_entities r, segs

        #adds the face to the beam outline
        face = beam_ents.add_face segs

        #returns the face result of the method
        return face
      end

      def set_groups(model)
        active_model = Sketchup.active_model.active_entities.parent
        # Sets the outer group for the beam and should be named "Beam"
        @outer_group = active_model.entities.add_group
        @outer_group.name = 'Beam'
        # Sets the inside group for the beam and should be named "W--X--"
        @inner_group = @outer_group.entities.add_group
        @inner_group.name = "#{@@beam_name}"
        @steel_layer = model.layers.add " Steel"
        @inner_group.layer = @steel_layer
        # Sets the inner most group for the beam and should be named "Difference"
        @solid_group = @inner_group.entities.add_group
        #############################
        ##    GROUP STRUCTURE (3 groups)
        # @outer_group {
        #   plates, studs
        #   @inner_group {
        #     holes, labels
        #     @solid_group {
        #       geometry
        #     }
        #   }
        # }
      end

      def clear_groups
        @outer_group = nil
        @inner_group = nil
        @solid_group = nil
      end

      def add_labels(point)

        centerpoint = point
        # start_point = arc.start_edge.start.position

        beam_label_group = @inner_group.entities.add_group
        label_ents = beam_label_group.entities
        #Adds in the label of the name of the beam at the center on both sides
        component_names = []
        @definition_list.map {|comp| component_names << comp.name}
        if component_names.include? @@beam_name
          comp_def = @definition_list["#{@@beam_name}"]
        else
          comp_def = @definition_list.add "#{@@beam_name}"
          comp_def.description = "The #{@@beam_name} label"
          ents = comp_def.entities
          _3d_text = ents.add_3d_text("#{@@beam_name}", TextAlignCenter, "1CamBam_Stick_7", false, false, 3.0, 3.0, 0.0, false, 0.0)
          save_path = Sketchup.find_support_file "Components", ""
          comp_def.save_as(save_path + "/#{@@beam_name}.skp")
        end

        beam_label = label_ents.add_instance comp_def, centerpoint

      end

      def add_web_holes(path)
        holes = []
        scale_web = @tw/2
        scale_hole = Geom::Transformation.scaling ORIGIN, 1, 1, scale_web

        webhole1 = @inner_group.entities.add_instance @nine_sixteenths_hole, ORIGIN
        webhole1.transform! scale_hole

        z = Geom::Vector3d.new(0,0,1)

        angle = @top_edge_vector.angle_between z
        rot1 = Geom::Transformation.rotation ORIGIN, [0,1,0], angle
        webhole1.transform! rot1

        align_hole(webhole1, @top_edge_vector, 0)

        c = webhole1.bounds.center
        adjust = @c.position - c

        @c.erase!; @c2.erase!
        # adjust = @top_edge.start.position - c # <-----this is used for testing
        move = Geom::Transformation.new adjust
        webhole1.transform! move

        #Here on the web by now

        webhole2 = webhole1.copy

        slide_down = Geom::Vector3d.new @side_line.line[1]
        slide_down.length = @webhole_stagger
        slide_down.reverse!
        move_down = Geom::Transformation.new(slide_down)
        webhole2.transform! move_down

        bottom_row_holes_count = @web_holes_count
        top_row_web_holes = @web_holes_count

        if @segment_count % 4 == 1 || @segment_count % 4 == 2
          bottom_row_holes_count -= 1
        end

        move_along_curve(webhole2, path, @hole_rotation_angle) #bottom row holes
        copy_along_curve(webhole1, path, @hole_rotation_angle*2, 0, top_row_web_holes, holes ) #top row holes
        copy_along_curve(webhole2, path, @hole_rotation_angle*2, 0, bottom_row_holes_count, holes ) #bottom row holes

        holes.push webhole1, webhole2
        return holes
      end

      def add_flange_holes(path)
        holes = []
        scale_flange = @tf/2
        scale_hole = Geom::Transformation.scaling ORIGIN, 1, 1, scale_flange

        flangehole1 = @inner_group.entities.add_instance @nine_sixteenths_hole, ORIGIN
        flangehole1.transform! scale_hole

        z = Geom::Vector3d.new(0,0,1)
        vec = @side_line.line[1]
        angle = vec.angle_between z

        rot = Geom::Transformation.rotation ORIGIN, [0,1,0], angle
        flangehole1.transform! rot

        align_hole(flangehole1, vec, 0)
        # move hole to a corner of the flange
        # c = flangehole1.bounds.center
        position = @top_edge.start.position - ORIGIN

        move = Geom::Transformation.new position
        flangehole1.transform! move

        # set it 4" up the arc
        vec1 = @start_direction_vector.clone
        vec1.reverse!
        vec1.length = @segment_length/2
        slide_up = Geom::Transformation.new(vec1)

        flangehole1.transform! slide_up
        # determine if the holes stagger or are 1-5/8" from edge
        # set it to width
        vec2 = @top_edge_vector.clone
        @flange_hole_stagger ? vec2.length = ((@w/2)-(@guage_width/2)) : vec2.length = 1.6250
        vec2.reverse!
        slide1 = Geom::Transformation.new vec2
        flangehole1.transform! slide1
        # copy another one
        flangehole2 = flangehole1.copy
        # position the copy
        vec3 = vec2.clone
        @flange_hole_stagger ? vec3.length = @guage_width : vec3.length = @w-((1.6250)*2)
        slide2 = Geom::Transformation.new vec3
        flangehole2.transform! slide2

        top_inside_holes     = @flange_hole_count
        top_outside_holes    = @flange_hole_count
        bottom_inside_holes  = @flange_hole_count
        bottom_outside_holes = @flange_hole_count

        if @flange_hole_stagger
          move_along_curve(flangehole2, path, @hole_rotation_angle)
          hole_rotation = @hole_rotation_angle*2
          if @segment_count % 4 == 1 || @segment_count % 4 == 2
            top_outside_holes -= 1
            bottom_outside_holes -= 1
          end
        else
          hole_rotation = @hole_rotation_angle
          if @segment_count % 4 == 3 || @segment_count % 4 == 0
            top_inside_holes     += 1
            top_outside_holes    += 1
            bottom_inside_holes  += 1
            bottom_outside_holes += 1
          end
        end

        # copy holes to the other flange
        flangehole3 = flangehole1.copy
        flangehole4 = flangehole2.copy

        vec4 = @bottom_edge.start.position - @top_edge.end.position
        vec4.length = @h-@tf
        send_to_flange = Geom::Transformation.new vec4
        flangehole3.transform! vec4
        flangehole4.transform! vec4

        # array all holes along the arc
        copy_along_curve(flangehole1, path, hole_rotation, 0, top_inside_holes, holes ) #top inside hole
        copy_along_curve(flangehole2, path, hole_rotation, 0, top_outside_holes, holes ) #top outside hole
        copy_along_curve(flangehole3, path, hole_rotation, 0, bottom_inside_holes, holes ) #bottom inside hole
        copy_along_curve(flangehole4, path, hole_rotation, 0, bottom_outside_holes, holes ) #bottom outside hole

        holes.push flangehole1, flangehole2, flangehole3, flangehole4
        return holes
      end

      def move_along_curve(hole, arc, angle)
        rot = Geom::Transformation.rotation arc.center, arc.normal, angle
        hole.transform! rot
      end

      def copy_along_curve(hole, arc, angle, number_of_copies, max, loot)
        if number_of_copies == max
          return loot
        else
          rot = Geom::Transformation.rotation arc.center, arc.normal, angle
          new_hole = hole.copy
          loot << new_hole
          new_hole.transform! rot
          number_of_copies += 1
          copy_along_curve(new_hole, arc, angle, number_of_copies, max, loot)
        end
      end

      def align_hole(hole, align_vec, count)
        hole_loop = get_hole_component_curve(hole)
        hole_vec = hole.transformation.zaxis
        return if count == 10
        return if hole_vec.parallel? align_vec
        count += 1
        v1 = Geom::Vector3d.new(hole_vec[0], hole_vec[1], 0)
        v2 = Geom::Vector3d.new(align_vec[0], align_vec[1], 0)
        angle = v1.angle_between v2
        tran = Geom::Transformation.rotation ORIGIN, [0,0,1], angle
        hole.transform! tran
        align_hole(hole, align_vec, count)
      end

      def get_hole_component_curve(hole)
        hole.definition.entities[0].definition.entities.each do |ent|
          if ent.is_a? Sketchup::Edge
            return ent.curve
          end
        end
      end

    end
  end
end