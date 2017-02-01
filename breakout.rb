# This is the tool that takes a steel part and breaks it out

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'

    DICTIONARY_NAME       = "3DS Steel"
    SCHEMA_KEY            = "SchemaType"
    SCHEMA_VALUE          = ":Plate"

    DONE_COLOR = '1 Done'
    PLATE_COLOR = 'Black'

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
      include BreakoutSetup

      def initialize
        @users_template = Sketchup.template
        # Sketchup.template= Sketchup.find_support_file('Breakout.skp', "Plugins/#{FNAME}/Models/")
        @model = Sketchup.active_model
        BreakoutSetup.set_styles(@model)
        BreakoutSetup.set_scenes(@model)
        @entities = @model.entities
        @materials = @model.materials
        @selection = @model.selection
        @styles = @model.styles
        @plates = []
        @steel_member = @entities.first
        @member_name = @steel_member.name
        @labels = []
        activate
      end

      def activate
        position_member(@steel_member)
        color_steel_member(@steel_member)
        components = scrape(@steel_member)
        temp_color(@plates)
        #last method This resets the users template to what they had in the beginning
        # Sketchup.template = @users_template
      end

      def user_check(entities)
        #This code will color all the classified plates black and siuspend the operation and allow the user to visually
        #check that all the plates are accounted for and hit ENTER if to continue or ESC if they need to do some modeling.
      end

      def color_steel_member(member)
        member.material = @materials[DONE_COLOR]
      end

  		def scrape(part)
        if part.class == Sketchup::Group
    			part.entities.each do |e|
            if e.definition.attribute_dictionary("#{DICTIONARY_NAME}", "#{SCHEMA_KEY}").values.include?(SCHEMA_VALUE)
              @plates.push e
            end
          end
        else
          part.definition.entities.each do |e|
            if e.definition.attribute_dictionary("#{DICTIONARY_NAME}", "#{SCHEMA_KEY}").values.include?(SCHEMA_VALUE)
              @plates.push e
            end
          end
        end
  		end

      def temp_color(plates)
        if plates.nil?
          return
        else
          plates.each do |p|
            p.material = PLATE_COLOR
          end
        end
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