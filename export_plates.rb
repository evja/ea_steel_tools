
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
        @model.start_operation('make wireframe', true)
          prep_plates_for_export(@sel[0])
          set_scene_for_dxf
        @model.commit_operation
        @layers = @model.layers
        @layers["Layer0"].color = Sketchup::Color.new(255,255,255)
        if @layers[" (S) Holes/Studs"]
          @layers[" (S) Holes/Studs"].name = HOLES_LAYER
        end
      end

      def self.qualify_for_dxf
        if Sketchup.active_model.selection[0].layer.name == BREAKOUT_LAYERS[1]
          # p "CHECK 1 IS GOOD FOR DXF"
          return true
        else
          false
        end
      end

      def recursive_explosion(ent)
        plane = [Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1)]
        ents = ent.explode
        ents.each do |en|
          if (en.is_a? Sketchup::Group) || (en.is_a? Sketchup::ComponentInstance)
            recursive_explosion(en)
          elsif (en.is_a? Sketchup::Face)
            en.erase!
          end
        end
        return ents
      end

      def get_label_info(ents)
        label_data = {}
        plates = ents.select{|e| e.is_a? Sketchup::ComponentInstance}
        plates.each do |plt|
          @sel.add plt
          position = plt.bounds.center
          position[2] = 0
          @ents.add_cpoint position
          pname = "#{@model.title} - #{plt.definition.name}"
          thickness = plt.material.name
          label = @ents.add_text("[#{pname}]-[#{thickness}]-[#{plt.name}]", position)
          label.layer = @model.layers.add(INFO_LAYER)
        end
      end

      def prep_plates_for_export(group)
        @plate_g_cpy = group.copy.make_unique
        @plate_g_cpy.name = "DXF Set"
        @plate_g_cpy.layer = BREAKOUT_LAYERS[2]
        mv = Geom::Transformation.translation([0,30,0])
        @ents.transform_entities mv, @plate_g_cpy.entities.to_a
        # @plate_g_cpy.transform! mv
        # @plate_g_cpy.entities.each{.move! mv
        plates = @plate_g_cpy.entities.to_a
        get_label_info(plates)
        geom = plates.each{|p| recursive_explosion(p)}

        vec = Geom::Vector3d.new(0,0,1)
        vert_edges = (@plate_g_cpy.entities.to_a).select{|e| (e.is_a? Sketchup::Edge) && (e.line[1].parallel? vec)}
        p vert_edges[0].length
        p vert_edges[0].length.to_f
        p vert_edges[0].length.to_i
        @plate_g_cpy.entities.erase_entities(vert_edges.to_a)

        z_vec = Z_AXIS.reverse
        plane = @model.axes.sketch_plane
        highs = get_high_ents(@plate_g_cpy.entities)
        move_v_to_plane(plane, highs[1], z_vec)
        move_curve_to_plane(plane, highs[0], z_vec)
        clean_under_z(highs[2])
      end

      def get_high_ents(ents)
        lofty_vertexs = []
        lofty_curves = []
        trash = []

        ents.each do |ent|
          if not ent.vertices[0].position[2].to_f > 0.00
            if ent.vertices[0].position[2].to_f < -0.0625
              trash.push ent.all_connected
              ent.all_connected.each {|te| ents.to_a.delete(te)}
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
            @ents.transform_entities(mv, edge.all_connected)
          end
        end
      end

      def move_v_to_plane(plane, verts, vector)
        verts.each do |v|
          vpz = v.position[2].to_f
          if vpz > 0.0
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
        pages = @model.pages
        part_page = pages[0]
        plate_page = pages[1]
        dxf_page = pages[2]

        part_layer = @model.layers[BREAKOUT_LAYERS[0]]
        plates_layer = @model.layers[BREAKOUT_LAYERS[1]]
        dxf_layer = @model.layers[BREAKOUT_LAYERS[2]]

        pages.selected_page = part_page
        @plate_g_cpy.visible = false
        # part_page.set_visibility(dxf_layer, false)
        part_page.update(16)

        pages.selected_page = plate_page
        @plate_g_cpy.visible = false
        # plate_page.set_visibility(dxf_layer, false)
        plate_page.update(16)

        pages.selected_page = dxf_page
        dxf_page.set_visibility(part_layer, false)
        # dxf_page.update(32)
        dxf_page.set_visibility(plates_layer, false)
        # dxf_page.update(32)
        dxf_page.set_visibility(dxf_layer, true)
        # dxf_page.update(32)

        # pages.selected_page = dxf_page
        view = @model.active_view

        eye = [10,-10,10]
        target = [0,0,0]
        up = Z_AXIS
        cam = Sketchup::Camera.new(eye, target, up)
        cam.perspective = false
        view.camera = cam
        dxf_page.use_camera = true
        view.zoom_extents
        new_style = @model.styles.add_style(Sketchup.find_support_file("DXF.style", "Plugins/#{FNAME}/Models/Styles/"), true)
        dxf_style = @model.styles['DXF']
        dxf_page.use_style= dxf_style.name
        dxf_page.update(3)
        # dxf_page.update(2)
        pages.selected_page = dxf_page
        @plate_g_cpy.layer = @model.layers[0]
        # @plate_g_cpy.explode
        message = "Wireframe is colored by layer, check for propper layer before exporting"
        add_message(message)

      end

      def label_wireframes()


      end

    end#module

  end #module
end #module