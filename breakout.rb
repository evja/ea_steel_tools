# This is the tool that takes a steel part and breaks it out

#Bolts Layer needs to be turned off

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    require 'benchmark'

    class Breakout
      include BreakoutSetup
      include Control

      def activate

        Sketchup.active_model.start_operation("set environment and run checks", true, true)
        @model = Sketchup.active_model
        unless qualify_model(@model)
          result = UI.messagebox("You are trying to breakout a part with an unconventional name: #{@model.title}, do you wish to continue? If you do continue you risk the tool not behaving properly", MB_YESNO)
          if result == 7
            reset
            return
          end
        end
        @@environment_set = false if not defined? @@environment_set
        @pages = @model.pages
        # @users_template = Sketchup.template
        # Sketchup.template= Sketchup.find_support_file('Breakout.skp', "Plugins/#{FNAME}/Models/")
        @entities = @model.entities
        @materials = @model.materials
        @selection = @model.selection
        @d_list = @model.definitions
        @styles = @model.styles
        @plates = []
        @steel_member = @selection.first
        @letters = [*"A".."Z"]
        @unique_plates = []
        @labels = []
        @status_text = "Please Verify that all the plates are accounted for: RIGHT ARROW = 'Proceed' LEFT ARROW = 'Go Back'"
        @state = 0
        components = scrape(@steel_member)
        # p 'evaluating for empty plates'
        if @plates.empty?
          result = UI.messagebox("Did not detect any plates, do you wish to continue?", MB_YESNO)
          if result == 6
            @state = 1
            position_member(@steel_member)
            set_envoronment if @@environment_set == false
            color_steel_member(@steel_member)
            set_layer(@steel_member, BREAKOUT_LAYERS[0])
            hide_parts(@steel_member, @pages[1], 16)
            update_scene(@pages[1])
            reset
          else
            @plates = []
            reset
          end
        else
          # p 'coloring'
          temp_color(@plates)
          temp_label(@plates, @model.active_view)
        end
        #last method This resets the users template to what they had in the beginning
      end

      def qualify_model(model)
        ents = model.entities
        if model.title.match GROUP_REGEX
        # if model.entities.count == 1
          if ents[0].class == Sketchup::Group && ents[0].name.match(GROUP_REGEX)
            # p 'passed as a group'
            return true
          elsif ents[0].class == Sketchup::ComponentInstance #&& ents[0].definition.name.match(GROUP_REGEX)
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

      def reset
        Sketchup.send_action "selectSelectionTool:"
        @plates = [] if @state == 2
        @model.commit_operation
      end

      def set_envoronment
        BreakoutSetup.set_styles(@model)
        BreakoutSetup.set_scenes(@model)
        BreakoutSetup.set_materials(@model)
        BreakoutSetup.set_layers(@model)
        @@environment_set = true
      end

      def color_steel_member(member)
        if @materials[DONE_COLOR]
          member.material = @materials[DONE_COLOR]
        else
          UI.messagebox("Paint the steel part the done color")
          # message = UI::Notification.new(STEEL_EXTENSION, "Paint the steel part the done color")
          # message.show
        end
      end

      def scrape(part) #part is the assumed steel part (beam or column with all respective sub components)
        # p 'scraping'
        begin
          part.definition.entities.each do |e|
            if defined? e.definition
              if not e.definition.attribute_dictionaries == nil
                if not e.definition.attribute_dictionaries[DICTIONARY_NAME] == nil
                  if e.definition.attribute_dictionaries[DICTIONARY_NAME].values.include?(SCHEMA_VALUE)
                    # p 'deep inside scraping'
                    a = {object: e, orig_color: e.material, vol: e.volume, xscale: e.definition.local_transformation.xscale, yscale: e.definition.local_transformation.yscale, zscale: e.definition.local_transformation.zscale}
                    @plates.push a
                  end
                end
              end
            end
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem scraqping the plates")
        end
      end

      def temp_color(plates)
        if plates.nil?
          return
        else
          # p 'inside temp color'
          plates.each do |plate|
            plate[:object].material = PLATE_COLOR
            # p 'gathering plates temp colors'
            # plates[plate].material = PLATE_COLOR
          end
        end
      end

      def temp_label(plates, view)
        # p 'inside labeling'
        @t_labels = []
        v = Geom::Vector3d.new [0,0,1]
        v.length = 20
        plates.each do |pl|
          # p 'labeling each plate'
          t = 'PLATE'
          pt = pl[:object].bounds.center
          txt = @steel_member.definition.entities.add_text t, pt, v
          @t_labels.push txt
        end
        view.refresh
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

        c = member.bounds.center

        tr2 = Geom::Transformation.axes c, X_AXIS, Y_AXIS, Z_AXIS
        member.move! tr2.inverse
      end

      def move_stuff
         Sketchup.status_text = "Breaking out the paltes"
         position_member(@steel_member)
         sort_plates(split_plates)
         @named_plate_definitions = name_plates()
         flat_plates = spread_plates
         set_envoronment if @@environment_set == false
         color_steel_member(@steel_member)
         set_layer(@plate_group, BREAKOUT_LAYERS[1])
         set_layer(@steel_member, BREAKOUT_LAYERS[0])
         @plate_group.visible = false
         hide_parts(@plate_group, @pages.first, 16)
         @steel_member.visible = false
         hide_parts(@steel_member, @pages[1], 16)
         hide_parts(@steel_member, @pages[2], 16)
         update_scene(@pages[1])
      end

      def onKeyDown(key, repeat, flags, view)
        if @state == 0 && key == VK_RIGHT
          restore_material(@plates)
          @model.start_operation("Breakout", true)
          @state = 1
          move_stuff
          reset
        elsif @state == 0 && key == VK_LEFT
          restore_material(@plates)
          Sketchup.status_text = "Classify Plates Then Start Again"
          @plates = []
          @state = 2
          reset
        end
      end

      def update_scene(page)
        @pages.selected_page = page
        vw = @model.active_view
        lyr = @model.layers[BREAKOUT_LAYERS[0]]
        page.set_visibility(lyr, false)
        vw.zoom_extents
        page.update(32)
        page.update(1)
        @pages.selected_page = @pages[0]
        page.set_visibility(lyr, true)
      end

      def hide_parts(part, page, code)
        pg = @pages.selected_page
        @pages.selected_page = page
        part.visible = false
        page.update(code)
        @pages.selected_page = pg
      end

      def show_parts(part, page, code)
        pg = @pages.selected_page
        @pages.selected_page = page
        part.visible = true
        page.update(code)
        @pages.selected_page = pg
      end

      def split_plates()
        @individual_plates.each do |plate|
          @unique_plates.push plate.definition.instances
        end
        @unique_plates.uniq! if @individual_plates.count > 0
        @unique_plates.compact! if @unique_plates.compact != nil

        return @unique_plates
      end

      # def check_for_locked_groups(group)
      #   group.each do |plate|
      #     gents = plate.definition.entities
      #     if gents.count < 4
      #       gents.each do |e|
      #         if e.class == Sketchup::Group || e.class == Sketchup::ComponentInstance
      #           if e.locked?
      #             e.explode
      #             return
      #           end
      #         end
      #       end
      #     end
      #   end
      # end

      def sort_plates2(plates)
        plates each do |pl|
          bnds = pl.bounds.diagonal.to_f.round(4)

          #(idea) create a hash of objects and thier diagonal and compact it.
          #check definition instances against each other for diagonal

          #make differences unique and update the definition

          #check that the now true thickness matches the material thickness

          #give warnings when some of these occur.
        end

      end

      def sort_plates(plates)
        plates_hash = {}
        plates.each do |pl|
          if pl.class == Array && pl.count > 1
            pl.each do |part|
              bnds = part.bounds.diagonal.to_f.round(4)
              cl = part.material.name

              plates_hash[part] = bnds
            end

            # if there are multiple instances of the plate and none of the other diagonal bounds match then make unique and reset the scale definition.
            counter = 1
            uniqueholder = []
            plates_hash.each do |k,v|
              phc = plates_hash.clone.each do |k1, v1|
                if k != k1
                  if (k.equals?(k1)) && (v != v1)
                    uniqueholder.push k
                    plates_hash.delete(k)
                  end
                end
              end
              counter += 1
            end

            instance_materials = []
            test_bucket = []
            pl.each_with_index do |plate, i|
              instance_materials.push plate.material
              test_bucket.push item = {color: plate.material.name, object: plate, index: i}
            end
            if instance_materials.uniq.count == 2
              instance_materials.uniq!

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
        plates2 = @unique_plates.flatten!
        plates2.uniq!
        plates = sort_plates_for_naming(plates2.uniq)

        # This code finds the direction labels in the component definition list and renames them so the letters of the alphabet are available for plates
        poss_labs = ["N", "S", "E", "W", "X"]
        poss_labs.each do |lab|
          if @d_list[lab]
            # p "Found a direction in the list"
            @d_list[lab].name = "Direction Label"
          else
            # p "not FOUND"
          end
        end

        test_b = []
        plates.each do |plt|
          test_b.push plt.definition
        end
        test_b.uniq!
        test_b.each_with_index do |plt, i|
          if plt.group?
            plt.instances.each {|inst| inst.to_component}
          end
          if @d_list[@letters[i]]
            @d_list[@letters[i]].name = "Temp"
          end
          add_plate_attributes(plt)
          plt.name = @letters[i]
        end
        return test_b
      end

      def label_plate(plate, group)
        labels = []
        mod_title = @model.title

        container = group.entities.add_group

        plname = plate.definition.name
        var = mod_title + '-' + plname
        text = container.entities.add_3d_text(var, TextAlignLeft, STEEL_FONT, false, false, 0.675, 0.0, -0.00, false, 0.0)

        align = Geom::Transformation.axes([plate.bounds.center[0], plate.bounds.center[1], 0], X_AXIS, Y_AXIS, Z_AXIS )
        vr = X_AXIS.reverse
        vr.length = (container.bounds.width/2)
        shift = Geom::Transformation.translation(vr)
        # container.move! align
        @entities.transform_entities align, container
        @entities.transform_entities shift, container
        return container
      end


      def sort_plates_for_naming(plates_array)
        begin
          thck1 = [] #H 1/4" Thickness
          thck2 = [] #G 5/16" Thickness
          thck3 = [] #F 3/8" Thickness
          thck4 = [] #E 1/2" Thickness
          thck5 = [] #D 5/8" Thickness
          thck6 = [] #C 3/4" Thickness
          thck7 = [] #special Thickness
          thck8 = [] #special Thickness

        plates_array.each_with_index do |plate|
          # thickness = get_plate_thickness_verified(plate)
          case plate.material.name
          when /¼"/
            # p plate.material.name
            # thickness = 1/4.to_f
            thck1.push plate
          when /5_16"/
            # p plate.material.name
            # thickness = 5/16.to_f
            thck2.push plate
          when /⅜"/
            # p plate.material.name
            # thickness = 3/8.to_f
            thck3.push plate
          when /½"/
            # p plate.material.name
            # thickness = 1/2.to_f
            thck4.push plate
          when /⅝"/
            # p plate.material.name
            # thickness = 5/8.to_f
            thck5.push plate
          when /¾"/
            # p plate.material.name
            # thickness = 3/4.to_f
            thck6.push plate
          when /Special Thick/
            # p plate.material.name
            # thickness = "UNKNOWN"
            thck7.push plate
          when /⅞"/
            # thickness = 7/8.to_f
            thck7.push plate
          else
            # p plate.material.name
            # thickness = "UNKNOWN"
            thck8.push plate
          end
          # p plate.attribute_dictionary[DICTIONARY_NAME]["thick"] = thickness
        end

        sorted = [thck1, thck2, thck3, thck4, thck5, thck6, thck7, thck8].flatten
        return sorted
        rescue
          UI.messagebox('There was a problem sorting the plates by thickness, possibly a name change for the color thicknesses. this code uses the letters A(Charcoal) B(special thickness) C(3/4") ect')
        end
        # Sorth the paltes by thickness first (thinnest to thickest) then do a sub sort of the quantity (highest to lowest) then put volume (biggest to smallest)
      end

      def add_plate_attributes(classified_plate)
        if classified_plate.attribute_dictionary(DICTIONARY_NAME).values.include? SCHEMA_VALUE
          PLATE_DICTIONARIES.each_with_index do |d, i|
            classified_plate.attribute_dictionary(DICTIONARY_NAME)[d] = i
          end
        else
          UI.messagebox("The item you are attempting this on is not a classified plate.")
          return nil
        end
      end

      def get_largest_face(entity)
        entity.definition.entities
        faces = entity.definition.entities.select {|e| e.typename == 'Face'}
        largest_face = [0, nil]

        sorted_faces = Hash[*faces.collect{|f| [f,f.area]}.flatten].sort_by{|k,v|v}
        largest_face = sorted_faces[-1]
        # faces.each do |face|
        #   if face.area >= largest_face[0]
        #     largest_face[0] = face.area
        #     largest_face[1] = face
        #   else
        #     next
        #   end
        # end
        return largest_face[0]
      end

      def sort_plates_for_spreading(plates)
        sorted = []
        alphabet = ("A".."Z").to_a
        plates.each_with_index do |pl, i|
          letter = pl.name
          alphabet.each_with_index do |let, i2|
            if letter == let
              sorted[i2] = pl
              break
            end
          end
        end

        return sorted
      end

      def get_plate_thickness_verified(plate)
        #go through each plate and check that it's color is the same as the scale
        ########################  DEVELOPMENT START  ######################################
        thickness = 0
        color = plate.material.name
        #########################  DEVELOPMENT END   ######################################
      end

      def spread_plates
        copies = []
        alph = ("A".."Z").to_a
        plates2 = @d_list.map{|pl| pl if alph.include? pl.name}.compact!
        plates = sort_plates_for_spreading(plates2)

        next_distance = 0
        last_plate_width = 0
        dist = 1

        label_locs = []
        @plate_group = @entities.add_group
        # @plate_group.instance.name = 'Plates'
        plates.compact!
        plates.each do |pl|
          # @model.start_operation("spread a plate", true)

          insertion_pt = [dist, 3, 0]
          pl_cpy = @plate_group.entities.add_instance pl, insertion_pt
          copies.push pl_cpy
          pl_cpy.material = pl.instances.first.material

          #compare copy to scraped plates
          copy_def = pl_cpy.definition
          @named_plate_definitions.first
          prop_def = @named_plate_definitions.select {|pd| pd if pd == copy_def}
          x = prop_def[0].instances.first.transformation.xscale
          y = prop_def[0].instances.first.transformation.yscale
          z = prop_def[0].instances.first.transformation.zscale

          trans = Geom::Transformation.scaling(x,y,z) #Test this after the brute one dont work

          pl_cpy_trans = pl_cpy.transform! trans

          pl_cpy.name = "x"+((pl_cpy.definition.count_instances) - 1).to_s
          # pl_cpy.name = "#{@steel_member.name}-#{pl.material.to_r.to_f}-#{((pl_cpy.definition.count_instances) - 1)}"

          face = get_largest_face(pl_cpy)
          if face == nil
            p 'found nil'
            next
          else
            pl_norm = face.normal
          end
          #########################################################################

          # pl_cpy = pl_cpy.make_unique

          #########################################################################
          if not pl_norm.parallel? Z_AXIS
            if pl_norm.parallel? X_AXIS
              rotation1 = pl_norm.angle_between Y_AXIS
              rotation2 = pl_norm.angle_between Z_AXIS
              pl_cpy.transform! (Geom::Transformation.rotation insertion_pt, [0,0,1], rotation1)
              pl_cpy.transform! (Geom::Transformation.rotation insertion_pt, [1,0,0], rotation2)
            end
            if pl_norm.parallel? Y_AXIS
              rotation2 = pl_norm.angle_between Z_AXIS
              pl_cpy.transform! (Geom::Transformation.rotation insertion_pt, [1,0,0], rotation2)
            end
          end

          ##align long edge with Y_AXIS
          if pl_cpy.bounds.width > pl_cpy.bounds.height
            pl_cpy.transform! Geom::Transformation.rotation(insertion_pt, [0,0,1], 90.degrees)
          end

          pl_orig = pl_cpy.transformation.origin
          pl_corner = pl_cpy.bounds.min
          pos_vec = pl_orig - pl_corner
          pos_entities = Geom::Transformation.translation(pos_vec)

          pl_cpy.definition.entities.transform_entities pos_entities, pl_cpy

          pb = pl_cpy.bounds
          w = pb.width
          h = pb.height
          d = pb.depth
          plc = pb.max

          if plc[2] > 0
            vec = Geom::Vector3d.new(0,0,(plc[2]*1))
            pl_cpy.transform! (Geom::Transformation.translation(vec.reverse))
          end

          if plc[0] < 0
            vec = Geom::Vector3d.new((plc[0]*1),0,0)
            pl_cpy.transform! (Geom::Transformation.translation(vec.reverse))
          end

          pl_cpy.transform! (Geom::Transformation.translation([last_plate_width,0,0]))
          pl_label = label_plate(pl_cpy, @plate_group)
          set_layer(pl_label, SCRIBES_LAYER)

          label_locs.push pl_cpy.bounds.center
          pull_out_dist = pl_cpy.bounds.height


          last_plate_width += (w + 3)
        end
        return copies
      end

      def deactivate(view)
        # restore_material(@plates) if @state != 0
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