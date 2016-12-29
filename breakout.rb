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
                return true
                possibilities.push 'True'
              else
                possibilities.push 'False'
              end
            else
              next
              p 'next'
            end
          end

          p possibilities
          # p possibilities.count
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
              else
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
          @beam_name = @steel_members[0].name
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
        clear_model
        create_new_file
  		end

      def is_plate?(entity)
        #write code to see if the part is a plate
      end

  		def scrape(part)
        if part.class == Sketchup::Group
          p part.entities.count
    			part.entities.each do |e|
            if e.class == Sketchup::Group && e.name.match(BEAM_REGEX)
              e.material = BEAM_COLOR
              # p e.name
              # p e.class
              # p e.definition
            end

            if e.class == Sketchup::Group && !e.name.match(BEAM_REGEX)
              e.material = PLATE_COLOR
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
        elsif part.class == Sketchup::ComponentInstance
          p part.definition.entities.count
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

      def check_for_duplicate_files(dir, file)
        if File.exist?(file)
          UI.messagebox('File already exists')
          return false
        else
          return true
        end
      end

      def clear_model
        @entities.each do |ent|
          if ent.class == Sketchup::Group || ent.class == Sketchup::ComponentInstance
            if ent.hidden?
              ent.hidden = false
            end
            if ent.locked?
              ent.locked = false
            end
          end
        end
        @selection.add @entities.to_a
        @selection.remove @steel_members.to_a
        @entities.erase_entities(@selection.to_a)
      end

      def create_new_file()
        if @multiple
          #dont do anything yet
        else
          @new_file = UI.savepanel("Save the Breakout", @path, "#{@beam_name}.skp" )
          @model.save_copy(@new_file,Sketchup::Model::VERSION_2017)

          # @sketchup = Sketchup.file_new
          # @model_2 = @sketchup.active_model
          # p1 = [0,0,0]
          # p2 = [10,10,10]
          # ents = @model_2.entities
          # ents.add_line p1, p2
          # @new_file = UI.savepanel("Save the Breakout", @path, "#{@beam_name}.skp" )
          # Sketchup.open_file(File.join(@new_file))
          UI.openURL(File.join(@new_file))
        end
      end

      # def check_for_directory(dir)

      # end

      def find_breakout_location
        f1 = 'Steel'
        f2 = 'SketchUp Break-Outs'
        d = @path.split('\\')
        d.pop
        d.pop
        @path = File.join(d, f1, f2)
        Dir.chdir("#{@path}")
  		end


  	end
  end
end