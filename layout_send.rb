# This is the tool that takes a steel part and sends it to breakout

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'

    class SendToLayout

      #part = steel component
      def initialize(part)
        @part = part
        create_layout_file
      end

      def create_layout_file
        newfile = UI.savepanel("Create the layout file", '', "#{@part.name}.layout")
        # Open an existing LayOut document.
        doc = Layout::Document.open(newfile)

        # Grab other handles to commonly used collections inside the model.
        layers = doc.layers
        pages = doc.pages
        entities = doc.shared_entities

        # Now that we have our handles, we can start pulling objects and making
        # method calls that are useful.
        first_entity = entities.first

        number_pages = pages.length

        rect = Layout::Rectangle.new([[1, 1], [2, 2]])
        doc.add_entity(rect, layers.first, pages.first)

        doc.save
        UI.openURL(newfile)
      end
    end #class
  end #module
end #module


new_file = UI.savepanel("Save the Breakout", @path, "#{part_name}.skp" )
            if new_file
              Sketchup.undo
              member_definition.save_as(new_file)
              paths.push new_file
              member.material = @materials["#{BEAM_COLOR}"]
              set_breakout_directory(@path)
            end
            temp_group.explode if temp_group
          end
          paths.each {|path| UI.openURL(path)}