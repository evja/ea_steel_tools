# This is the tool that takes a steel part and sends it to breakout

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    GROUP_REGEX = /([A-Z,a-z]{2})(\d{3})/
    BEAM_REGEX = /(([W,w])\d{1,2}([X,x])\d{1,3})/
    BEAM_COLOR = "3 Broken Out"
    SERVER_PATH = "//DELL/Data"
    JOBS_LOCATION = "3X Jobs(server)"
    # Function for getting the server is pushd //DELL/Data

    module BreakoutSendMod
      def self.qualify_selection(sel)
        if sel[0].class == Sketchup::Group && sel[0].name.match(GROUP_REGEX)
          p 'passed as a group'
          return true

        elsif sel[0].class == Sketchup::ComponentInstance && sel[0].definition.name.match(GROUP_REGEX)
          p 'passed as a Component'
          return true

        else
          p 'not validated'
          return false
        end
      end
    end

    class SendToBreakout

      def initialize
        @model = Sketchup.active_model
        @entities = @model.entities
        @selection = @model.selection
        @materials = @model.materials
        @plates = []
        @steel_members = []
        @labels = []
        @multiple = ''
        @path = @model.path
        go
      end

      def set_breakout_directory(path)
        @@breakout_dir = path
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
        end
      end

      def validate_selection(sel)
        if sel.class == Sketchup::Group && sel.name.match(GROUP_REGEX)
          return sel
        else
          p'no joy in validate selection'
        end
      end

      def go
        sanitize_selection(@selection)
        find_breakout_location
        create_new_file
      end

      def create_new_file()
        if @multiple
          paths = []
          @steel_members.each do |member|
            temp_group = @model.active_entities.add_group(member)
            member_definition = temp_group.definition
            new_file = UI.savepanel("Save the Breakout", @path, "#{member.name}.skp" )
            if new_file
              member_definition.save_as(new_file)
              Sketchup.undo
              paths.push new_file
              member.material = @materials[BEAM_COLOR]
              set_breakout_directory(@path)
            else
              Sketchup.undo
            end

          end
          paths.each {|path| UI.openURL(path)}
        else
          steel_member = @steel_members.first
          temp_group = @model.active_entities.add_group(steel_member)
          defn = temp_group.definition
          @new_file_path = UI.savepanel("Save the Breakout", @path, "#{@beam_name}.skp" )
          p @new_file_path
          if !@new_file_path.nil?
            defn.save_as(@new_file_path)
            UI.openURL(@new_file_path)
            steel_member.material = @materials[BEAM_COLOR]
            set_breakout_directory(@path)
          end
          Sketchup.undo
        end
      end

      def directory_exists?(directory)
        File.directory?(directory)
      end

      def get_assumed_names
        model_names = @model.path.split('\\').last.split(' ')
        name_option1 = model_names.first
        name_option2 = model_names[0] + ' ' + model_names[1]
        return [name_option2, name_option1]
      end

      def find_breakout_location
        begin
          a = @path.split("\\")
          a.pop
          a.pop
          b = Dir.chdir(File.join(a))
          b1 = Dir["**/*Steel*/*Break*"]
          if !b1.empty? && File.expand_path(b1.first)
            c = File.expand_path(b1.first)
            @path = c
            return
          elsif defined? @@breakout_dir #Check if you have saved the path
            @path = @@breakout_dir
            puts 'Preset Path Found'
          else #Check the server for job folder
            Dir.chdir("#{SERVER_PATH}") #This needs to find the DELL instead of the X: drive for those who have the drive on the network
            possible_names = get_assumed_names
            p possible_names
            possible_names.each do |name|
              path_to_job = Dir["**/*#{name}*/*Steel*/*Break*"]
              if !path_to_job.empty?
                @path = File.expand_path(path_to_job.first)
                p @path
                return
              end
            end
          end
          @path = SERVER_PATH
          UI.messagebox("Could not find the job folder in 3X Jobs(server), Perhaps it's in the ARCHIVE")
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          Dir.chdir("#{SERVER_PATH}")
          UI.messagebox("I could not find the 'Stee/SketchUp Break-Outs' for this job. manually locate it and i will save the path until you close SketchUp ")
        end
      end


    end
  end
end




# Dir.chdir(@server_path) do
#   a = Dir["picture_*@2x.*"]
# end