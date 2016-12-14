module EA_Extensions623
  module EASteelTools

    class RolledSteel < RolledDialog
      include BeamLibrary
      ###############
      ## CONSTANTS ##
      ###############

      ##################################
      #@@@@@@@@ BEAM variables @@@@@@@@#
      ##################################
      #Sets the root radus for the beams
      RADIUS = 3
      #This sets the distance from the end of the beam the direction labels go
      LABELX = 10
      #Sets the distance from the ends of the beams that holes cannot be, in inches
      NO_HOLE_ZONE = 6
      #Setc the north direction as the green axis
      NORTH = Geom::Vector3d.new [0,1,0]
      # This sets the stiffener location from each end of the beam
      STIFF_LOCATION = 2
      #Distance from the end of the beam the 13/14" holes are placed
      BIG_HOLES_LOCATION = 4
      # Minimum distance from the inside of the flanges to the center of 13/16" holes can be
      MIN_BIG_HOLE_DISTANCE_FROM_KZONE = 1.25

      def initialize(data)

        @explode = lambda {|e| e.explode}
        @erase   = lambda {|e| e.erase! }

        @geometry     = []
        @holes        = []
        @web_holes    = []
        @flange_holes = []
        @guage_holes  = []
        @studs        = []
        @shear_holes  = []
        @labels       = []
        @sh_plates    = []
        @stiff_plates = []

        @arc  = 0 #This is the new arc
        @face = 0 # This is the profile

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
        @h     = values[:d].to_f #overall beam height
        @w     = values[:bf].to_f  #overall beam width
        @tf    = values[:tf].to_f  #flange thickness
        @tw    = values[:tw].to_f  #web thickness
        @wc    = values[:width_class].to_f  #width class
        @r     = values[:r].to_f #root radius

        # Sets the stagger distance between the web holes
        if @hc < 14
          @webhole_stagger = @hc/2
          @first_web_hole_dist_from_center = (@webhole_stagger/2)
        else
          @first_web_hole_dist_from_center = (@h/2) - (@tf + 3)
          @webhole_stagger = 6
        end

        #determines if the beam width is small enough to stagger the holes or not
        if @wc < 6.75
          @flange_hole_stagger = true
          # p 'Staggered'
        else
          @flange_hole_stagger = false
          # p '1-5/8" from edge'
        end

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
        pot = []
        arcs = check_for_multiples(@selected_curve, pot)
        load_parts

        arcs.each do |arc|
          create_beam(arc)
          reset_tool
        end

        model.commit_operation

        Sketchup.send_action "selectSelectionTool:"
      end

      def check_for_multiples(selection, arc_pot)
        arc = selection[0].curve
        arc.each_edge {|e| selection.remove e}
        arc_pot << arc

        if selection.any?
          check_for_multiples(selection, arc_pot)
        else
          return arc_pot
        end
      end

      def load_parts
        all_stiffplates = []
        var = @wc.to_s.split(".")
        if var.last.to_i == 0
          wc = var.first
        else
          wc = var.join('.')
        end
        stiffener_plate = "PL #{@@height_class}(#{wc}) Stiffener"

        file_path1 = Sketchup.find_support_file "ea_steel_tools/Beam Components/9_16 Hole Set.skp", "Plugins"
        file_path2 = Sketchup.find_support_file "ea_steel_tools/Beam Components/13_16 Hole Set.skp", "Plugins"
        file_path3 = Sketchup.find_support_file "ea_steel_tools/Beam Components/2½ x½_ Studs.skp", "Plugins"
        file_path4 = Sketchup.find_support_file "ea_steel_tools/Beam Components/UP.skp", "Plugins/"
        file_path5 = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{stiffener_plate}.skp", "Plugins/"


        @nine_sixteenths_hole     = @definition_list.load file_path1
        @thirteen_sixteenths_hole = @definition_list.load file_path2
        @half_inch_stud           = @definition_list.load file_path3
        @up_arrow                 = @definition_list.load file_path4
        @stiffener                = @definition_list.load file_path5
        # @shear_pl_ww10            = @definition_list.load file_path6
        # @shear_pl_ww12            = @definition_list.load file_path7
      end

      def create_beam(origin_arc)
        #Completed Methods
        set_groups
        profile = draw_beam(@@beam_data)

        # @@has_holes = false # uncomment this to toggle holes
        if @@has_holes
          web_holes    = add_web_holes    if @@web_holes
          flange_holes = add_flange_holes if @@flange_holes
          large_holes  = add_shear_holes
          guage_holes  = add_guage_holes
        end

        # Draw the New Arc with 8" Segments
        arc = draw_new_arc(origin_arc)

        # Adds in the labels for the steel
        labels = add_labels(arc)

        # Adds in the plates
        add_stiffeners(@stiff_scale, @stiff_color)
        add_shearplates(@shear_scale, @shear_color)

        align_with_curve(profile, arc) #this returns an array. The FACE that has been aligned and the ARC
        extrude_face(profile, arc)
        spread_parts(arc)
        erase_arc(arc) #Move this back to the bottom of the method
        @working_group.explode
        if @@has_holes && @@cuts_holes
          @solid_group.explode
          web_holes.each(&@explode) if @@web_holes
          flange_holes.each(&@explode) if @@flange_holes
          large_holes.each(&@explode)
        end
      end

      def set_groups
        active_model = Sketchup.active_model.active_entities.parent
        @working_group      = @entities.add_group
        @working_group_ents = @working_group.entities
        @outer_group = @working_group_ents.add_group # add plates
        @outer_group.name = 'Beam'

        @inner_group = @outer_group.entities.add_group #Add Labels
        @inner_group.name = "#{@@beam_name}"
        @steel_layer = Sketchup.active_model.layers.add " Steel"
        @inner_group.layer = @steel_layer

        @solid_group = @inner_group.entities.add_group

        b = @outer_group.bounds
        h = b.height
        w = b.width
        d = b.depth

        # Sets the outer group for the beam and should be named "Beam"
        # Sets the inside group for the beam and should be named "W--X--"
        # Sets the inner most group for the beam and should be named "Difference"
        #############################
        ##    GROUP STRUCTURE (3 groups)
        # @outer_group {
        #   --plates, studs--
        #   @inner_group {
        #     --holes, labels--
        #     @solid_group {
        #       geometry
        #     }
        #   }
        # }
      end

      def draw_beam(data)
        #set variable for the Name, Height Class, Height, Width, flange thickness, web thickness and radius for the beams
        segs = @radius
        @all_added_entities_so_far = []

        #sets the center of the radius for each beam radius
        arc_radius_points = [
          [(@w*0.5)+(@tw*0.5)+@r, 0, @tf+@r], [(@w*0.5)+(@tw*0.5)+@r, 0, (@h-@tf)-@r], [(@w*0.5)-(@tw*0.5)-@r, 0, (@h-@tf)-@r], [(@w*0.5)-(@tw*0.5)-@r, 0, @tf+@r]
        ]

        #sets the information for creating the radius @points
        normal = [0,1,0]
        zero_vec = [0,0,1]
        radius = []
        turn = 180
        #draws the arcs and rotates them into position
        arc_radius_points.each do |center|
          a = @solid_group.entities.add_arc center, zero_vec, normal, @r, 0, 90.degrees, segs
          rotate = Geom::Transformation.rotation center, [0,1,0], turn.degrees
          @solid_group.entities.transform_entities rotate, a
          radius << a
          turn += 90
        end

        #draws the wire frame outline of the beam to create a face
        @segments = []
        count = 1
        beam_outline = @points.each do |pt|
           a = @solid_group.entities.add_line pt, @points[count.to_i]
            count < 15 ? count += 1 : count = 0
            @segments << a
        end

        #erases the unncesary lines created in the outline
        @segments.each_with_index do |line, i|
          @top_edge    = line if i == 8
          @bottom_edge = line if i == 0
          @side_line   = line if i == 4

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
        radius.each do |r|
          @segments << r
        end

        @control_segment = @solid_group.entities.add_line @points[0], @points[1]

        #sets all of the connected @segments of the outline into a variable
        segs = @segments.first.all_connected

        #move the beam outline to center on the axes
        m = Geom::Transformation.new [-0.5*@w, 0, 0]
        @solid_group.entities.transform_entities m, segs

        #adds the face to the beam outline
        @face = @solid_group.entities.add_face segs
        @geometry.push @face
        @all_added_entities_so_far.push @face
        #returns the face result of the method
        return @face
      end

      def add_web_holes
        @c = Geom::Point3d.new 0,0, @h/2

        scale_web = @tw/2
        scale_hole = Geom::Transformation.scaling ORIGIN, 1, 1, scale_web
        webhole1 = @inner_group.entities.add_instance @nine_sixteenths_hole, ORIGIN
        webhole1.transform! scale_hole

        # align1 = Geom::Transformation.axes @c.position, @x_vec, @z_vec, @y_vec
        align1 = Geom::Transformation.axes @c, Z_AXIS, Y_AXIS, X_AXIS
        webhole1.transform! align1

        # align_hole(webhole1, @y_vec, 0)
        @hc >= 14 ? @h-(@tf+3) : (0.5*@h)+(0.25*@hc)

        c = webhole1.bounds.center
        adjust1 = @c - c

        adjust2 = Z_AXIS.clone
        adjust2.length = @first_web_hole_dist_from_center

        move1 = Geom::Transformation.new adjust1
        move2 = Geom::Transformation.translation adjust2
        webhole1.transform! move1
        webhole1.transform! move2

        #Here on the web by now

        webhole2 = webhole1.copy

        slide_down = Geom::Vector3d.new Z_AXIS
        slide_down.length = @webhole_stagger
        slide_down.reverse!
        move_down = Geom::Transformation.new(slide_down)
        webhole2.transform! move_down
        @web_holes.push webhole1, webhole2
        @all_added_entities_so_far.push webhole1, webhole2
        @holes.push webhole1, webhole2
        return @web_holes
      end

      def add_flange_holes
        if @tf < 0.75
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

          # determine if the holes stagger or are 1-5/8" from edge
          # set it to width
          vec2 = X_AXIS.clone
          @flange_hole_stagger ? vec2.length = ((@w/2)-(@guage_width/2)) : vec2.length = 1.6250
          # vec2.reverse!
          slide1 = Geom::Transformation.new vec2.reverse!
          flangehole1.transform! slide1
          # copy another one
          flangehole2 = flangehole1.copy
          # position the copy
          vec3 = vec2.clone
          @flange_hole_stagger ? vec3.length = @guage_width : vec3.length = @w-((1.6250)*2)
          slide2 = Geom::Transformation.new vec3
          flangehole2.transform! slide2

          # copy holes to the other flange
          flangehole3 = flangehole1.copy
          flangehole4 = flangehole2.copy

          vec4 = @bottom_edge.start.position - @top_edge.end.position
          vec4.length = @h-@tf
          send_to_flange = Geom::Transformation.new vec4
          flangehole3.transform! vec4
          flangehole4.transform! vec4

          @flange_holes.push flangehole1, flangehole2, flangehole3, flangehole4
          @all_added_entities_so_far.push flangehole1, flangehole2, flangehole3, flangehole4
          @holes.push flangehole1, flangehole2, flangehole3, flangehole4
          return @flange_holes
        else # add in 1/2" studs
          @flange_hole_stagger ? dist = @guage_width/2 : dist = (@w/2) - 1.6250
          stud1 = @outer_group.entities.add_instance @half_inch_stud, [dist, 0, @h]

          stud2 = stud1.copy
          place_2nd_stud = Geom::Transformation.translation [(@flange_hole_stagger ? -@guage_width : (@w - (1.6250*2))*-1), 0, 0]
          stud2.transform! place_2nd_stud

          cpoint = [0,0,@h/2]
          rot = Geom::Transformation.rotation cpoint, [0,1,0], 180.degrees

          stud3 = stud2.copy
          stud4 = stud1.copy
          @outer_group.entities.transform_entities rot, stud3, stud4

          @studs.push stud1, stud2, stud3, stud4
          @all_added_entities_so_far.push stud1, stud2, stud3, stud4
        end
      end

      def add_shear_holes
        scale_web = @tw/2

        # Sets the spacing for the 13/16" Web holes to be spaced from each other vertically
        if @hc > 10
          reasonable_spacing = 3
        else
          reasonable_spacing = 2.5
        end

        @number_of_sheer_holes = (((((@h - (2*@tf)) - (MIN_BIG_HOLE_DISTANCE_FROM_KZONE*2)) / 3).to_i) +1)
        @number_of_sheer_holes = 2  if @hc <= 6

        dist = Geom::Vector3d.new [0,0,1]

        y1 = 0
        z = (0.5*@h)
        x = (-0.5*@tw)

        #adds in the 13/16" Web/Connection holes
        #adds in the 13/16" Web/Connection holes
        @number_of_sheer_holes.even? ? z = (z-reasonable_spacing.to_f/2)-(((@number_of_sheer_holes-2)/2)*reasonable_spacing) : z = z-(((@number_of_sheer_holes-1)/2)*reasonable_spacing)

        for n in 0..(@number_of_sheer_holes-1) do
          point = Geom::Point3d.new x, y1, (z + (n*reasonable_spacing))
          scale_hole = Geom::Transformation.scaling point, scale_web, 1, 1
          t1 = Geom::Transformation.rotation point, [0,1,0], 270.degrees
          inst =  @inner_group.entities.add_instance @thirteen_sixteenths_hole, point
          inst.transform! t1
          inst.transform! scale_hole
          @shear_holes << inst
          @holes << inst
          @all_added_entities_so_far << inst
        end

        return @holes
      end

      def add_guage_holes
        scale_flange = @tf/2
        scale_guage_hole = Geom::Transformation.scaling ORIGIN, 1, 1, scale_flange

        guagehole1 = @inner_group.entities.add_instance @thirteen_sixteenths_hole, ORIGIN
        guagehole1.transform! scale_guage_hole

        z = Geom::Vector3d.new(0,0,1)
        vec = @side_line.line[1]
        angle = vec.angle_between z

        rot = Geom::Transformation.rotation ORIGIN, [0,1,0], angle
        guagehole1.transform! rot

        align_hole(guagehole1, vec, 0)

        # move hole to a corner of the flange
        position = @top_edge.start.position - ORIGIN

        move = Geom::Transformation.new position
        guagehole1.transform! move

        # determine if the holes stagger or are 1-5/8" from edge
        # set it to width
        vec2 = X_AXIS.clone
        vec2.length = ((@w/2)-(@guage_width/2))

        slide1 = Geom::Transformation.new vec2.reverse!
        guagehole1.transform! slide1
        # copy another one
        guagehole2 = guagehole1.copy

        # position the copy
        vec3 = vec2.clone
        vec3.length = @guage_width
        slide2 = Geom::Transformation.new vec3
        guagehole2.transform! slide2

        # copy holes to the other flange
        guagehole3 = guagehole1.copy
        guagehole4 = guagehole2.copy

        vec4 = @bottom_edge.start.position - @top_edge.end.position
        vec4.length = @h-@tf
        send_to_flange = Geom::Transformation.new vec4
        guagehole3.transform! vec4
        guagehole4.transform! vec4

        @guage_holes.push guagehole1, guagehole2, guagehole3, guagehole4
        @all_added_entities_so_far.push guagehole1, guagehole2, guagehole3, guagehole4
        @holes.push guagehole1, guagehole2, guagehole3, guagehole4
        return @guage_holes
      end

      def add_labels(arc)
        start_direction_group = @inner_group.entities.add_group
        start_ents = start_direction_group.entities

        end_direction_group = @inner_group.entities.add_group
        end_ents = end_direction_group.entities

        up_direction_group = @inner_group.entities.add_group
        up_ents = up_direction_group.entities

        beam_label_group = @inner_group.entities.add_group
        label_ents = beam_label_group.entities

        arc_start_line = arc.first_edge
        arc_end_line   = arc.last_edge

        xp1 = arc_start_line.start.position
        xp2 = arc_start_line.end.position

        yp1 = arc_end_line.start.position
        yp2 = arc_end_line.end.position

        vec1 = xp1 - xp2
        vec2 = yp2 - yp1

        beam_direction_x = vec1
        beam_direction_y = vec2
        heading_x = Geom::Vector3d.new beam_direction_x
        heading_y = Geom::Vector3d.new beam_direction_y
        heading_x[2] = 0
        heading_y[2] = 0
        angle_x = heading_x.angle_between NORTH
        angle_y = heading_y.angle_between NORTH

        direction1 = get_direction(angle_x, vec1)
        direction2 = get_direction(angle_y, vec2)

        #Gets the file paths for the direction labels
        # Direction Labels have the axis at the center of mass
        file_path1 = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{direction1}.skp", "Plugins/"
        start_direction = @definition_list.load file_path1
        file_path2 = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{direction2}.skp", "Plugins/"
        end_direction = @definition_list.load file_path2

        direction_insertion_point1 = [(@tw/2), 0, @h/2]
        direction_insertion_point2 = [(-@tw/2), 0, @h/2]

        tr = Geom::Transformation.axes direction_insertion_point1, Y_AXIS, Z_AXIS
        tr2 = Geom::Transformation.axes direction_insertion_point2, Y_AXIS.reverse, Z_AXIS

        start = true
        if start
          start_label = start_ents.add_instance start_direction, ORIGIN
          start_label.move! tr

          start_label2 = start_ents.add_instance start_direction, ORIGIN
          start_label2.move! tr2

          end_label = end_ents.add_instance end_direction, ORIGIN
          end_label.move! tr

          end_label2 = end_ents.add_instance end_direction, ORIGIN
          end_label2.move! tr2
        end

        #gets the name of the beam (Size of the beam)
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

        label_width  = comp_def.bounds.width
        label_height = comp_def.bounds.height
        label_center = comp_def.bounds.center

        tr3 = Geom::Transformation.axes [(@tw/2) + 0.0625, (@segment_length/2)-(label_width/2), (@h/2)-(label_height/2)], Y_AXIS, Z_AXIS
        tr4 = Geom::Transformation.axes [-(@tw/2) - 0.0625, (@segment_length/2)+(label_width/2), (@h/2)-(label_height/2)], Y_AXIS.reverse, Z_AXIS
        # Adds in the labels and sets them in position
        beam_label = label_ents.add_instance comp_def, ORIGIN
        beam_label.move! tr3

        beam_label2 = label_ents.add_instance comp_def, ORIGIN
        beam_label2.move! tr4

        # Adds in the Up Arrow
        file_path = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/UP.skp", "Plugins/"
        up_direction = @definition_list.load file_path

        up_label = up_ents.add_instance up_direction, ORIGIN
        up_label.move! tr

        up_label2 = up_ents.add_instance up_direction, ORIGIN
        up_label2.move! tr2


        @labels.push start_direction_group, end_direction_group, beam_label_group, up_direction_group
        @all_added_entities_so_far.push end_direction_group, beam_label_group, up_direction_group
      end

      def add_stiffeners(scale, color)
        all_stiffplates = []
        var = @wc.to_s.split(".")
        if var.last.to_i == 0
          wc = var.first
        else
          wc = var.join('.')
        end

        stiffener_plate = "PL #{@@height_class}(#{wc}) Stiffener"

        file_path_stiffener = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{stiffener_plate}.skp", "Plugins/"

        #Sets the x y and z values for placement of the plates
        x = (-0.5*@tw)-0.0625
        y = 0 #STIFF_LOCATION
        z = (0.5*@h)

        # Adds the stiffener from the component list if there already is one, otherwise it puts a new one in
        stiffener = @definition_list.load file_path_stiffener

        #sets a scale object to be called on the stiffeners based on the scale
        resize1 = Geom::Transformation.scaling [x-0.0625,y,z], 1, scale, 1

        #add 2 instances of the stiffener plate
        stiffener1 = @outer_group.entities.add_instance stiffener, ORIGIN
        stiffener2 = @outer_group.entities.add_instance stiffener, ORIGIN
        #rotates two of the stiffeners to the opposite side of the beam
        place1 = Geom::Transformation.axes [x,y,z], Y_AXIS, X_AXIS
        place2 = Geom::Transformation.axes [-x,y,z], Y_AXIS.reverse, X_AXIS.reverse
        stiffener1.move! place1
        stiffener2.move! place2
        all_stiffplates.push stiffener1, stiffener2


        all_stiffplates.each_with_index do |plate, i|
          if plate === stiffener1 || plate === stiffener2
            plate.transform! resize1
          end
        end

        all_stiffplates.each {|plate| plate.material = color }
        @stiff_plates.push stiffener1, stiffener2
        #returns the all plates array
        return all_stiffplates
      end

      def add_shearplates(scale, color)
        all_shearplates = []

        var = @wc.to_s.split(".")
        if var.last.to_i == 0
          wc = var.first
        else
          wc = var.join('.')
        end

        to_w10_shear_plate = "PL #{@@height_class}(#{wc}) to W10"
        to_w12_shear_plate = "PL #{@@height_class}(#{wc}) to W12"
        resize = Geom::Transformation.scaling 1, (1+scale.to_r.to_f), 1


        file_path_lg_shear_plate = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{to_w12_shear_plate}.skp", "Plugins/"
        small_shear_plate = "PL #{@@height_class}(#{wc}) to #{@@height_class}" #This is for all beams smaller than W10's

        if @hc < 10
          file_path_sm_shear_plate = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{small_shear_plate}.skp", "Plugins/"
        else
          file_path_sm_shear_plate = Sketchup.find_support_file "#{ROOT_FILE_PATH}/Beam Components/#{to_w10_shear_plate}.skp", "Plugins/"
        end

        #Sets the x y and z values for placement of the plates
        x = (-0.5*@tw)-0.0625
        y = 0 #STIFF_LOCATION
        z = (0.5*@h)

        if @hc >= 6
        # adds in the shear plate if the beam is longer than the minimum beam length
          shear_plate = @definition_list.load file_path_sm_shear_plate
          shear_pl1 = @outer_group.entities.add_instance shear_plate, ORIGIN
          shear_pl2 = @outer_group.entities.add_instance shear_plate, ORIGIN

          place1 = Geom::Transformation.axes [-x,y,z], Y_AXIS, X_AXIS.reverse
          place2 = Geom::Transformation.axes [x,y,z], Y_AXIS.reverse, X_AXIS

          shear_pl1.move! place1
          shear_pl2.move! place2

          # scales the plates to the correct thickness
          shear_pl1.transform! resize
          shear_pl2.transform! resize
          all_shearplates.push shear_pl1, shear_pl2
          @sh_plates.push shear_pl1, shear_pl2

          # adds in the other two shear plates if the height is higher than 12
          if @hc >= 12
            lg_shear_plate = @definition_list.load file_path_lg_shear_plate

            shear_pl3 = @outer_group.entities.add_instance lg_shear_plate, ORIGIN
            shear_pl4 = @outer_group.entities.add_instance lg_shear_plate, ORIGIN

            shear_pl3.move! place1
            shear_pl4.move! place2

            shear_pl3.transform! resize
            shear_pl4.transform! resize

            all_shearplates.push shear_pl3, shear_pl4
            @sh_plates.push shear_pl3, shear_pl4
          end
        end

        all_shearplates.each {|plate| plate.material = color}
        return all_shearplates
      end

      def get_direction(angle, vec)
        #Gets the direction based on the angles heading in relation to NORTH
        #Single Directions
        case angle
        when (0.degrees)..(30.degrees)
          hdng = 'N'
        when (60.degrees)..(120.degrees)
          if vec[0] >= 0
          hdng = 'E'
        else
          hdng = 'W'
        end
        when (150.degrees)..(180.degrees)
          hdng = 'S'
        #Compound Directions
        when (30.degrees)..(60.degrees)
          if vec[0] >= 0
            hdng = 'NE'
          else
            hdng = 'NW'
          end
        when (120.degrees)..(150.degrees)
          if vec[0] >= 0
            hdng = 'SE'
          else
            hdng = 'SW'
          end
        end

        return hdng
      end

      def draw_new_arc(selected_arc)
        # Selected Arc Data
        arc = selected_arc
        seg1 = arc.first_edge
        seg2 = arc.last_edge
        vertex1 = seg1.start
        vertex2 = seg2.end

        radius = arc.radius

        centerpoint = arc.center
        vec = arc.normal
        x_axis = arc.xaxis

        angle1 = arc.start_angle
        angle2 = arc.end_angle
        @arc_center = @solid_group.entities.add_cpoint centerpoint
        percent = angle2/360.degrees

        @drctn = check_arc_direction(selected_arc)
        # New Arc Data
        if @@roll_type == 'EASY'
          case @@placement[1]
          when 'O'
            extra = -1*(@w/2)
          when 'C'
            extra = 0
            @@radius_offset = 0
          when 'I'
            extra = (@w/2)
          end
          new_radius = radius+@@radius_offset+extra
        else #roll type is hard
          case @@placement[0]
          when 'T'
            if @drctn == 0
              offset = @h/2
              @@radius_offset *= -1
            else
              offset = -1*(@h/2)
            end
          when 'B'
            if @drctn == 0
              offset = -1*(@h/2)
              @@radius_offset *= -1
            else
              offset = @h/2
            end
          end
          new_radius = radius+@@radius_offset+offset

          if new_radius < @h*10
            UI.messagebox('WARNING: the radius you are attempting may not be achiveable by current camber rolling methods')
          end
        end

        @segment_count = get_segment_count(percent, radius, @segment_length)
        value = (@segment_length/2.0)/new_radius
        seg_angle = Math.asin(value)
        @hole_rotation_angle = seg_angle*4
        @guage_hole_rotation_angle = @hole_rotation_angle * (@segment_count/2)
        # @stiffner_rotation_angle =

        #this sets the web and flange hole counts
        @web_holes_count = ((@segment_count)/4).to_i
        @flange_hole_stagger ? @flange_hole_count = @web_holes_count : @flange_hole_count = @web_holes_count*2

        new_angle = (2.0*seg_angle*@segment_count)
        new_path = @solid_group.entities.add_arc centerpoint, x_axis, arc.normal, new_radius, angle1, new_angle, @segment_count
        new_arc = new_path[0].curve
        # p new_arc.radius

        arc = tune_new_arc(new_path, selected_arc)
        return arc
      end

      def tune_new_arc(new_arc, old_arc)
        curve = new_arc[0].curve
        old_curve = old_arc
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
        @solid_group.entities.transform_entities rot, curve

        new_dist = curve.last_edge.end.position.distance referencepoint

        if new_dist > check_dist
          reverse_rot = Geom::Transformation.rotation center, curve.normal, (angle*-1.5)
          @solid_group.entities.transform_entities reverse_rot, curve
        end

        return curve
      end

      def check_arc_direction(arc)
        direction = 0
        y_edge = arc.last_edge
        c = arc.center
        v1 = arc.xaxis
        v2 = y_edge.end.position - arc.center

        @v3 = Geom::Vector3d.linear_combination(0.500, v1, 0.500, v2)
        # @entities.add_cline(c, @v3)

        @v3.x = @v3.x.to_i
        @v3.y = @v3.y.to_i
        @v3.z = @v3.z.to_i

        if arc.normal[0] == 0 && arc.normal[1] == 0 && arc.normal[2] > 0
          direction = 1
        elsif @v3[2] >= 0
          direction = 1 # 1 means the z value of the vector is + and assumes you want the beam above or below. 1 is above and 0 is below
        end
         p direction
        return direction
      end

      def get_segment_count(percentage, radius, segment_length)
        pi = Math::PI*percentage
        seg_count = (2*pi*radius)/segment_length
        rounded_up = (seg_count.to_i)+1
        rounded_up += 1 if rounded_up.even?
        return rounded_up
      end

      def align_with_curve(face, arc)
        @face_vec = face.normal
        center      = arc.center
        start_edge  = arc.first_edge
        start_point = start_edge.start.position
        end_point   = start_edge.end.position
        start_vec = end_point - start_point

        x = (start_point[0] + end_point[0]) / 2
        y = (start_point[1] + end_point[1]) / 2
        z = (start_point[2] + end_point[2]) / 2

        pt = Geom::Point3d.new x,y,z
        @x_vec  = start_vec
        @y_vec  = pt - center
        @z_vec  = arc.normal

        if @z_vec[2] < 0
          @z_vec.reverse!
        end

        @face_up_vec = @side_line.end.position - @side_line.start.position
        if @@roll_type == 'EASY'
          place = Geom::Transformation.axes start_point, @y_vec, @x_vec, @z_vec
          @solid_group.entities.transform_entities place, @geometry
          @inner_group.entities.transform_entities place, @holes, @labels
          @outer_group.entities.transform_entities place, @studs
          @outer_group.entities.transform_entities place, @sh_plates
          @outer_group.entities.transform_entities place, @stiff_plates
          if @@placement[0] == 'T'
            tempvec = @z_vec.clone.reverse!
            tempvec.length = @h
            mvdwn = Geom::Transformation.translation tempvec
            @solid_group.entities.transform_entities mvdwn, @geometry
            @inner_group.entities.transform_entities mvdwn, @holes, @labels
            @outer_group.entities.transform_entities mvdwn, @studs
            @outer_group.entities.transform_entities mvdwn, @sh_plates
            @outer_group.entities.transform_entities mvdwn, @stiff_plates
          end
        else # Roll Type is Hard
          if @drctn == 1
            vec_set = Geom::Vector3d.new [0,0,-0.5*@h]
            mvdwn = Geom::Transformation.translation vec_set
            @solid_group.entities.transform_entities mvdwn, @geometry
            @inner_group.entities.transform_entities mvdwn, @holes, @labels
            @outer_group.entities.transform_entities mvdwn, @studs
            @outer_group.entities.transform_entities mvdwn, @sh_plates
            @outer_group.entities.transform_entities mvdwn, @stiff_plates

            place = Geom::Transformation.axes start_point, @z_vec, @x_vec, @y_vec
            @solid_group.entities.transform_entities place, @geometry
            @inner_group.entities.transform_entities place, @holes, @labels
            @outer_group.entities.transform_entities place, @studs
            @outer_group.entities.transform_entities place, @sh_plates
            @outer_group.entities.transform_entities place, @stiff_plates
          else
            cpoint  = [0,0,@h/2]
            flip = Geom::Transformation.rotation cpoint, [0,1,0], 180.degrees
            @solid_group.entities.transform_entities flip, @geometry
            @inner_group.entities.transform_entities flip, @holes, @labels
            @outer_group.entities.transform_entities flip, @studs
            @outer_group.entities.transform_entities flip, @sh_plates
            @outer_group.entities.transform_entities flip, @stiff_plates

            vec_set = Geom::Vector3d.new [0,0,-0.5*@h]
            mvdwn = Geom::Transformation.translation vec_set
            @solid_group.entities.transform_entities mvdwn, @geometry
            @inner_group.entities.transform_entities mvdwn, @holes, @labels
            @outer_group.entities.transform_entities mvdwn, @studs
            @outer_group.entities.transform_entities mvdwn, @sh_plates
            @outer_group.entities.transform_entities mvdwn, @stiff_plates

            place = Geom::Transformation.axes start_point, @z_vec, @x_vec, @y_vec
            @solid_group.entities.transform_entities place, @geometry
            @inner_group.entities.transform_entities place, @holes, @labels
            @outer_group.entities.transform_entities place, @studs
            @outer_group.entities.transform_entities place, @sh_plates
            @outer_group.entities.transform_entities place, @stiff_plates
          end
        end

        if face.normal.samedirection? start_vec
          face_loop = face.outer_loop
          r = Geom::Transformation.rotation start_point, @side_line.line[1], 180.degrees
          @working_group_ents.transform_entities r, face
        end

        position_arc(arc) #moves the arc away to be able to followme

        @hole_point = Geom::Point3d.new @face_handles[:top_inside].position
        v = @x_vec.clone

        v.length = start_edge.length / 2

        v2 = @z_vec.clone
        v2.length = @h/4

        temp_group = @entities.add_group
        corners = [@top_edge.start.position, @top_edge.end.position, @bottom_edge.start.position, @bottom_edge.end.position]

        corners.each {|point| temp_group.entities.add_cpoint point }

        @start_direction_vector = face.normal
        @top_edge_vector = @top_edge.start.position - @top_edge.end.position
        @face_up_vec = @side_line.end.position - @side_line.start.position
        temp_group.entities.clear!
        temp_group.erase!

        return face, arc
      end

      def position_arc(path)
        vec = path.normal
        if vec[2] < 0
          vec.reverse!
        end
        vec.length = @h*2
        slide_out = Geom::Transformation.new(vec)
        @inner_group.entities.transform_entities slide_out, path
      end

      def reset_tool
        @working_group = nil
        @outer_group   = nil
        @inner_group   = nil
        @solid_group   = nil

        @geometry     = []
        @holes        = []
        @web_holes    = []
        @flange_holes = []
        @guage_holes  = []
        @studs        = []
        @shear_holes  = []
        @labels       = []
        @sh_plates    = []
        @stiff_plates = []

        @arc  = 0 #This is the new arc
        @face = 0 # This is the profile
      end

      def extrude_face(face, path)
        face.followme(path.edges)
      end

      def spread_parts(arc)
        @guage_holes.each do |hole|
          slide(hole, arc, BIG_HOLES_LOCATION)
          spread(hole, arc, @guage_hole_rotation_angle, 0, 1)
        end
        @shear_holes.each do |hole|
          slide(hole, arc, BIG_HOLES_LOCATION)
          spread(hole, arc, @guage_hole_rotation_angle, 0, 1)
        end
        # @flange_holes.each do |hole|
        #   slide(hole, arc, BIG_HOLES_LOCATION)
        #   spread(hole, arc, @guage_hole_rotation_angle, 0, 1)
        # end

      end

      def slide(part, arc, distance)
        slide_vec = arc.first_edge.end.position - arc.first_edge.start.position
        slide_vec.length = distance
        slide     = Geom::Transformation.translation slide_vec
        part.transform! slide
      end

      def spread(part, arc, angle, number_of_copies, max)
        if number_of_copies == max
          return
        else
          center = arc.center
          pivot = arc.normal
          x_vec = arc.xaxis

          rot = Geom::Transformation.rotation center, pivot, angle
          copy = part.copy
          copy.transform! rot
          number_of_copies += 1
          spread(copy, arc, angle, number_of_copies, max)
        end
      end

      # def copy_along_curve(hole, arc, angle, number_of_copies, max, loot)
      #   if number_of_copies == max
      #     return loot
      #   else
      #     rot = Geom::Transformation.rotation arc.center, arc.normal, angle
      #     new_hole = hole.copy
      #     loot << new_hole
      #     @all_added_entities_so_far.push new_hole
      #     new_hole.transform! rot
      #     number_of_copies += 1
      #     copy_along_curve(new_hole, arc, angle, number_of_copies, max, loot)
      #   end
      # end

      def erase_arc(arc)
         arc.edges.each(&@erase)
      end

