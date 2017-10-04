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

      def qualify_selection(sel)
        if sel[0].class == Sketchup::Group && sel[0].name.match(GROUP_REGEX)
          # p 'passed as a group'
          return true

        elsif sel[0].class == Sketchup::ComponentInstance && sel[0].definition.name.match(GROUP_REGEX)
          # p 'passed as a Component'
          return true

        else
          # p 'not validated, give warning and allow user to decide'
          result = UI.messagebox("You are trying to break out a part with an unconventional name '#{sel[0].name}', do you wish to continue?", MB_YESNO)
          if result == 6
            return true
          else
            return false
          end
        end
      end

      def set_breakout_directory(path)
        @@breakout_dir = path
      end

      def sanitize_selection(sel)
        if sel.count > 1
          UI.messagebox("You must only have one member selected to send to breakout")
          return
          # @multiple = true
          # p 'multiple'
          # sel.each_with_index {|member, i| @steel_members.push validate_selection(member)}
        else
          @multiple = false
          p 'single'
          @steel_members.push sel[0]
          @beam_name = @steel_members[0].name
        end
      end

      def validate_selection(sel)
        if sel.class == Sketchup::Group
          return sel
        else
          p'no joy in validate selection'
        end
      end

      def go
        if qualify_selection(@selection)
          sanitize_selection(@selection)
          find_breakout_location
          create_new_file
        end
      end

      def create_new_file()
        if @multiple
          paths = []
          @steel_members.each do |member|
            temp_group = @model.active_entities.add_group(member)
            member_definition = temp_group.definition
            if member.class == Sketchup::ComponentInstance
              if member.name.empty?
                part_name = member.definition.name
              else
                part_name = member.name
              end
            else
              part_name = mamber.name
            end
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
        else
          p 'creating a new file'
          steel_member = @steel_members.first
          temp_group = @model.active_entities.add_group(steel_member)
          defn = temp_group.definition
          @new_file_path = UI.savepanel("Save the Breakout", @path, "#{@beam_name}.skp" )
          p @new_file_path
          if !@new_file_path.nil?
            defn.save_as(@new_file_path)
            steel_member.material = @materials["#{BEAM_COLOR}"]
            UI.openURL(@new_file_path)
            set_breakout_directory(@path)
          end
        temp_group.explode if temp_group
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
          # a = @path.split("\\")
          # a.pop
          # a.pop

          # #############################
          # #############################
          # #############################
          # if Dir.exist?(File.join(a))
          #   b = File.join(a)
          #   Dir.chdir(b)
          #   p b.to_s + " is a directory"
          # else
          #   p "could not find the directory #{}"
          # end
          # b = Dir.chdir(File.join(a)) if Dir.chdir(File.join(a)) # This is the code that is throwing off the guys on the network
          #############################
          #############################
          #############################
          # b1 = Dir["**/*Steel*/*Break*"]
          if defined? @@breakout_dir #Check if you have saved the path
            p 'you have been here before'
            @path = @@breakout_dir
            # puts 'Preset Path Found'
            return
          # elsif !b1.empty? && File.expand_path(b1.first) #Check if you are in the master model
          #   p 'you are in the master model'
          #   @path = File.expand_path(b1.first)
          #   return
          # else #Check the server for job folder
          #   p 'Checking fo the path in the server'
          #   t1 = Thread.new {
          #     p 'Started a new thread 1'
          #     Dir.chdir("#{SERVER_PATH}") #This needs to find the DELL instead of the X: drive for those who have the drive on the network
          #     possible_names = get_assumed_names
          #     p 'got get_assumed_names'
          #     possible_names.each do |name|
          #       p name
          #       path_to_job = Dir["**/*#{name}*/*Steel*/*Break*"]
          #       if !path_to_job.empty?
          #         @path = File.expand_path(path_to_job.first)
          #         # p @path
          #         return
          #       end
          #     end
          #   }

          #   t2 = Thread.new {
          #     p 'started a new thread'
          #     UI.start_timer(10) {t1.kill}
          #     p ' Killed t1'
          #   }
          else
            p 'setting the server path'
            @path = @model.path
          end
          # UI.messagebox("Could not find the job folder in 3X Jobs(server), Perhaps it's in the ARCHIVE")
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          # Dir.chdir("#{SERVER_PATH}")
          UI.messagebox("I could not find the 'Steel/SketchUp Break-Outs' for this job. manually locate it and i will save the path until you close SketchUp ")
        end
      end

    end #Class
  end
end

# Dir.chdir(@server_path) do
#   a = Dir["picture_*@2x.*"]
# end