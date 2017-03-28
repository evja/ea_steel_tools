# This is the tool that takes a steel part and breaks it out

#Bolts Layer needs to be turned off

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
        if model.title.match GROUP_REGEX
        # if model.entities.count == 1
          if ents[0].class == Sketchup::Group && ents[0].name.match(GROUP_REGEX)
            # p 'passed as a group'
            return true

          elsif ents[0].class == Sketchup::ComponentInstance && ents[0].definition.name.match(GROUP_REGEX)
            # p 'passed as a Component'
            return true

          else
            # p 'not validated'
            return false
          end
        else
          return false
        end
      end
    end

    class Breakout
      include BreakoutSetup

      def activate
        @@environment_set = false if not defined? @@environment_set
        @model = Sketchup.active_model
        @model.start_operation("Breakout", true)
        # @users_template = Sketchup.template
        # Sketchup.template= Sketchup.find_support_file('Breakout.skp', "Plugins/#{FNAME}/Models/")
        @entities = @model.entities
        @materials = @model.materials
        @selection = @model.selection
        @definition_list = @model.definitions
        @styles = @model.styles
        @plates = []
        @steel_member = @entities.first
        @member_name = @steel_member.name
        @letters = [*"A".."Z"]
        @unique_plates = []
        @labels = []
        @status_text = "Please Verify that all the plates are accounted for: RIGHT ARROW = 'Proceed' LEFT ARROW = 'Go Back'"
        @state = 0
        set_envoronment if @@environment_set == false
        position_member(@steel_member)
        color_steel_member(@steel_member)
        components = scrape(@steel_member)
        UI.messagebox("The function could not find any classified plates") if @plates.empty?
        temp_color(@plates)
        temp_label(@plates)
        #last method This resets the users template to what they had in the beginning
        # Sketchup.template = @users_template

        @model.commit_operation
        # Sketchup.status_text =("Please Verify that all the plates are accounted for: Enter = 'Accept' Esc = 'No, need to classify some'")
      end

      def set_envoronment
        BreakoutSetup.set_styles(@model)
        BreakoutSetup.set_scenes(@model)
        BreakoutSetup.set_materials(@model)
        @@environment_set = true
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
              a = {object: e, orig_color: e.material, vol: e.volume}
              @plates.push a
            end
          end
        else
          part.definition.entities.each do |e|
            if e.definition.attribute_dictionary("#{DICTIONARY_NAME}", "#{SCHEMA_KEY}").values.include?(SCHEMA_VALUE)
              a = {object: e, orig_color: e.material, vol: e.volume}
              @plates.push a
            end
          end
        end
        # p @plates.first
      end

      def temp_color(plates)
        if plates.nil?
          return
        else
          plates.each do |plate|
            plate[:object].material = PLATE_COLOR
            # plates[plate].material = PLATE_COLOR
          end
        end
      end

      def temp_label(plates)
        @t_labels = []
        v = Geom::Vector3d.new [0,0,1]
        v.length = 20
        plates.each do |pl|
          t = 'PLATE'
          pt = pl[:object].bounds.center
          txt = @steel_member.entities.add_text t, pt, v
          @t_labels.push txt
        end
      end

      def restore_material(plates)
        @t_labels.each {|l| l.erase!} if !@t_labels.empty? #Erase all the temp labels
        @t_labels.clear
        @individual_plates = []
        plates.each do |plate|
          plate[:object].material = plate[:orig_color]

          @individual_plates.push plate[:object]
        end
        @state = 1 if @state == 0
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

      def onKeyDown(key, repeat, flags, view)
        if @state == 0 && key == VK_RIGHT
          restore_material(@plates)
          @state = 1
          Sketchup.status_text = "Breaking out the paltes"
          sort_plates(split_plates)
          plates = name_plates()
          # label_plates(plates)
          spread_plates
          Sketchup.send_action "selectSelectionTool:"
        elsif @state == 0 && key == VK_LEFT
          restore_material(@plates)
          Sketchup.status_text = "Classify Plates Then Start Again"
          @state = 2
          Sketchup.send_action "selectSelectionTool:"
        end
      end

      def split_plates()
        @individual_plates.each_with_index do |plate, i|
          @unique_plates.push plate.definition.instances
        end
        @unique_plates.uniq!
      end

      def sort_plates(plates)
        plates.each do |pl|
          if pl.class == Array && pl.count > 1
            instance_materials = []
            test_bucket = []
            pl.each_with_index do |plate, i|
              instance_materials.push plate.material
              test_bucket.push item = {color: plate.material.name, object: plate, index: i}
            end
            # p test_bucket
            if instance_materials.uniq.count == 2
              instance_materials.uniq!
              # p instance_materials

              a = []
              b = []
              test_bucket.each do |obj|
                if obj[:color] == instance_materials[0].name
                  a.push obj[:object]
                elsif obj[:color] == instance_materials[1].name
                  b.push obj[:object]
                end
              end

              # a.count > b.count ? found = b[0].make_unique : found = a[0].make_unique
              a.count > b.count ? b  : b = a
              # @individual_plates.push found

              if b.count > 1
                c = b[-1].make_unique
                b.each_with_index do |dfn, i|
                  return if i == b[-1]
                  dfn.definition = c.definition
                end
              else
                c = b[0].make_unique
              end

              @unique_plates.push c #This is a made unique plate

            elsif instance_materials.uniq.count > 2
              UI.messagebox("You have multiple components with the same definition but different thickness material. please check your plates to make different thickness plates are unique")
            else
              next
            end

          end
        end
      end

      def name_plates()
        #Assign each unique component a letter A-Z in it's definition
        plates = @unique_plates.flatten!
        plates.uniq!

        poss_labs = ["N", "S", "E", "W"]
        poss_labs.each do |lab|
          if @definition_list[lab]
            p "Found a direction in the list"
            @definition_list[lab].name = "Direction Label"
          else
            p "not FOUND"
          end
        end

        test_b = []
        plates.each do |plt|
          test_b.push plt.definition
        end
        test_b.uniq!
        test_b.each_with_index do |plt, i|
          if @definition_list[@letters[i]]
            @definition_list[@letters[i]].name = "Temp"
          end
          plt.name = @letters[i]
        end

        return test_b
      end

      def label_plates(plates)
        labels = []
        mod_title = @model.title
        plates.each_with_index do |pl, i|
          plde = pl.entities
          plname = pl.name
          var = mod_title + ' - ' + plname
          text = plde.add_3d_text(var, TextAlignLeft, '1CamBam_Stick_7', false, false, 0.5, 0.0, 0, false, 0.0)
        end
      end

      def spread_plates
        alph = ("A".."Z").to_a
        plates = @definition_list.map{|pl| pl if alph.include? pl.name}.compact!
        dist = 0
        plates.each_with_index do |pl, i|
          pl.entities.each {|f| f.material = pl.instances.first.material}
          @entities.add_instance pl, [dist, 0, 0]
          dist += 6
        end
      end

      def deactivate(view)
        restore_material(@plates)
      end

      def onMouseMove(flags, x, y, view)
        Sketchup.status_text = @status_text if @state == 0
      end

      def suspend(view)
        view.invalidate
      end

      def resume(view)
        view.invalidate
      end

  	end
  end
end