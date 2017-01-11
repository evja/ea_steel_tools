# This is the tool that takes a steel part and sends it to breakout

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    GROUP_REGEX = /([A-Z,a-z]{2})(\d{3})/
    BEAM_REGEX = /(([W,w])\d{1,2}([X,x])\d{1,3})/
    BEAM_COLOR = 220,20,60
    PLATE_COLOR = 'black'

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
        @plates = []
        @steel_members = []
        @labels = []
        @multiple = ''
        @path = @model.path
        go
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
            end
          end
          paths.each {|path| UI.openURL(path)}
        else
          steel_member = @steel_members.first
          temp_group = @model.active_entities.add_group(steel_member)
          defn = temp_group.definition
          @new_file_path = UI.savepanel("Save the Breakout", @path, "#{@beam_name}.skp" )
          if @new_file_path
            defn.save_as(@new_file_path)
            # temp_group.explode
            Sketchup.undo
            UI.openURL(@new_file_path)
          end
        end
      end

      def add_scenes
        pages = @mod2.pages
        view = @mod2.active_view
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