# This is the tool that takes a steel part and breaks it out

module EA_Extensions623
  module EASteelTools
		require 'sketchup.rb'
		SKETCHUP_CONSOLE.show

    module BreakoutMod
      def self.qualify_model(model)
        ents = model.entities
        if model.entities.count == 1
          if ents[0].class == Sketchup::Group && ents[0].name.match(GROUP_REGEX)
            p 'passed as a group'
            return true

          elsif ents[0].class == Sketchup::ComponentInstance && ents[0].definition.name.match(GROUP_REGEX)
            p 'passed as a Component'
            return true

          else
            p 'not validated'
            return false
          end
        else
          return false
        end
      end
    end

    class Breakout

      def initialize
        @model = Sketchup.active_model
        @entities = @model.entities
        @materials = @model.materials
        @selection = @model.selection
        @plates = []
        @steel_member = @entities.first
        @member_name = @steel_member.name
        @labels = []
        activate
			end

      def activate
        add_scenes
        set_colors
        position_member(@steel_member)
        components = scrape(@steel_member)
      end

      def set_colors
        material_files = Sketchup.find_support_files('skm', 'Plugins/ea_steel_tools/Colors')
        material_files.each do |m_file|
          @materials.load(m_file)
        end
        @done_color = @materials['1 Done']
        @steel_member.material = @done_color
      end

      def is_plate?(entity)
        #write code to see if the part is a plate
      end

  		def scrape(part)
        parts = []
        if part.class == Sketchup::Group
          # p part.entities.count
    			part.entities.each do |e|
            if e.name.match(BEAM_REGEX)
              # e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::Group && !e.name.match(BEAM_REGEX)
              if e.class == Sketchup::ComponentInstance
                # e.material = PLATE_COLOR
                # p e.class
                # p e.definition
              end

              if e.class == Sketchup::Group
                # e.material = PLATE_COLOR
                # p e.class
                # p e.definition
              end
            end


          end

        elsif part.class == Sketchup::ComponentInstance
          # p part.definition.entities.count
          part.definition.entities.each do |e|
            if e.class == Sketchup::Group && e.name.match(BEAM_REGEX)
              # e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::Group && !e.name.match(BEAM_REGEX)
              # e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end
            if e.class == Sketchup::ComponentInstance
              # e.material = PLATE_COLOR
              # p e.class
              # p e.definition
            end
            # p e.name
            # p e.class
            # p e.bounds.height
            # p e.bounds.width
            # p e.bounds.depth
          end
        end
        return parts
  		end

      def add_scenes
        pages = @model.pages
        view = @model.active_view
        perspective_scene = pages.add "Perspective"
        front_scene = pages.add "Front"
        plates_scene = pages.add "Plates"
        pages.selected_page = pages[0]
      end

      def position_member(member)
        tr = Geom::Transformation.axes ORIGIN, X_AXIS, Y_AXIS, Z_AXIS
        member.move! tr
        d = member.bounds.depth
        h = member.bounds.height
        w = member.bounds.width

        x = X_AXIS.reverse
        x.length = w/2
        slide = Geom::Transformation.translation x
        member.move! slide
      end

  	end
  end
end