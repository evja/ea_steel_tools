
module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    require 'benchmark'

    class ExportPlates
      include Control

      def initialize
        @model = Sketchup.active_model
        @layers = @model.layers
        @ents = @model.entities
        @sel = @model.selection
        @pages = @model.pages
        @dl = @model.definitions

        @model.start_operation('make wireframe', true, true, true)
        #set view
        set_view_for_export
        beam = @ents.select{|part| part.layer.name == BREAKOUT_LAYERS[0]}
        plates = @ents.select{|part| part.layer.name == BREAKOUT_LAYERS[1]}
        dxf_original_set = @ents.select{|part| part.layer.name == BREAKOUT_LAYERS[2]}
        export_group = @sel[0].copy
        protected_geom = @ents.add_group(beam, plates, dxf_original_set)
        protected_comp = protected_geom.to_component
        pcd = protected_comp.definition
        pct = protected_comp.transformation.clone

        ######### RUNS THE SAVE COMPONENT IN DEFINITION LIST ######
        # @dl.purge_unused
        # protected_comp.erase!


        ######### RUNS THE SAVE COMPONENT IN TEMP FOLDER ######
        a = __FILE__
        b = a.split("/")
        b.pop
        b.pop
        c = File.join(b,TEMP_FOLDER,"saved_parts.skp")
        saved_temp_path = pcd.save_as(c)
        protected_comp.erase!
        @dl.purge_unused


        @model.materials.purge_unused
        @model.layers.purge_unused

        parts = export_group.explode
        begin_export

        parts.each do |pt|
          if not pt.deleted?
            if pt.respond_to? :erase!
              pt.erase!
            elsif pt.is_a? Sketchup::Vertex
              @ents.erase_entities(pt.edges)
            elsif pt.is_a? Sketchup::Curve
              @ents.erase_entities(pt.edges)
            end
          else
            next
          end
        end

        ######### RUNS THE SAVE COMPONENT IN DEFINITION LIST ######
        # ex = @ents.add_instance(pcd, pct)


        ######### RUNS THE SAVE COMPONENT IN TEMP FOLDER ######
        expath = @dl.load(c)
        ex = @ents.add_instance(expath, pct)
        File.rename(c, "Delete Me.skp")

        ex.explode

        @pages.selected_page = @pages[0]
        @pages[0].set_visibility(@layers[BREAKOUT_LAYERS[1]],false)
        @pages[0].set_visibility(@layers[BREAKOUT_LAYERS[2]],false)
        @pages[0].update(48)
        @pages.selected_page = @pages[1]
        @pages[1].set_visibility(@layers[BREAKOUT_LAYERS[0]],false)
        @pages[1].set_visibility(@layers[BREAKOUT_LAYERS[2]],false)
        @pages[1].update(48)
        @pages.selected_page = @pages[-1]
        @pages[-1].set_visibility(@layers[BREAKOUT_LAYERS[0]],false)
        @pages[-1].set_visibility(@layers[BREAKOUT_LAYERS[1]],false)
        @pages[-1].update(48)

        @model.commit_operation
        Sketchup.send_action "selectSelectionTool:"
      end


      def self.qualify_for_dxfexport
        if Sketchup.active_model.selection[0].layer.name == BREAKOUT_LAYERS[2]
          p "CHECK 1 IS GOOD FOR DXF export"
          return true
        else
          false
        end
      end

      def set_view_for_export
        # @model.start_operation('set_view', true, true, true)
        # @model.commit_operation

        pages = @model.pages
        @part_page = pages[0]
        @plate_page = pages[1]
        @dxf_page = pages[2]

        part_layer = @model.layers[BREAKOUT_LAYERS[0]]
        plates_layer = @model.layers[BREAKOUT_LAYERS[1]]
        dxf_layer = @model.layers[BREAKOUT_LAYERS[2]]

        pages.selected_page = @dxf_page
        @dxf_page.set_visibility(part_layer, false)
        @dxf_page.set_visibility(plates_layer, false)
        @dxf_page.set_visibility(dxf_layer, true)

        view = @model.active_view

        eye = [0,0,10]
        target = [0,0,0]
        up = Y_AXIS
        cam = Sketchup::Camera.new(eye, target, up)
        cam.perspective = false
        view.camera = cam
        @dxf_page.use_camera = true
        view.zoom_extents
      end

      def begin_export()
        begin
        dxf_options = {
          :faces_flag => false,
          :construction_geometry => true,
          :dimensions => true,
          :text => false,
          :edges => true
        }

        title = @model.title
        mp = @model.path
        ms = mp.split("\\")
        ms.pop
        file_path = File.join(ms)
        @export_path = UI.savepanel("Export #{title} to DXF", file_path, title )
        if @export_path
          status = @model.export("#{@export_path}.dxf", false)
        end
        # status = UI.savepanel("Save the Breakout", file_path, ".dxf;.dwg" )
      rescue
        UI.messagebox("There was a problem exporting the plates, you may need to export manually")
      end

      end

    end#class

  end #module
end #module