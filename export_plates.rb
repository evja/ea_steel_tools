
module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    require 'benchmark'

    class ExportPlates
      include Control

      def initialize
        @model = Sketchup.active_model
        @ents = @model.entities
        @sel = @model.selection

        @model.start_operation('make wireframe', true, true, true)
        prep_plates_for_export(@sel[0])
        @model.commit_operation
        set_scene_for_dxf

        Sketchup.send_action "selectSelectionTool:"
      end

      def self.qualify_for_dxf
        if Sketchup.active_model.selection[0].layer.name == BREAKOUT_LAYERS[1]
          # p "CHECK 1 IS GOOD FOR DXF"
          return true
        else
          false
        end
      end

      def color_layers
        @layers.add(INFO_LAYER) if not @layers.include? INFO_LAYER
        @layers.add(SCRIBES_LAYER) if not @layers.include? SCRIBES_LAYER
        @layers["Layer0"].color = Sketchup::Color.new(255,255,255)
        @layers[INFO_LAYER].color = Sketchup::Color.new(255,255,0)
        @layers[SCRIBES_LAYER].color = Sketchup::Color.new(0,0,255)
      end


      def prep_plates_for_export(group)
        begin
          @plate_g_cpy = group.copy.make_unique
          @plate_g_cpy.name = "DXF Set"
          # set_layer(@plate_g_cpy, BREAKOUT_LAYERS.grep(/DXF/)[0])
          copy_offset = 30
          mv = Geom::Transformation.translation([0,copy_offset,0])
          @ents.transform_entities mv, @plate_g_cpy.entities.to_a
          plates = @plate_g_cpy.entities.select{|comp| comp.is_a? Sketchup::ComponentInstance} # Maybe add another validation that the part is classified "Plate"

          plates.each do |group|
            vector = Geom::Vector3d.new(0,0,1)
            dictionary = group.definition.attribute_dictionary(PLATE_DICTIONARY)

            #### Need to find the label that is touching the plate at hand
            label = @plate_g_cpy.entities.select{|grp| (grp.is_a? Sketchup::Group) && (grp.name == group.definition.name)}

            # place = Geom::Point3d.new(dictionary[INFO_LABEL_POSITION][0],dictionary[INFO_LABEL_POSITION][1]+copy_offset,dictionary[INFO_LABEL_POSITION][2])
            place = label[0].bounds.center
            gd = group.definition
            plate_ents = []
            plate_ents = recursive_explosion(group, true, plate_ents)
            plate_ents = clean_entities(plate_ents)
            check_and_handle_bevels(plate_ents)
            edges = get_edges(plate_ents)
            vert_edges = fetch_vertical_edges(edges, vector)

            @plate_g_cpy.entities.erase_entities(vert_edges.to_a)
            label = @plate_g_cpy.entities.add_text("#{Q_LABEL}=#{dictionary[Q_LABEL]}\n#{PN_LABEL}=#{dictionary[PN_LABEL]}\n#{M_LABEL}=#{dictionary[M_LABEL]}\n#{TH_LABEL}=#{dictionary[TH_LABEL]}", place)
            label.layer = @model.layers.add(INFO_LAYER)
          end

          labels = @plate_g_cpy.entities.select{|grp| grp.is_a? Sketchup::Group}
          labels.each{|label| label.explode}
          parts = @plate_g_cpy.entities
          parts.each{|e| e.material = nil}
          clean_faces(parts)

          z_vec = Z_AXIS.reverse
          plane = @model.axes.sketch_plane
          highs = get_high_ents(parts)
          move_v_to_plane(plane, highs[1], z_vec)
          move_curve_to_plane(plane, highs[0], z_vec)
          clean_under_z(highs[2])
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem preparing the plates for export, you may need to restart or do some manual work")
        end
      end

      def get_edges(ents)
        edges = ents.select {|e| e.is_a? Sketchup::Edge}
        return edges
      end

      def check_and_handle_bevels(entities)
        begin
          faces = entities.select {|e| e.is_a? Sketchup::Face}
          largest_face = [0, nil]
          sorted_faces = Hash[*faces.collect{|f| [f,f.area.round(3)]}.flatten].sort_by{|k,v|v}
          largest_face = sorted_faces[-1]
          lg_face = largest_face[0]
          comp_vec = lg_face.normal

          faces.each do |face|
            if face.deleted?
              next
            end
            vec = face.normal
            if !(vec.parallel?(comp_vec)) && !(vec.perpendicular?(comp_vec))
              angle = ((vec.angle_between(comp_vec)).radians).round(0)
              p "Angle - #{angle}"
              p "Face Size - #{face.area}"
              #1-move higher vertices directly over the lower bevel vertices to square off the plate
              verts = face.vertices

              sorted_verts = Hash[*verts.collect{|v| [v,v.position[2]]}.flatten].sort_by{|k,v|-v}
              # p sorted_verts
              sorted_verts.each_with_index do |v, i|
                p v
              end

              high_point = sorted_verts[0][0].position
              low_point = sorted_verts[2][0].position

              high_edge = sorted_verts[0][0].common_edge(sorted_verts[1][0])
              low_edge = sorted_verts[2][0].common_edge(sorted_verts[3][0])

              #make construction line where bevel goes
              sp = high_edge.start.position
              ep = high_edge.end.position
              v1 = sp - ep
              v2 = ep - sp
              lngth = (high_edge.length*0.95)
              v1.length = lngth
              v2.length = lngth

              sp1 = ep.clone
              sp2 = sp.clone

              slide1 = Geom::Transformation.translation(v1)
              slide2 = Geom::Transformation.translation(v2)

              sp1.transform! slide1
              sp2.transform! slide2

              p1 = Geom::Point3d.new(high_point[0], high_point[1], 0)
              p2 = Geom::Point3d.new(low_point[0], low_point[1], 0)

              vec = p2 - p1
              move = Geom::Transformation.translation(vec)

              @plate_g_cpy.entities.transform_entities(move, high_edge)

              bevel_line = @plate_g_cpy.entities.add_line(sp1, sp2)
              bevel_line.layer = SCRIBES_LAYER

            end
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem handling a beveled plate, it may need to be manualy fixed before exporting")
        end

      end

      def clean_entities(entities)
        ce = []
        entities.each_with_index do |e,i|
          if !e.deleted?
            ce.push e
          end
        end
        return ce
      end

      def fetch_vertical_edges(entities, vector)
        container = []
        entities = clean_entities(entities)
        entities.each do |ent|
          # p ent
          if ent.typename == "Edge"
            if ent.line[1].parallel? vector
              container.push ent
            end
          else
            next
          end
        end
        return container
      end

      def recursive_explosion(ent, condition, container)
        if condition
          parts = ent.explode
          parts.each do |e|
            if (e.is_a? Sketchup::Group) || (e.is_a? Sketchup::ComponentInstance)
             recursive_explosion(e, true, container)
            else
              container.push e
            end
          end
        else
          parts = ent.entities
          parts.each do |e|
            if (e.is_a? Sketchup::Group) || (e.is_a? Sketchup::ComponentInstance)
             recursive_explosion(e, true, container)
            else
              container.push e
            end
          end
        end
        return container
      end

      def clean_faces(entities)
        entities = clean_entities(entities)
        entities.each do |e|
          if e.is_a? Sketchup::Face
            e.erase!
          end
        end
      end

      def get_high_ents(ents)
        lofty_vertexs = []
        lofty_curves = []
        trash = []

        ents.each do |ent|
          if ent.is_a? Sketchup::Text
            next
          end
          if not ent.vertices[0].position[2].to_f > 0.00
            if ent.vertices[0].position[2].to_f <= -0.125
              trash.push ent
            end
            next
          else
            if ent.curve.nil?
              lofty_vertexs.push ent.vertices
            else
              if not lofty_curves.include? ent
                # p ''
                lofty_curves.push ent.curve.edges
                lofty_curves.flatten
              else
                # p ''
              end
            end
          end
        end
        # p lofty_curves

        return [lofty_curves.flatten, lofty_vertexs.flatten, trash.flatten]
      end

      def move_curve_to_plane(plane, curves, vector)
        edge_set = []
        curves.each do |edge|
          vpz = edge.start.position[2].to_f
          if vpz > 0.0
            edge_set.push edge.curve.edges
            edge_set.flatten
            vec = vector.clone
            vec.length = vpz

            mv = Geom::Transformation.translation(vec)
            @plate_g_cpy.entities.transform_entities(mv, edge.all_connected)
          end
        end
      end

      # def move_v_to_plane(plane, verts, vector)
      #   verts.each do |v|
      #   distance = (v.position).distance_to_plane(plane)
      #     if distance > 0
      #       vec = (v.position) - ((v.position).project_to_plane(plane))
      #       mv = Geom::Transformation.translation(vec)
      #       @ents.transform_entities(mv, v)
      #     end
      #   end
      # end

      def move_v_to_plane(plane, verts, vector)
        verts.each do |v|
          vpz = v.position[2].to_f
          if vpz > 0
            vec = vector.clone
            vec.length = vpz

            mv = Geom::Transformation.translation(vec)
            @ents.transform_entities(mv, v)
          end
        end
      end

      def clean_under_z(ents)
        @ents.erase_entities(ents)
      end

      def set_scene_for_dxf
        @model.start_operation('set_scens', true, true, true)

        pages = @model.pages
        @part_page = pages[0]
        @plate_page = pages[1]
        @dxf_page = pages[2]

        part_layer = @model.layers[BREAKOUT_LAYERS[0]]
        plates_layer = @model.layers[BREAKOUT_LAYERS[1]]
        dxf_layer = @model.layers[BREAKOUT_LAYERS[2]]

        pages.selected_page = @part_page
        @plate_g_cpy.visible = false
        @part_page.update(16)

        pages.selected_page = @plate_page
        @plate_g_cpy.visible = false
        @plate_page.update(16)

        @model.commit_operation
        pages.selected_page = @dxf_page
        @dxf_page.set_visibility(part_layer, false)
        @dxf_page.set_visibility(plates_layer, false)
        @dxf_page.set_visibility(dxf_layer, true)

        view = @model.active_view

        eye = [10,-10,10]
        target = [0,0,0]
        up = Z_AXIS
        cam = Sketchup::Camera.new(eye, target, up)
        cam.perspective = false
        view.camera = cam
        @dxf_page.use_camera = true
        view.zoom_extents
        new_style = @model.styles.add_style(Sketchup.find_support_file("DXF.style", "Plugins/#{FNAME}/Models/Styles/"), true)
        dxf_style = @model.styles['DXF']
        @dxf_page.use_style= dxf_style.name
        @dxf_page.update(3)
        pages.selected_page = @dxf_page

        @layers = @model.layers
        if @layers[" (S) Holes/Studs"]
          @layers[" (S) Holes/Studs"].name = HOLES_LAYER
        end
        color_layers

        # @plate_g_cpy.explode
        message = "Wireframe is colored by layer, check for propper layer before exporting"
        add_message(message)

      end

    end#module

  end #module
end #module