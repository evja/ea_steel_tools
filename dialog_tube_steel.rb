module EA_Extensions623
  module EASteelTools
    extension_path = File.dirname( __FILE__ )
    skui_path = File.join( extension_path, 'SKUI' )
    load File.join( skui_path, 'embed_skui.rb' )
    ::SKUI.embed_in( self )
    # SKUI module is now available under EA_Steel_Tools::SKUI

    class HssDialog
      include HSSLibrary

      @@state = 0

      def initialize
        if @@state == 0
          @@tube_data             = {}   #Hash   {:h=>4, :b=>4}
          @@height_class          = '4'
          @@width_class           = '4'
          @@wall_thickness        = ''
          @@basetype              = ''
          @@basethick             = 0.75
          @@start_plate_thickness = ''
          @@end_plate_thickness   = ''
          @@studspacing           = 24  #Integer 16 or 24 or 32
          @@state                 = 1   #Integer()
          @@north_stud_selct      = true
          @@south_stud_selct      = true
          @@east_stud_selct       = true
          @@west_stud_selct       = true
          @@stud_toggle           = true
          @@hss_is_rotated        = false

          @@start_tolerance        = 1.5
          @@end_tolerance          = 0.0675

          @@hss_type                = 'Column' # Beam or Column Options
        end


        @label_font = SKUI::Font.new( 'Comic Sans MS', 8, true )
        @img_path = File.join( SKUI::PATH, '..', 'icons' )
        @img_file1 = File.join( @img_path, 'hss_section.png' )
        @img_file2 = File.join( @img_path, 'hss_rec_section.png' )
        @img_file3 = File.join( @img_path, 'hss_rec_section_rotated.png' )

        # ss is short for Stud Select and the xy is to be able to adjust the group together
        ss_x = 15
        ss_y = 0

        options = {
          :title           => "Tube Steel #{VERSION_NUM}",
          :preferences_key => 'TS',
          :width           => 416,
          :height          => 475,
          :resizable       => false
        }

        window = SKUI::Window.new( options )
        @window1 = window

        set_groups(@window1) # <- Method

        @sq_image = set_image1(@group2, @img_file1, ss_x, ss_y)
        @rec_image = set_image2(@group2, @img_file2, ss_x, ss_y)
        @rec_image_rot = set_image3(@group2, @img_file3, ss_x, ss_y)

        rotate_hss = SKUI::Checkbox.new("Rotate 90º")
        rotate_hss.font = @label_font
        rotate_hss.position(310, 155)
        rotate_hss.checked = @@hss_is_rotated
        rotate_hss.on (:change ) { |control|
          @@hss_is_rotated = control.checked?
          @rec_image.visible = !control.checked?
          @rec_image_rot.visible = control.checked?
        }
        @group2.add_control rotate_hss
        rotate_hss.visible = !(@@width_class.to_f == @@height_class.to_f)

        hss_type_select = SKUI::Listbox.new(["Column", "Beam"])
        hss_type_select.position(300, 25)
        hss_type_select.width = 68
        hss_type_select.on (:change ) {|control|
          @@hss_type = control.value
        }
        hss_type_label = SKUI::Label.new('Type')
        hss_type_label.position(265,27)
        @group1.add_control( hss_type_label )

        @group1.add_control(hss_type_select)

        hc_list_label = SKUI::Label.new('Size')
        hc_list_label.position(10,27)

        label1 = SKUI::Label.new('X')
        label1.position(100,30)
        @group1.add_control( label1 )

        label2 = SKUI::Label.new('X')
        label2.position(175,30)
        @group1.add_control( label2 )
        @group1.add_control( hc_list_label )

        list = all_height_classes
        height_class_dropdown = SKUI::Listbox.new( list )
        @@height_class.empty? ? @@height_class = (height_class_dropdown.value = height_class_dropdown.items.sample) : height_class_dropdown.value = height_class_dropdown.items.grep(@@height_class).first.to_s
        height_class_dropdown.position( 40, 25 )
        height_class_dropdown.width = 55


        list2 = all_tubes_in(@@height_class)
        width_size_dropdown = SKUI::Listbox.new( list2 )
        @@width_class.empty? ? @@width_class = (width_size_dropdown.value = width_size_dropdown.items.first) : @@width_class = (width_size_dropdown.value = width_size_dropdown.items.grep(@@width_class).first.to_s)
        width_size_dropdown.position( 113, 25 )
        width_size_dropdown.width = 55

        @group1.add_control( width_size_dropdown )

        # list3 = cuurent_selection_wall_thickness(@@width_class)
        list3 = all_guage_options_in(@@height_class, @@width_class)
        # p list3
        wall_thickness_dropdown = SKUI::Listbox.new( list3 )
        @@wall_thickness.empty? ? @@wall_thickness = (@@wall_thickness = wall_thickness_dropdown.items[1]) : (@@wall_thickness)
        wall_thickness_dropdown.value = @@wall_thickness
        wall_thickness_dropdown.position( 190, 25 )
        wall_thickness_dropdown.width = 50
        wall_thickness_dropdown.on(:change) { |control, value|
          @@wall_thickness = control.value
        }

        height_class_dropdown.on( :change ) { |control, value|
          @@height_class = control.value
          list2 = all_tubes_in(control.value)
          width_size_dropdown = SKUI::Listbox.new( list2 )
          @@width_class = width_size_dropdown.value = width_size_dropdown.items.first
          width_size_dropdown.position( 113, 25 )
          width_size_dropdown.width = 55
          @group1.add_control( width_size_dropdown )

          if @@width_class.to_f == @@height_class.to_f #is square tube
            @sq_image.visible = true
            @rec_image.visible = false
            @rec_image_rot.visible = false
            rotate_hss.visible = false
            rotate_hss.checked = false

          elsif @@width_class.to_f < @@height_class.to_f && !rotate_hss.checked? #is standard rectangle tube
            @sq_image.visible = false
            @rec_image.visible = true
            @rec_image_rot.visible = false
            rotate_hss.visible = true
            rotate_hss.checked = false

          elsif @@width_class.to_f < @@height_class.to_f && rotate_hss.checked? #is rectangle tube rotated 90º
            @sq_image.visible = false
            @rec_image.visible = false
            @rec_image_rot.visible = true
            rotate_hss.visible = true
          end
          @@hss_is_rotated = rotate_hss.checked?
          list3 = all_guage_options_in(@@height_class, @@width_class)
          wall_thickness_dropdown = SKUI::Listbox.new( list3 )
          # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.first)
          wall_thickness_dropdown.position( 190, 25 )
          wall_thickness_dropdown.width = 50
          wall_thickness_dropdown.on(:change) { |control, value|
            @@wall_thickness = control.value
          }
          @group1.add_control( wall_thickness_dropdown )

          width_size_dropdown.on( :change ) { |control, value|
            @@width_class = control.value

            if @@width_class.to_f == @@height_class.to_f #is square tube
              @sq_image.visible = true
              @rec_image.visible = false
              @rec_image_rot.visible = false
              rotate_hss.visible = false
              rotate_hss.checked = false

            elsif @@width_class.to_f < @@height_class.to_f && !rotate_hss.checked? #is standard rectangle tube
              @sq_image.visible = false
              @rec_image.visible = true
              @rec_image_rot.visible = false
              rotate_hss.visible = true
              rotate_hss.checked = false

            elsif @@width_class.to_f < @@height_class.to_f && rotate_hss.checked? #is rectangle tube rotated 90º
              @sq_image.visible = false
              @rec_image.visible = false
              @rec_image_rot.visible = true
              rotate_hss.visible = true
            end
            @@hss_is_rotated = rotate_hss.checked?
            list3 = all_guage_options_in(@@height_class, @@width_class)
            wall_thickness_dropdown = SKUI::Listbox.new( list3 )
            # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.sample)
            wall_thickness_dropdown.position( 190, 25 )
            wall_thickness_dropdown.width = 50
            @group1.add_control( wall_thickness_dropdown )
            wall_thickness_dropdown.on(:change) { |control, value|
              @@wall_thickness = control.value
            }
          }
        }
        @group1.add_control( height_class_dropdown )

        @group1.add_control( wall_thickness_dropdown )

        width_size_dropdown.on( :change ) { |control, value|
          @@width_class = control.value
          if @@width_class.to_f == @@height_class.to_f #is square tube
            @sq_image.visible = true
            @rec_image.visible = false
            @rec_image_rot.visible = false
            rotate_hss.visible = false
            rotate_hss.checked = false

          elsif @@width_class.to_f < @@height_class.to_f && !rotate_hss.checked? #is standard rectangle tube
            @sq_image.visible = false
            @rec_image.visible = true
            @rec_image_rot.visible = false
            rotate_hss.visible = true
            rotate_hss.checked = false

          elsif @@width_class.to_f < @@height_class.to_f && rotate_hss.checked? #is rectangle tube rotated 90º
            @sq_image.visible = false
            @rec_image.visible = false
            @rec_image_rot.visible = true
            rotate_hss.visible = true
          end
          @@hss_is_rotated = rotate_hss.checked?
        }

        baseselect = SKUI::Listbox.new(BASETYPES)
        baseselect.position(80,30)
        baseselect.width = 50
        @@basetype.empty? ? @@basetype = (baseselect.value = BASETYPES.first) : baseselect.value = @@basetype
        baseselect.on(:change) { |control, value|
          @@basetype = control.value
        }

        @group2.add_control(baseselect)

        base_s_label = SKUI::Label.new('Base Plate', baseselect)
        base_s_label.position(8, 33)
        @group2.add_control(base_s_label)


        # basethckselect = SKUI::Textbox.new(@@basethick)
        # basethckselect.name = :base_thickness
        # basethckselect.position(150,30)
        # basethckselect.width = 75
        # basethckselect.value = @@basethick
        # basethckselect.on(:textchange) {|control, value|
        #   @@basethick = control.value
        # }

        start_tol = SKUI::Textbox.new (@@start_tolerance.to_f)
        start_tol.name = :start_tolerance
        start_tol.position(80,100)
        start_tol.width = 50
        start_tol.height = 20
        start_tol.on( :textchange ) { |control|
          @@start_tolerance = control.value.to_s.to_r.to_f
        }
        @group2.add_control start_tol


        end_tol = SKUI::Textbox.new (@@end_tolerance.to_f)
        end_tol.name = :start_tolerance
        end_tol.position(80,75)
        end_tol.width = 50
        end_tol.height = 20
        end_tol.on( :textchange ) { |control|
          @@end_tolerance = control.value.to_s.to_r.to_f
        }
        @group2.add_control end_tol

        st_tol_label = SKUI::Label.new('T - Tolerance', start_tol)
        st_tol_label.position(5, 75)
        @group2.add_control(st_tol_label)

        end_tol_label = SKUI::Label.new('B - Tolerance', end_tol)
        end_tol_label.position(5, 100)
        @group2.add_control(end_tol_label)


        stud_toggle = SKUI::Checkbox.new("Toggle Studs")
        stud_toggle.font = @label_font
        stud_toggle.position(310,20)
        stud_toggle.checked = @@stud_toggle
        @group2.add_control stud_toggle

        north_stud_selct = SKUI::Checkbox.new('N')
        north_stud_selct.font = @label_font
        north_stud_selct.position(232+ss_x,20+ss_y)
        north_stud_selct.checked = @@north_stud_selct
        north_stud_selct.on (:change ) { |control|
          @@north_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(north_stud_selct)

        south_stud_selct = SKUI::Checkbox.new('S')
        south_stud_selct.font = @label_font
        south_stud_selct.position(232+ss_x,175+ss_y)
        south_stud_selct.checked = @@south_stud_selct
        south_stud_selct.on (:change ) { |control|
          @@south_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(south_stud_selct)

        east_stud_selct = SKUI::Checkbox.new('E')
        east_stud_selct.font = @label_font
        east_stud_selct.position(310+ss_x,97+ss_y)
        east_stud_selct.checked = @@east_stud_selct
        east_stud_selct.on (:change ) { |control|
          @@east_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(east_stud_selct)

        west_stud_selct = SKUI::Checkbox.new('W')
        west_stud_selct.font = @label_font
        west_stud_selct.position(145+ss_x,97+ss_y)
        west_stud_selct.checked = @@west_stud_selct
        west_stud_selct.on (:change ) { |control|
          @@west_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(west_stud_selct)

        stud_toggle.on (:change) {|control|
          @@stud_toggle = control.checked?
          north_stud_selct.checked = control.checked?
          @@north_stud_selct = control.checked?
          south_stud_selct.checked = control.checked?
          @@south_stud_selct = control.checked?
          east_stud_selct.checked = control.checked?
          @@east_stud_selct = control.checked?
          west_stud_selct.checked = control.checked?
          @@west_stud_selct = control.checked?
        }


        stud_spacing_control = SKUI::Textbox.new(@@studspacing.to_s.to_r.to_f)
        stud_spacing_control.position(80,140)
        stud_spacing_control.width = 50
        stud_spacing_control.height = 20
        stud_spacing_control.on(:textchange) {|control|
          @@studspacing = control.value.to_s.to_r.to_f
        }
        @group2.add_control(stud_spacing_control)

        ssp_label = SKUI::Label.new('Stud Spacing', stud_spacing_control)
        ssp_label.position(3,142)
        @group2.add_control(ssp_label)

        add_control_buttons(window)# <- Method
      end

      # def add_hss_selections()

      # end

      def add_control_buttons(window)
        btn_ok = SKUI::Button.new( 'OK' ) { |control|
          @@beam_data = find_tube(@@height_class, @@width_class)
          data = {
            height_class:      @@height_class,
            width_class:       @@width_class,
            wall_thickness:    @@wall_thickness,
            data:              @@beam_data,
            base_type:         @@basetype,
            base_thick:        @@basethick,
            stud_spacing:      @@studspacing,
            north_stud_selct:  @@north_stud_selct,
            south_stud_selct:  @@south_stud_selct,
            east_stud_selct:   @@east_stud_selct,
            west_stud_selct:   @@west_stud_selct,
            hss_is_rotated:    @@hss_is_rotated,
            start_tolerance:   @@start_tolerance,
            end_tolerance:     @@end_tolerance,
            hss_type:          @@hss_type
          }
          # p "rotated rectangle = #{@@hss_is_rotated}"
          p @@end_tolerance
          p @@start_tolerance
          control.window.close
          Sketchup.active_model.select_tool EASteelTools::TubeTool.new(data)
        }

        btn_ok.position( 5, -5 )
        btn_ok.font = SKUI::Font.new( 'Comic Sans MS', 14, true )
        window.add_control( btn_ok )

        ####################
        # The close button #
        ####################
        @btn_close = SKUI::Button.new( 'Close' ) { |control|
          clean_images([@sq_image, @rec_image, @rec_image_rot])
          control.window.close
          Sketchup.send_action "selectSelectionTool:"
        }
        @btn_close.position( -5, -5 )
        window.add_control( @btn_close )

        window.default_button = btn_ok
        window.cancel_button = @btn_close

        window.show

        window
      end

      def onKeyDown(key, repeat, flags, view)
        if key == 27
          clean_images([@sq_image, @rec_image, @rec_image_rot])
          @window1.release
          Sketchup.send_action "selectSelectionTool:"
        end
      end

      def clean_images(images)
        images.each do |image|
          image.release
        end
      end

      def set_image1(group, image, x, y)
        img_profile = SKUI::Image.new( image )
        img_profile.position( 175+x, 40+y )
        img_profile.width = 130
        img_profile.height = 130

        group.add_control( img_profile )
        img_profile.visible = (@@width_class.to_f == @@height_class.to_f)
        return img_profile
      end

      def set_image2(group, image, x, y)
        img_profile = SKUI::Image.new( image )
        img_profile.position( 175+x, 40+y )
        img_profile.width = 130
        img_profile.height = 130

        group.add_control( img_profile )
        img_profile.visible = (!@@hss_is_rotated && @@width_class < @@height_class)
        return img_profile
      end

      def set_image3(group, image, x, y)
        img_profile = SKUI::Image.new( image )
        img_profile.position( 175+x, 40+y )
        img_profile.width = 130
        img_profile.height = 130

        group.add_control( img_profile )
        img_profile.visible = (@@hss_is_rotated && @@width_class < @@height_class)
        return img_profile
      end

      def set_groups(window)
        #Creates the top group box that holds the dropdown lists of the
        @group1 = SKUI::Groupbox.new( 'Select HSS' )
        @group1.position( 5, 5 )
        @group1.right = 5
        @group1.height = 75
        window.add_control( @group1 )

        @group2 = SKUI::Groupbox.new( 'HSS Options' )
        @group2.position( 20, 95 )
        @group2.right = 20
        @group2.width = 360
        @group2.height = 200
        window.add_control( @group2 )
      end

      def self.close
        @window1.release
      end

      # def deactivate(view)
      #   @window1.close
      #   Sketchup.send_action "selectSelectionTool:"
      #   view.invalidate
      # end

    end #class

  end #module
end #module