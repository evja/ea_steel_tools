# This is the tool that takes a steel part and sends it to breakout

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'

    class SendToLayout

      #part = steel component
      def initialize(part, path)
        @part = part
        @part_path = path
        @model_viewport_width = 11
        @model_viewport_height = 2
        # @part_type = UI.inputbox(['Select Template'], ["BeamTemplate"], ["BeamTemaplte|ColumnTemplate"],"What Layout Template Would You Like?")
        @part_type = 'BeamTemplate'
        @plate_scene = 2
        @part_scene = 1



        create_layout_file #if @part_type
      end

      def create_layout_file
        newfile = UI.savepanel("Create the layout file", '', "#{@part.name}.layout")

        template = Sketchup.find_support_file("ea_steel_tools/Templates/#{@part_type}.layout", "Plugins/")
        p template

        @doc = Layout::Document.open(template)

        # Grab other handles to commonly used collections inside the model.
        @layers = @doc.layers
        @pages = @doc.pages
        @entities = @doc.shared_entities

        @first_page = @pages.first
        @second_page = @pages[1]


        set_firstpage_viewports(@doc, @layers, @pages)

        status = @doc.save(newfile)
        UI.openURL(newfile)
      end

      def set_firstpage_viewports(doc, layers, pages)
        #This inserts the plates view
        bounds = Geom::Bounds2d.new(3, 0.5, @model_viewport_width, @model_viewport_height)
        plateviewport = Layout::SketchUpModel.new(@part_path, bounds)
        plateviewport.current_scene = @plate_scene
        plateviewport.view = Layout::SketchUpModel::FRONT_VIEW
        plateviewport.render_mode = Layout::SketchUpModel::VECTOR_RENDER
        plateviewport.perspective = false
        plateviewport.render if plateviewport.render_needed?

        s_layers = sort_layers(@layers)

        # plate_layer = layers[s_layers[:Default]]

        pvp1 = doc.add_entity(plateviewport, layers[3], pages.first)

        #this inserts the part viewport


      end

      def sort_layers(layers)
        sorted_layers = {}
        layers.each do |l|
          sorted_layers[l.name.to_sym] = l
        end
        p sorted_layers
        return sorted_layers
      end


    end #class
  end #module
end #module


# new_file = UI.savepanel("Save the Breakout", @path, "#{part_name}.skp" )
#             if new_file
#               Sketchup.undo
#               member_definition.save_as(new_file)
#               paths.push new_file
#               member.material = @materials["#{BEAM_COLOR}"]
#               set_breakout_directory(@path)
#             end
#             temp_group.explode if temp_group
#           end
#           paths.each {|path| UI.openURL(path)}