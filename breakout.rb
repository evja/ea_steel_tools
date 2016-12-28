# This is the tool that takes a steel part and breaks it out

module EA_Extensions623
  module EASteelTools
		require 'sketchup.rb'
		SKETCHUP_CONSOLE.show
		GROUP_REGEX = /([A-Z,a-z]{2})(\d{3})/
		BEAM_REGEX = /(([W,w])\d{1,2}([X,x])\d{1,3})/
    BEAM_COLOR = 220,20,60
    PLATE_COLOR = 'black'

    module BreakoutMod
      def self.qualify_selection(sel)
        if sel[0].class == Sketchup::Group && sel[0].name.match(GROUP_REGEX)
          p 'passed as a group'
          possibilities = []
          sel[0].entities.each do |ent|
            if ent.class == Sketchup::Group || ent.class == Sketchup::ComponentInstance
              p sel[0].entities.count
              if ent.name.match(BEAM_REGEX)
                p 'found the inner beam'
                return true
                possibilities.push 'True'
              else
                p 'cant find the inner beam'
                possibilities.push 'False'
              end
            else
              next
              p 'next'
            end
          end

          p possibilities
          p possibilities.count
          if possibilities.include?('True')
            return true
          else
            return false
          end

        elsif sel[0].class == Sketchup::ComponentInstance && sel[0].definition.name.match(GROUP_REGEX)
          p 'passed as a Component'
          possibilities = []
            sel[0].definition.entities.each do |ent|
              if ent.name.match(BEAM_REGEX)
                return true
                possibilities.push 'True'
                p 'found the inner beam'
              else
                p 'cant find the inner beam'
                possibilities.push 'False'
              end

              if possibilities.include?('True')
                return true
              else
                return false
              end
            end
        else
          p 'not validated'
          return false
        end
      end
    end



    class Breakout

      def initialize
        @model = Sketchup.active_model
        @entities = @model.entities
        @selection = @model.selection
        @plates = []
        @steel_members = []
        @labels = []
	  		@multiple = ''
	  		@path = @model.path
	  		activise

	  		p 'all variables initialized'
			end

  		def sanitize_selection(sel)
  			if sel.count > 1
          @multiple = true
          p 'multiple'
  				sel.each_with_index {|member, i| @steel_members.push validate_selection(member)}
  			else
          @multiple = false
          p 'single'
  				@steel_members.push validate_selection(sel[0])
          p @steel_members
  			end
  		end

  		def validate_selection(sel)
        p sel
        p sel.class
        p sel.name
  			if sel.class == Sketchup::Group && sel.name.match(GROUP_REGEX)
  				return sel
        else
          p'no joy in validate selection'
  			end
  		end

  		def activise
  			sanitize_selection(@selection)
        @steel_members.each {|mem| scrape(mem)}
        find_breakout_location
  		end

  		def scrape(part)
        p part
        p part.class
        p ' in the scrape'
        if part.class == Sketchup::Group
          p 'found a group'
    			part.entities.each do |e|
            if e.class == Sketchup::Group && e.name.match(BEAM_REGEX)
              p 'changed the beam color'
              e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::Group && !e.name.match(BEAM_REGEX)
              p 'changed the beam color'
              e.material = PLATE_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::ComponentInstance
              p 'changed the plate color'
              e.material = PLATE_COLOR
              # p e.class
              # p e.definition
            end
            # p e.name
            # p e.class
            # p e.bounds.height
            # p e.bounds.width
            # p e.bounds.depth
          end
        elsif part.class == Sketchup::ComponentInstance
          part.definition.entities.each do |e|
            if e.class == Sketchup::Group && e.name.match(BEAM_REGEX)
              e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::Group && !e.name.match(BEAM_REGEX)
              e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end
            if e.class == Sketchup::ComponentInstance
              e.material = PLATE_COLOR
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
  		end

  		def find_breakout_location
        # system("explorer #{@path}")
        # button_click = Proc.new {
        #   Tk.getOpenFile
        # }
  		end


  	end
  end
end