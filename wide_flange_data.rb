module EA_Extensions623
  module EASteelTools

    class FlangeTool
      include BeamLibrary
      include Control

      # This is the standard Ruby initialize method that is called when you create
      # a new object.
      def initialize(data)
        #returns the avtive model material list
        @model = Sketchup.active_model
        @entities = @model.active_entities
        @selection = @model.selection
        @definition_list = @model.definitions
        @materials = @model.materials
        @material_names = @materials.map {|color| color.name}

        view = @model.active_view
        @ip1 = nil
        @ip2 = nil
        @xdown = 0
        @ydown = 0

        @@beam_name         = data[:name]               #String 'W(height_class)X(weight_per_foot)'
        @@height_class      = data[:height_class]       #String 'W(number)'
        @@beam_data         = data[:data]               #Hash   {:d=>4.16, :bf=>4.06, :tf=>0.345, :tw=>0.28, :r=>0.2519685039370079, :width_class=>4}"
        @@placement         = data[:placement]          #String 'TOP' or 'BOTTOM'
        @@has_holes         = data[:has_holes]          #Boolean
        @@hole_spacing      = data[:stagger]            #Integer 16 or 24
        @@cuts_holes        = data[:cuts_holes]         #Boolean
        @@has_stiffeners    = data[:stiffeners]         #Boolean
        @@has_shearplates   = data[:shearplates]        #Boolean
        @@stiff_thickness   = data[:stiff_thickness]    #String '1/4' or '3/8' or '1/2'
        @@shearpl_thickness = data[:shearpl_thickness]  #String '1/4' or '3/8' or '1/2'
        @@force_studs       = data[:force_studs]
        @@flange_type       = data[:flange_type]

        values = data[:data]
        @hc    = data[:height_class].split('W').last.to_i #this gets just the number in the height class
        @h     = values[:d].to_f
        @w     = values[:bf].to_f
        @tf    = values[:tf].to_f
        @tw    = values[:tw].to_f
        @wc    = values[:width_class].to_f
        @r     = values[:r].to_f
        @number_of_sheer_holes = (((((@h - ((2*@tf) + (@r*2))) - (MIN_BIG_HOLE_DISTANCE_FROM_KZONE*2)) / 3).to_i) +1)


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

        @x_red = @model.axes.axes[0]
        @y_green = @model.axes.axes[1]
        @z_blue = @model.axes.axes[2]

        if @@flange_type == FLANGE_TYPE_COL
          @is_column = true
        else
          @is_column = false
        end

        @nine_sixteenths_holes = []
        check_for_preselect(@selection, @model.active_view)
        self.reset(view)
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


              # Create the member in Sketchup
              self.create_geometry(pt1, pt2, view)
              self.reset(view)
              # Sketchup.send_action "selectSelectionTool:" #Mabes Babes
            end
          end
        end
        if @bad_selections.any?
          UI.beep
          @model.selection.remove @bad_selections
          # @bad_selections.each {|sel| @model.selection.add sel}
          p "There are #{@bad_selections.count} groups or otherwise"
        end
      end

      def onSetCursor
        cursor_path = Sketchup.find_support_file ROOT_FILE_PATH+"/icons/wfs_cursor(2).png", "Plugins/"
        cursor_id = UI.create_cursor(cursor_path, 0, 0)
        UI.set_cursor(cursor_id.to_i)
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

      def draw_control_line(pts, view)
        view.line_width = 2
        view.line_stipple = "."
        view.drawing_color = "black"
        view.draw(GL_LINES, pts)
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

      # The onLButtonDOwn method is called when the user presses the left mouse button.
      def onLButtonDown(flags, x, y, view)
        # When the user clicks the first time, we switch to getting the
        # second point.  When they click a second time we create the Beam
        if @ip1.valid?
          if @@placement == "TOP"
            point = Geom::Point3d.new(0, 0, -@h)
            @mv_dwn = Geom::Transformation.new(point)
          elsif @@placement == "MID"
            point = Geom::Point3d.new(0, 0, @h * -0.5)
            @mv_dwn = Geom::Transformation.new(point)
          end
        end

        if( @state == 0 )
          @ip1.pick view, x, y
          if @ip1.valid?
            @state = 1

            @ip1points = [
              a1 = Geom::Point3d.new((-0.5*@w), 0, 0),
              b1 = Geom::Point3d.new((0.5*@w), 0, 0),
              c1 = Geom::Point3d.new((0.5*@w), 0, @tf),
              d1 = Geom::Point3d.new(((0.5*@tw)+@r), 0, @tf),
              e1 = Geom::Point3d.new(((0.5*@tw)), 0, ((@tf+@r))),
              f1 = Geom::Point3d.new(((0.5*@tw)), 0, ((@h-@tf)-@r)),
              g1 = Geom::Point3d.new(((0.5*@tw)+@r), 0, (@h-@tf)),
              h1 = Geom::Point3d.new((0.5*@w), 0,(@h-@tf)),
              i1 = Geom::Point3d.new((0.5*@w), 0, @h),
              j1 = Geom::Point3d.new((-0.5*@w), 0, @h),
              k1 = Geom::Point3d.new((-0.5*@w), 0, (@h-@tf)),
              l1 = Geom::Point3d.new(((-0.5*@tw)-@r), 0, (@h-@tf)),
              m1 = Geom::Point3d.new(((-0.5*@tw)), 0, ((@h-@tf)-@r)),
              n1 = Geom::Point3d.new(((-0.5*@tw)), 0, (@tf+@r)),
              o1 = Geom::Point3d.new(((-0.5*@tw)-@r), 0, @tf ),
              p1 = Geom::Point3d.new((-0.5*@w), 0, @tf)
            ]

            @ghostpoints = @ip1points.map{|e| e.clone}

            Sketchup::set_status_text ("Select second end"), SB_PROMPT
            @xdown = x
            @ydown = y

            if @mv_dwn
              @ip1points.each{|p| p.transform!(@mv_dwn)}
              @ghostpoints.each{|p| p.transform!(@mv_dwn)}
            end
          end
        else
          # create the line on the second click
          if( @ip2.valid? )
            @@vec = @ip2.position - @ip1.position
            @@pt1 = @ip1.position
            @@pt2 = @ip2.position
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
          self.create_geometry(@ip1.position, @ip2.position,view)
          self.reset(view)
        end
      end

      # The activate method is called by SketchUp when the tool is first selected.
      # it is a good place to put most of your initialization
      def activate
        clear_groups # clears the groups so new ones can be made on the next instance
        @nine_sixteenths_holes = []

        # The Sketchup::InputPoint class is used to get 3D points from screen
        # positions.  It uses the SketchUp inferencing code.
        # In this tool, we will have two points for the end points of the beam.
        @ip1 = Sketchup::InputPoint.new
        @ip2 = Sketchup::InputPoint.new
        @ip = Sketchup::InputPoint.new
        @drawn = false

        @@pt1        = nil
        @@pt2        = nil
        @@vec        = nil

        @left_lock = nil
        @right_lock = nil
        @up_lock = nil

        # This sets the label for the VCB
        Sketchup::set_status_text ("Length"), SB_VCB_LABEL
      end


      def draw_beam(beam, length)
          # temporarily groups the face so other geometry wont interere with operations
          beam_ents = @solid_group.entities

          #set variable for the Name, Height Class, Height, Width, flange thickness, web thickness and radius for the beams
          segs = RADIUS
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
            if i == 3 || i == 5 || i == 11 || i == 13
              @segments.slice(i)
              line.erase!
            end
          end

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

          if @is_column
            length = length - STANDARD_BASE_PLATE_THICKNESS
          end

          face.pushpull length

          #Soften the radius lines
          beam_ents.grep(Sketchup::Edge).each_with_index do |e, i|
            if e.length == length && !e.soft?
              @radius.each do |arc|
                a = arc[0].start.position
                b = arc[2].end.position
                if e.start.position == a || e.start.position == b
                  e.soft = true
                  e.smooth = true
                end
              end
            end
          end

          #returns the face result of the method
          return @solid_group
      end

      def add_9_16_web_holes(length)
        begin
          #this code makes so the holes cannot be less than 8" from the beams edge
          #and if the beam is smaller than 26" then the holes do not stagger
          if length >= MINIMUM_BEAM_LENGTH
            if (length % @@hole_spacing) >= NO_HOLE_ZONE*2
              fhpX = (length % @@hole_spacing) / 2
              shpX = ((length % @@hole_spacing) / 2) + @@hole_spacing
            else
              fbl = length - (length % @@hole_spacing)
              fhpX = ((fbl % @@hole_spacing) / 2) + ((length % @@hole_spacing) / 2) + @@hole_spacing/2
              shpX = ((fbl % @@hole_spacing) / 2) + ((length % @@hole_spacing) / 2) + 1.5*@@hole_spacing
            end
          else
            fhpX = length / 2
            shpX = length / 2
          end

          # Load the 9/16" holes from the collection
          file_path1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{NN_SXTNTHS_HOLE}", "Plugins/"
          nine_sixteenths_hole = @definition_list.load file_path1

          #load the 1/2" studs ready for placing
          file_path_stud = Sketchup.find_support_file "#{COMPONENT_PATH}/#{HLF_INCH_STD}", "Plugins/"
          half_inch_stud = @definition_list.load file_path_stud if @@force_studs

          @@force_studs ? element = half_inch_stud : element = nine_sixteenths_hole

          count = 0

          #Setst the scale depth for the web and the flange
          scale_web = @tw/2

          while fhpX < length
            tran1 = Geom::Transformation.scaling [fhpX, (0.5*@tw), (0.5*@h)+(0.25*@hc)], 1, scale_web, 1

            if count.even? && @tw <= 0.75
              #Adds in the top row of web holes
              if @hc >= 14
                topz = @h-(@tf+3)
                bottz = @h-(@tf+9)
              elsif @hc <= 6
                topz = (0.5*@h)
                bottz = topz
              else
                topz = (0.5*@h)+(0.25*@hc)
                bottz = (0.5*@h)-(0.25*@hc)
              end

              placement1 = [fhpX, (0.5*@tw), topz]
              inst = @inner_group.entities.add_instance element, placement1
              t = Geom::Transformation.rotation placement1, [1,0,0], 270.degrees
              inst.transform! t
              inst.transform! tran1 unless @@force_studs
              @@force_studs ? @all_studs << inst : @nine_sixteenths_holes << inst

              break if shpX > length

              #Adds in the bottom row of web holes
              placement2 = [shpX, (0.5*@tw), bottz]
              inst = @inner_group.entities.add_instance element, placement2
              t = Geom::Transformation.rotation placement2, [1,0,0], 270.degrees
              inst.transform! t
              inst.transform! tran1 unless @@force_studs

              @@force_studs ? @all_studs << inst : @nine_sixteenths_holes << inst
            end
            #this keeps track of where on the beam the holes shouldbe placed
            fhpX += @@hole_spacing
            shpX += @@hole_spacing
            count += 1
          end

        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading 9/16 holes into the beam")
        end
      end

      def add_9_16_flange_holes(length)
        begin
          #adds in the top flange 9/16" holes if the flange thickness is less than 3/4"
          #and 1/2" studs if the flange is thicker than 3/4"
          if @w < 6.75
            stagger = true
            y = 0.5*@guage_width
            hole_spacing_update = @@hole_spacing ################### here is a change i made on 4/21/2016 to force a 24" spacing when flange holes not staggered ###################
          else
            y = (0.5*@w) - 1.625
            hole_spacing_update = 24 ################### here is a change i made on 4/21/2016 to force a 24" spacing when flange holes not staggered ###################
          end
          #this code makes so the holes cannot be less than 8" from the beams edge
          #and if the beam is smaller than 26" then the holes do not stagger
          if length >= MINIMUM_BEAM_LENGTH
            if (length % hole_spacing_update) >= NO_HOLE_ZONE*2
              fhpX = (length % hole_spacing_update) / 2
              shpX = ((length % hole_spacing_update) / 2) + hole_spacing_update
            else
              fbl = length - (length % hole_spacing_update)
              fhpX = ((fbl % hole_spacing_update) / 2) + ((length % hole_spacing_update) / 2) + hole_spacing_update/2
              shpX = ((fbl % hole_spacing_update) / 2) + ((length % hole_spacing_update) / 2) + 1.5*hole_spacing_update
            end
          else
            fhpX = length / 2
            shpX = length / 2
          end

          # Load the 9/16" holes from the collection
          file_path1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{NN_SXTNTHS_HOLE}", "Plugins/"
          nine_sixteenths_hole = @definition_list.load file_path1


          #initialize some variables
          @all_studs = []
          count = 0

          #Setst the scale depth for the web and the flange
          scale_flange = @tf/2

          while fhpX < length
            tran2 = Geom::Transformation.scaling [fhpX, 0.5*@guage_width, @h], 1, 1, scale_flange
            tran3 = Geom::Transformation.scaling [fhpX, 0.5*@guage_width, @tf], 1, 1, scale_flange

            # inserts 9/16" holes in the flanges if the flange thickness is less than 3/4"
            # and inserts 1/2" studs on the top flange if it is thicker than 3/4"
            if @tf <= 0.75 && @@force_studs == false
              holes = [
                #adds the first row of 9/16" holes in the top flange
                (inst1 = @inner_group.entities.add_instance nine_sixteenths_hole, [fhpX, y, @h] unless stagger && count.odd?),
                #adds the first row of holes in the bottom flange
                (inst3 = @inner_group.entities.add_instance nine_sixteenths_hole, [fhpX, y, @tf] unless stagger && count.odd?),
                #adds the second row of 9/26" holes in the top flange
                (inst2 = @inner_group.entities.add_instance nine_sixteenths_hole, [fhpX, -y, @h] unless stagger && count.even?),
                #adds the second row of holes in the bottom flange
                (inst4 = @inner_group.entities.add_instance nine_sixteenths_hole, [fhpX, -y, @tf] unless stagger && count.even?)
              ]

              #Staggers the holes if the beam is narrower than 6-3/4"
              holes.compact! if stagger
              holes.each_with_index do |hole, i|
                i.even? ? (hole.transform! tran2) : (hole.transform! tran3)
                @nine_sixteenths_holes.push hole
              end
            else # Adds the 1/2" Studs where holes could go if the flange was less than 3/4"
              #load the 1/2" studs ready for placing
              file_path_stud = Sketchup.find_support_file "#{COMPONENT_PATH}/#{HLF_INCH_STD}", "Plugins/"
              half_inch_stud = @definition_list.load file_path_stud
              #puts studs on the beam if the flange thickness is thicker than 3/4"

              inst1 = @inner_group.entities.add_instance half_inch_stud, [fhpX, y, @h] unless stagger && count.odd?
              inst2 = @inner_group.entities.add_instance half_inch_stud, [fhpX, -y, @h] unless stagger && count.even?

              @all_studs << inst1
              @all_studs << inst2
            end

            #this keeps track of where on the beam the holes shouldbe placed
            fhpX += hole_spacing_update
            shpX += hole_spacing_update
            count += 1
          end

          @all_studs.compact! if not @all_studs.empty?
          if @@force_studs || @@flange_type == 'Column'
            @all_studs.each do |stud|
              copy = stud.copy
              tran = Geom::Transformation.rotation [0,0,@h/2], X_AXIS, 180.degrees
              copy.transform! tran
            end
          end

        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading 9/16 holes into the beam")
        end
      end

      ##########################################
      ##########################################
      def draw_parametric_plate(pts)
        begin
          temp_faces = []
          temp_edges = []
          temp_groups = []
          arcs = []

          @baseplate_group = @outer_group.entities.add_group
          @baseplate_group.name = 'Bottom Plate'
          face = @baseplate_group.entities.add_face pts
          rotface = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 90.degrees)
          @outer_group.entities.transform_entities(rotface, @baseplate_group)
          vec = Geom::Point3d.new(0, 0, @h/2) - @baseplate_group.bounds.center
          center = Geom::Transformation.translation(vec)
          @outer_group.entities.transform_entities(center, @baseplate_group)
          align = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, @h/2), Y_AXIS, 90.degrees)
          @outer_group.entities.transform_entities(align, @baseplate_group)
          vector = Geom::Vector3d.new(STANDARD_BASE_PLATE_THICKNESS, 0, 0)
          sld = Geom::Transformation.translation(vector)
          @outer_group.entities.transform_entities(sld, @baseplate_group)

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

          color_by_thickness(@baseplate_group, 0.875)

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

          [big_hole, bh2, bh3, bh4].each {|h| set_layer(h, HOLES_LAYER)}
          # classify_as_plate(@baseplate_group)

          return @baseplate_group
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the base plate")
        end
      end
      ##########################################
      ##########################################

      def add_13_16_holes(length)
        begin
          #this code makes so the holes cannot be less than 8" from the beams edge
          #and if the beam is smaller than 26" then the holes do not stagger
          if length >= MINIMUM_BEAM_LENGTH
            if (length % @@hole_spacing) >= NO_HOLE_ZONE*2
              fhpX = (length % @@hole_spacing) / 2
              shpX = ((length % @@hole_spacing) / 2) + @@hole_spacing
            else
              fbl = length - (length % @@hole_spacing)
              fhpX = ((fbl % @@hole_spacing) / 2) + ((length % @@hole_spacing) / 2) + @@hole_spacing/2
              shpX = ((fbl % @@hole_spacing) / 2) + ((length % @@hole_spacing) / 2) + 1.5*@@hole_spacing
            end
          else
            fhpX = length / 2
            shpX = length / 2
          end

          # Load the 13/16" holes from the collection
          file_path2 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{THRTN_SXTNTHS_HOLE}", "Plugins/"
          thirteen_sixteenths_hole = @definition_list.load file_path2

          #initialize some variables
          all_holes = []
          count = 0

          #Setst the scale depth for the web and the flange
          scale_web = @tw/2
          scale_flange = @tf/2

          while fhpX < length
            tran1 = Geom::Transformation.scaling [fhpX, (0.5*@tw), (0.5*@h)+(0.25*@hc)], 1, scale_web, 1
            tran2 = Geom::Transformation.scaling [fhpX, 0.5*@guage_width, @h], 1, 1, scale_flange
            tran3 = Geom::Transformation.scaling [fhpX, 0.5*@guage_width, @tf], 1, 1, scale_flange

            #insert 4 13/16" holes in the top and bottom flange close to each end of the beam
            if count == 0 || shpX > length
              count == 0 ? x = BIG_HOLES_LOCATION : x = (length - BIG_HOLES_LOCATION)
              holes = [
                #adds in 13/16" holes in the top flange
                (inst1 = @inner_group.entities.add_instance thirteen_sixteenths_hole, [x, (0.5*@guage_width), @h]),
                #adds a 13/16" Hole in the bottom flange
                (inst3 = @inner_group.entities.add_instance thirteen_sixteenths_hole, [x, (0.5*@guage_width), @tf]),
                #adds in 13/16" holes in the top flange
                (inst2 = @inner_group.entities.add_instance thirteen_sixteenths_hole, [x, (-0.5*@guage_width), @h]),
                #adds a 13/16" Hole in the bottom flange
                (inst4 = @inner_group.entities.add_instance thirteen_sixteenths_hole, [x, (-0.5*@guage_width), @tf])
              ]

              #Scales each of the holes to the flange thickness
              holes.each_with_index do |hole, i|
                i.even? ? (hole.transform! tran2) : (hole.transform! tran3)
              end

              all_holes.push inst1, inst2, inst3, inst4
            end

            #insert 3 13/16" holes in the web at each end of the beam
            if count == 0 || shpX > length
              count == 0 ? x = BIG_HOLES_LOCATION : x = (length - BIG_HOLES_LOCATION)
              y1 = (0.5*@tw)
              z = (0.5*@h)

              # Sets the spacing for the 13/16" Web holes to be spaced from each other vertically

              # if @hc >= 10
              #   SHEAR_HOLE_SPACING = 3
              # elsif @hc < 10
              #   @number_of_sheer_holes = 2  if @hc <= 6
              #   SHEAR_HOLE_SPACING = 2.5
              # end

              #adds in the 13/16" Web/Connection holes
              @number_of_sheer_holes.even? ? z = (z-SHEAR_HOLE_SPACING.to_f/2)-(((@number_of_sheer_holes-2)/2)*SHEAR_HOLE_SPACING) : z = z-(((@number_of_sheer_holes-1)/2)*SHEAR_HOLE_SPACING)

              for n in 0..(@number_of_sheer_holes-1) do
                t1 = Geom::Transformation.rotation [x,y1,z + (n*SHEAR_HOLE_SPACING)], [1,0,0], 270.degrees
                inst =  @inner_group.entities.add_instance thirteen_sixteenths_hole, [x, y1, z + (n*SHEAR_HOLE_SPACING)]
                inst.transform! t1
                inst.transform! tran1
                all_holes << inst
              end
            end

            break if shpX > length

            #this keeps track of where on the beam the holes shouldbe placed
            fhpX += @@hole_spacing
            shpX += @@hole_spacing
            count += 1
          end

          all_holes.each{|h| set_layer(h, HOLES_LAYER)}
          return all_holes
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading the 13/16\" holes")
        end
      end

      def add_labels_beam(vec, length)
        begin
          all_labels = []

          start_direction_group = @inner_group.entities.add_group
          start_ents = start_direction_group.entities
          end_direction_group = @inner_group.entities.add_group
          end_ents = end_direction_group.entities
          up_direction_group = @inner_group.entities.add_group
          up_ents = up_direction_group.entities
          beam_label_group = @inner_group.entities.add_group
          label_ents = beam_label_group.entities

          beam_direction = vec
          heading = Geom::Vector3d.new beam_direction
          heading[2] = 0
          angle = heading.angle_between NORTH

          #Sets the direction labels according to the beam vec
          #Single Directions
          direction_labels = get_direction_labels(angle, vec)

          #Gets the file paths for the labels
          file_path1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{direction_labels[0]}", "Plugins/"
          end_direction = @definition_list.load file_path1
          file_path2 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{direction_labels[1]}", "Plugins/"
          start_direction = @definition_list.load file_path2

          for n in 1..2
            n == 1 ? y = -(0.5*@tw) : y = (0.5*@tw)

            placement1 = [LABELX, y, 0.5*@h]
            placement2 = [length-LABELX, y, 0.5*@h]
            r1 = Geom::Transformation.rotation placement1, [1,0,0], 90.degrees
            r2 = Geom::Transformation.rotation placement2, [1,0,0], 90.degrees
            r3 = Geom::Transformation.rotation placement1, [0,0,1], 180.degrees
            r4 = Geom::Transformation.rotation placement2, [0,0,1], 180.degrees

            inst = start_ents.add_instance start_direction, placement1
            start_ents.transform_entities r1, inst
            start_ents.transform_entities r3, inst if n == 2

            inst = end_ents.add_instance end_direction, placement2
            end_ents.transform_entities r2, inst
            end_ents.transform_entities r4, inst if n == 2
          end

          for n in 1..2
            n == 1 ? z = @h : z = 0

            placement1 = [LABELX, 0, z]
            placement2 = [length-LABELX, 0, z]

            r1 = Geom::Transformation.rotation placement1, [1,0,0], 180.degrees
            r2 = Geom::Transformation.rotation placement2, [1,0,0], 180.degrees
            #add the first direction marker to the start of the beam
            inst = start_ents.add_instance start_direction, placement1
            start_ents.transform_entities r1, inst if n == 2

            inst = end_ents.add_instance end_direction, placement2
            end_ents.transform_entities r2, inst if n == 2
          end

          #Adds in the label of the name of the beam at the center on both sides
          component_names = []
          @definition_list.map {|comp| component_names << comp.name}
          if component_names.include? @@beam_name
            comp_def = @definition_list["#{@@beam_name}"]
          else
            comp_def = @definition_list.add "#{@@beam_name}"
            comp_def.description = "The #{@@beam_name} label"
            ents = comp_def.entities
            _3d_text = ents.add_3d_text("#{@@beam_name}", TextAlignCenter, "#{STEEL_FONT}", false, false, 3.0, 3.0, 0.0, false, 0.0)
            # p "loaded CamBam_Stick_7: #{_3d_text}"
            save_path = Sketchup.find_support_file "Components", ""
            comp_def.save_as(save_path + "/#{@@beam_name}.skp")
          end

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{UP_DRCTN}", "Plugins/"
          up_direction = @definition_list.load file_path

          # Adds in the UP directioal label on both sides of the web
          # also adds in the beam name label if it already exists in the component
          for n in 1..2
            label_width = comp_def.bounds.width
            x = (0.5*length)
            y = (0.5*@tw)+0.01
            z = (0.5*@h)
            if n == 1
              loc, loc1 = [x-(0.5*label_width), y, z-1.5], [x-(0.75*label_width), y, z]
            else
              loc, loc1 = [x-(0.5*label_width), -y, z-1.5], [x-(0.75*label_width), -y, z]
            end

            t1 = Geom::Transformation.rotation loc, [1,0,0], 90.degrees
            t2 = Geom::Transformation.rotation [x, y, z], [0,0,1], 180.degrees
            t3 = Geom::Transformation.rotation loc1, [0,0,1], 180.degrees
            t4 = Geom::Transformation.rotation loc1, [1,0,0], 90.degrees
            beam_label = label_ents.add_instance comp_def, loc
            up_dir = up_ents.add_instance up_direction, loc1
            label_ents.transform_entities t1, beam_label
            up_ents.transform_entities t4, up_dir
            if n == 1
              label_ents.transform_entities t2, beam_label
              up_ents.transform_entities t3, up_dir
            end
          end

          #rotates the up arrow group to always be pointing up

          if vec[2] != 0
            z = vec[2]
            vec1 = Geom::Vector3d.new [vec[0], vec[1], 0]
            a = vec1.angle_between vec

            z > 0 ? angle = a : angle = a*-1

            t4 = Geom::Transformation.rotation loc1, [0,1,0], angle
            @inner_group.entities.transform_entities t4, up_direction_group
            # UI.messagebox("#{(angle*180)/Math::PI} degrees is what the angle is rotating")
          end

          all_labels.push up_direction_group, start_direction_group, end_direction_group, beam_label_group
          return all_labels
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading the labels on the beam")
        end
      end

      def add_labels_column(vec, length)
        begin
          all_labels = []
          component_names = []
          @definition_list.map {|comp| component_names << comp.name}

          orientation1_group = @inner_group.entities.add_group
          orient1_ents = orientation1_group.entities
          orientation2_group = @inner_group.entities.add_group
          orient2_ents = orientation2_group.entities
          up_direction_group = @inner_group.entities.add_group
          up_ents = up_direction_group.entities
          beam_label_group = @inner_group.entities.add_group
          label_ents = beam_label_group.entities

          #Gets the file paths for the labels
          f1 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{NORTH_LABEL}", "Plugins/"
          f2 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{SOUTH_LABEL}", "Plugins/"
          f3 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{EAST_LABEL}", "Plugins/"
          f4 = Sketchup.find_support_file "#{COMPONENT_PATH}/#{WEST_LABEL}", "Plugins/"
          north = @definition_list.load f1
          south = @definition_list.load f2
          east = @definition_list.load f3
          west = @definition_list.load f4

          #places the directional labels, one
          x = LABEL_HEIGHT_FROM_FLOOR
          y = @tw
          z = @h

          for n in 1..2
            loc1 = [x, y/2, z/2] #north
            loc2 = [x, -0.5*y, z/2] #south
            loc3 = [x, 0, 0] #east
            loc4 = [x, 0, z] #west

            n == 1 ? group = orient1_ents : group = orient2_ents

            rot = Geom::Transformation.rotation loc1, [1,0,0], 270.degrees
            rot1 = Geom::Transformation.rotation loc1, [0,0,1], 270.degrees
            combo1 = rot * rot1
            rot2 = Geom::Transformation.rotation loc2, [0,0,1], 270.degrees
            rot3 = Geom::Transformation.rotation loc2, [0,1,0], 90.degrees
            combo2 = rot2 * rot3
            rot5 = Geom::Transformation.rotation loc3, [1,0,0], 180.degrees
            rot4 = Geom::Transformation.rotation loc3, [0,0,1], 90.degrees
            combo3 = rot4 * rot5
            rot6 = Geom::Transformation.rotation loc3, [0,0,1], 270.degrees

            n == 1 ? (a1, a2, a3, a4 = north, south, west, east) : (a1, a2 ,a3 ,a4 = east, west, north, south)

            d1 = group.add_instance a4, loc1 #North & West
            d2 = group.add_instance a3, loc2 # South & East
            d3 = group.add_instance a2, loc3 # East & North
            d4 = group.add_instance a1, loc4 # West & South

            @inner_group.entities.transform_entities combo1, d1
            @inner_group.entities.transform_entities combo2, d2
            @inner_group.entities.transform_entities combo3, d3
            @inner_group.entities.transform_entities rot6, d4

            x += 5
          end

          #Adds in the label of the name of the beam at the center on both sides
          if component_names.include? @@beam_name
            comp_def = @definition_list["#{@@beam_name}"]
          else
            comp_def = @definition_list.add "#{@@beam_name}"
            comp_def.description = "The #{@@beam_name} label"
            ents = comp_def.entities
            _3d_text = ents.add_3d_text("#{@@beam_name}", TextAlignCenter, STEEL_FONT, false, false, 3.0, 3.0, 0.0, false, 0.0)
            save_path = Sketchup.find_support_file "Components", ""
            comp_def.save_as(save_path + "/#{@@beam_name}.skp")
          end

          file_path = Sketchup.find_support_file "#{COMPONENT_PATH}/#{UP_DRCTN}", "Plugins/"
          up_direction = @definition_list.load file_path

          # Adds in the UP directioal label on both sides of the web
          # also adds in the beam name label if it already exists in the component
          for n in 1..2
            label_width = comp_def.bounds.width
            x = (length/2)
            y = (0.5*@tw)+0.01
            z = (0.5*@h)
            if n == 1
              loc, loc1 = [x-(0.5*label_width), y, z-1.5], [length-16, y, z]
            else
              loc, loc1 = [x-(0.5*label_width), -y, z-1.5], [length-16, -y, z]
            end

            t1 = Geom::Transformation.rotation loc, [1,0,0], 90.degrees
            t2 = Geom::Transformation.rotation [x, y, z], [0,0,1], 180.degrees
            t3 = Geom::Transformation.rotation loc1, [0,0,1], 180.degrees
            beam_label = label_ents.add_instance comp_def, loc
            up_dir = up_ents.add_instance up_direction, loc1
            label_ents.transform_entities t1, beam_label
            if n == 1
              label_ents.transform_entities t2, beam_label
              up_ents.transform_entities t3, up_dir

              rott = Geom::Transformation.rotation loc1, [1,0,0], 270.degrees
              up_ents.transform_entities rott, up_dir
            else
              rott = Geom::Transformation.rotation loc1, [1,0,0], 90.degrees
              up_ents.transform_entities rott, up_dir
            end
          end

          rot_up = Geom::Transformation.rotation loc1, [0,1,0], 90.degrees
          up_ents.transform_entities rot_up, up_direction_group

          rot_direct = 360 - Z_AXIS.angle_between(vec).radians

          # p rot_direct

          # p rot_direct.degrees
          rot_vert = Geom::Transformation.rotation(up_direction_group.bounds.center, Y_AXIS, rot_direct.degrees)
          up_ents.transform_entities(rot_vert, up_direction_group)

          all_labels.push up_direction_group, orientation1_group, orientation2_group, beam_label_group

          return all_labels
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading the labels in the column")
        end
      end

      # Sets the appropriate plates in the beam
      # Shear Plates and stiffener plates
      def add_stiffener_plates(length, column, scale)
        begin
          all_stiffplates = []
          var = @wc.to_s.split(".")
          if var.last.to_i == 0
            wc = var.first
          else
            wc = var.join('.')
          end

          stiffener_plate = "PL_ #{@@height_class}(#{wc}) Stiffener"

          file_path_stiffener = Sketchup.find_support_file "#{COMPONENT_PATH}/#{stiffener_plate}.skp", "Plugins/"

          #Sets the x y and z values for placement of the plates
          x = STIFF_LOCATION
          y = (-0.5*@tw)-0.0625
          z = (0.5*@h)

          # Adds the stiffener from the component list if there already is one, otherwise it puts a new one in
          stiffener = @definition_list.load file_path_stiffener

          #sets a scale object to be called on the stiffeners based on the scale
          resize1 = Geom::Transformation.scaling [x,y,z], scale, 1, 1
          resize2 = Geom::Transformation.scaling [length-x,y,z], scale, 1, 1

          #add 4 instances of the stiffener plate
          if not column
            stiffener1 = @outer_group.entities.add_instance stiffener, [x,y,z]
            stiffener2 = @outer_group.entities.add_instance stiffener, [x,-y,z]
            #rotates two of the stiffeners to the opposite side of the beam
            stiff_rot_first = Geom::Transformation.rotation [x,-y,z], [0,0,1], 180.degrees
            @outer_group.entities.transform_entities stiff_rot_first , stiffener2
            all_stiffplates.push stiffener1, stiffener2
          end
          stiffener3 = @outer_group.entities.add_instance stiffener, [length-x,y,z]
          stiffener4 = @outer_group.entities.add_instance stiffener, [length-x,-y,z]

          stiff_rot_second = Geom::Transformation.rotation [length-x,-y,z], [0,0,1], 180.degrees
          @outer_group.entities.transform_entities stiff_rot_second , stiffener4


          # add the plates to the array for grouping
          all_stiffplates.push stiffener3, stiffener4

          all_stiffplates.each_with_index do |plate, i|
            if plate === stiffener1 || plate === stiffener2
              plate.transform! resize1
            else
              plate.transform! resize2
            end
          end

          all_stiffplates.each {|plate| color_by_thickness(plate, @@stiff_thickness.to_r.to_f); classify_as_plate(plate); lock_scale_toX(plate) }
          #returns the all plates array
          return all_stiffplates

        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem inserting the stiffener plates")
        end
      end

      def insert_moment_clip(length)
        file_path_moment_clip = Sketchup.find_support_file "#{COMPONENT_PATH}/#{MOMENT_CLIP}", "Plugins/"

        mcd = @definition_list.load file_path_moment_clip
        moment_clip = @outer_group.entities.add_instance mcd, ORIGIN
        classify_as_plate(moment_clip)
        moment_clip2 = moment_clip.copy
        classify_as_plate(moment_clip2)

        color_by_thickness(moment_clip, 0.375)
        color_by_thickness(moment_clip2, 0.375)

        p1 = Geom::Point3d.new(0,0,@h)
        mv1 = Geom::Transformation.translation(p1)

        @outer_group.entities.transform_entities(mv1, moment_clip2)

        rot = Geom::Transformation.rotation(ORIGIN, Y_AXIS, 180.degrees)
        @outer_group.entities.transform_entities(rot, moment_clip)

        vec = Geom::Vector3d.new(length-(@hc/2), 0,0)
        slide = Geom::Transformation.translation(vec)

        @outer_group.entities.transform_entities(slide, moment_clip)
        @outer_group.entities.transform_entities(slide, moment_clip2)

        lock_scale_toX(moment_clip)
        lock_scale_toX(moment_clip2)
      end

      def add_shearplates(length, scale)
        begin
          all_shearplates = []

          var = @wc.to_s.split(".")
          if var.last.to_i == 0
            wc = var.first
          else
            wc = var.join('.')
          end

          to_w10_shear_plate = "PL_ #{@@height_class}(#{wc}) to W10"
          to_w12_shear_plate = "PL_ #{@@height_class}(#{wc}) to W12"
          resize = Geom::Transformation.scaling (1+scale.to_r.to_f), 1, 1


          if @hc < 10
            small_shear_plate = "PL_ #{@@height_class}(#{wc}) to #{@@height_class}" #This is for all beams smaller than W10's
            file_path_sm_shear_plate = Sketchup.find_support_file "#{COMPONENT_PATH}/#{small_shear_plate}.skp", "Plugins/"
          else
            file_path_sm_shear_plate = Sketchup.find_support_file "#{COMPONENT_PATH}/#{to_w10_shear_plate}.skp", "Plugins/"
          end
           file_path_lg_shear_plate = Sketchup.find_support_file "#{COMPONENT_PATH}/#{to_w12_shear_plate}.skp", "Plugins/"
          #Sets the x y and z values for placement of the plates
          x = STIFF_LOCATION
          y = (-0.5*@tw)-0.0625
          z = (0.5*@h)

          place1 = [(length/2)+14,y,z]
          place2 = [(length/2)+14,-y,z]

          resize1 = Geom::Transformation.scaling [((length/2)+14)-0.0625,y,z], scale, 1, 1
          resize2 = Geom::Transformation.scaling [((length/2)-14)-0.0625,-y,z], scale, 1, 1
          # adds in the shear plate if the beam is longer than the minimum beam length
          if @hc >= 6
            if length > MINIMUM_BEAM_LENGTH
              shear_plate = @definition_list.load file_path_sm_shear_plate
              shear_pl1 = @outer_group.entities.add_instance shear_plate, place1
              shear_pl2 = @outer_group.entities.add_instance shear_plate, place2

              # rotates the shear plate 180 o opposite side
              rot = Geom::Transformation.rotation place2, [0,0,1], 180.degrees
              @outer_group.entities.transform_entities rot, shear_pl2
              shear_pl1.transform! resize1
              shear_pl2.transform! resize1
              all_shearplates.push shear_pl1, shear_pl2
            end

            # adds in the other two shear plates if the height is higher that 12
            if @hc >= 12 && length > MINIMUM_BEAM_LENGTH
              shear_plate = @definition_list.load file_path_lg_shear_plate
              place1 = [(length/2)-14,y,z]
              place2 = [(length/2)-14,-y,z]

              shear_pl3 = @outer_group.entities.add_instance shear_plate, place1
              shear_pl4 = @outer_group.entities.add_instance shear_plate, place2
              rot = Geom::Transformation.rotation place2, [0,0,1], 180.degrees
              @outer_group.entities.transform_entities rot, shear_pl4
              shear_pl3.transform! resize2
              shear_pl4.transform! resize2
              all_shearplates.push shear_pl3, shear_pl4
            end
          end

          all_shearplates.each {|plate| color_by_thickness(plate, @@shearpl_thickness.to_r.to_f); classify_as_plate(plate); lock_scale_toX(plate)}
          return all_shearplates
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem loading the shearplates")
          return all_shearplates
        end
      end

      def align_beam(pt1, pt2, vec, group)
        begin
          #move the center of the bottom flange to the first point
          tr = Geom::Transformation.translation pt1
          @entities.transform_entities tr, group

          temp_vec = Geom::Vector3d.new [vec[0], vec[1], 0]
          vt_angle = temp_vec.angle_between vec

          #checks to see if the vec is negative-Z
          if vec[2] > 0
            vt_angle += (vt_angle * -2.0)
          end

          # Checks if the vec is vertical and applies a rotation to 90 degrees

          if Z_AXIS.parallel? vec
            rot = Geom::Transformation.rotation pt1, [0,1,0], vt_angle
            rot2 = Geom::Transformation.rotation pt1, [0,0,1], vt_angle
            @entities.transform_entities rot, group
            @entities.transform_entities rot2, group
          else
            #getrs both vectors to compare angle difference
            temp_vec = Geom::Vector3d.new [vec[0], vec[1], 0]
            beam_profile_vec = Geom::Vector3d.new [1,0,0]

            #gets the horizontal angle to rotate the face
            hz_angle = beam_profile_vec.angle_between temp_vec

            #checks if the vec is negative-X
            if vec[1] < 0
              hz_angle += (hz_angle * -2)
            end
            #rotates the profile to align with the vec horizontally
            rotation1 = Geom::Transformation.rotation pt1, [0,0,1], hz_angle
            @entities.transform_entities rotation1, group

            rot = Geom::Transformation.rotation pt1, [(-1.0*vec[1]), (vec[0]), 0], vt_angle
            @entities.transform_entities rot, group
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem aligning the beam to your specified location")
        end
      end

      def set_groups(model)
        active_model = Sketchup.active_model.active_entities.parent
        ###########################################
        #@@@@@@@ GROUP Instance Variables @@@@@@@@#
        ###########################################
        # Sets the outer group for the beam and should be named "Beam"
        @outer_group = active_model.entities.add_group
        @outer_group.name = UN_NAMED_GROUP
        # Sets the inside group for the beam and should be named "W--X--"
        @inner_group = @outer_group.entities.add_group
        @inner_group.name = "#{@@beam_name}"
        set_layer(@inner_group, STEEL_LAYER)

        # Sets the inner most group for the beam and should be named "Difference"
        @solid_group = @inner_group.entities.add_group
        @solid_group.name = WFINGROUPNAME
        ########################################
      end

      def clear_groups
        @outer_group = nil
        @inner_group = nil
        @solid_group = nil
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

      def create_geometry(pt1, pt2, view)
        begin
          model = view.model
          model.start_operation("Create Beam", true)
          set_groups(model)

          vec = pt2 - pt1
          length = vec.length
          if( length < 8 )
            UI.beep
            return
          end

          if !@model.axes.axes[0].parallel? X_AXIS
            #need to do something about the vertical ghost
            p 'Axis Off of Origin'
          end

          #draw the bare beam
          beam = draw_beam(@@beam_data, length)

          #insert all labels in the beam and column, insert 13/16" if it is a beam
          if @@flange_type == FLANGE_TYPE_COL
            column = true
            all_labels = add_labels_column(vec, length)
          else
            column = false
            all_labels = add_labels_beam(vec, length)
            thirteen_sixteenths_holes = add_13_16_holes(length) unless @hc < 6 && @@has_holes
          end

          all_labels.each {|label| label.layer = @labels_layer}

          #add holes to the beam
          add_9_16_flange_holes(length) if @@has_holes
          add_9_16_web_holes(length) if @@has_holes && !column

          case @@stiff_thickness
          when '1/4'
            @stiff_scale = 2
          when '5/16'
            @stiff_scale = 2.5
          when '3/8'
            @stiff_scale = 3
          when '1/2'
            @stiff_scale = 4
          when '5/8'
            @stiff_scale = 5
          when '3/4'
            @stiff_scale = 6
          end

          case @@shearpl_thickness
          when '1/4'
            @shear_scale = 2
          when '3/8'
            @shear_scale = 3
          when '1/2'
            @shear_scale = 4
          when '5/8'
            @shear_scale = 5
          when '3/4'
            @shear_scale = 6
          end

          if not @all_studs.empty?
            @all_studs.each {|stud| stud.layer = STEEL_LAYER }
            @all_studs.each {|stud| color_by_thickness(stud, 0.5)}
          end

          # #insert stiffener plates in the beam
          if @@has_stiffeners
            stiffplates = add_stiffener_plates(length, column, @stiff_scale)
            stiffplates.each {|plate| plate.layer = STEEL_LAYER}
          end

          if @@has_shearplates && column == false
            shplates = add_shearplates(length, @shear_scale)
            shplates.each {|plate| plate.layer = STEEL_LAYER}
          end

          if @@placement == "TOP"
            point = Geom::Point3d.new 0,0,-@h
            move_down = Geom::Transformation.new point
            @entities.transform_entities move_down, @outer_group
          elsif @@placement == "MID"
            point = Geom::Point3d.new 0,0, @h * -0.5
            move_down = Geom::Transformation.new point
            @entities.transform_entities move_down, @outer_group
          end

          #draw and classify the baseplate of a flang column
          classify_as_plate(draw_parametric_plate(sq_plate(@w, @h))) if column
          #insert moment clip if column
          insert_moment_clip(length) if column

          #align the beam with the input points
          if @@flange_type == FLANGE_TYPE_COL
            trans = Geom::Transformation.rotation(ORIGIN, Y_AXIS, 270.degrees)
            trans2 = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 270.degrees)
            beam.entities.transform_entities(trans, beam.entities.to_a)
            beam.entities.transform_entities(trans2, beam.entities.to_a)
            gtm = []
            @outer_group.entities.each do |e|
              if e.name != beam.parent.instances[0].name
                gtm << e
              else
                e.entities.each do |e2|
                  if e2.name != beam.name
                    # @entities.transform_entities(trans, e2)
                    # @entities.transform_entities(trans2, e2)
                    e2.transform!(trans)
                    e2.transform!(trans2)
                  end
                end
              end
            end
            @entities.transform_entities(trans, gtm)
            @entities.transform_entities(trans2, gtm)

            setbak = Geom::Transformation.rotation(ORIGIN, Y_AXIS, 90.degrees)
            setbak2  = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 90.degrees)
            @entities.transform_entities((setbak*setbak2), @outer_group)

            vector = Geom::Vector3d.new(0, 0, STANDARD_BASE_PLATE_THICKNESS)
            sld = Geom::Transformation.translation(vector)
            @entities.transform_entities(sld, @inner_group)

          end

          align_beam(pt1, pt2, vec, @outer_group)

          # This code checks to see if it is a column
          # if it is, and is being drawn from the top down
          # it makes sure to do the appropriate rotation
          if vec[0] == 0 && vec[1] == 0 && vec[2] < 0
            center = @outer_group.bounds.center
            # p "#{center}"
            new_rot = Geom::Transformation.rotation center, [0,1,0], 180.degrees
            @entities.transform_entities new_rot, @outer_group
          end

          # Cuts the holes if the option is checked
          if @@cuts_holes && @@has_holes
            beam.explode
            @nine_sixteenths_holes.each do |hole|
              hole.explode if not hole.deleted?
            end
            thirteen_sixteenths_holes.each {|hole| hole.explode} if not column
          end

          model.commit_operation

        end

      rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
        UI.messagebox("There was a problem with the Flange Tool. Please contact customer support for assistance")
        return @outer_group
      end
    end #end beam tool

  end # end module
end #module
  #-----------------------------------------------------------------------------