################################
# METHODS CURRENTLY NOT IN USE
################################

      def move_along_curve(hole, arc, angle)
        rot = Geom::Transformation.rotation arc.center, arc.normal, angle
        hole.transform! rot
      end

      def spread_web_holes(holes, path)
        bottom_row_holes_count = @web_holes_count
        top_row_web_holes = @web_holes_count

        if @segment_count % 4 == 1 || @segment_count % 4 == 2
          bottom_row_holes_count -= 1
        end

        # Need to make the inside reference the right curve information

        move_along_curve(holes[1], path, @hole_rotation_angle) #bottom row holes rotated along the arc to the right 8" segment
        copy_along_curve(holes[0], path, @hole_rotation_angle*2, 0, top_row_web_holes, holes ) #top row holes
        copy_along_curve(holes[1], path, @hole_rotation_angle*2, 0, bottom_row_holes_count, holes ) #bottom row holes
      end

      def spread_flange_holes(holes, path) # The holes need to be an array of the 4 flange holes
        # set it 4" up the arc
        # vec1 = Y_AXIS.clone # THIS NEEDS TO BE THE START VEC OF THE PATH
        # vec1.reverse!
        # vec1.length = @segment_length/2
        # slide_up = Geom::Transformation.new(vec1)

        # flangehole1.transform! slide_up

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

        # array all holes along the arc
        copy_along_curve(holes[0], path, hole_rotation, 0, top_inside_holes, holes ) #top inside hole
        copy_along_curve(holes[1], path, hole_rotation, 0, top_outside_holes, holes ) #top outside hole
        copy_along_curve(holes[2], path, hole_rotation, 0, bottom_inside_holes, holes ) #bottom inside hole
        copy_along_curve(holes[3], path, hole_rotation, 0, bottom_outside_holes, holes ) #bottom outside hole
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