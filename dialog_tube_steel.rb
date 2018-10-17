module EA_Extensions623
  module EASteelTools
    extension_path = File.dirname( __FILE__ )
    skui_path = File.join( extension_path, 'SKUI' )
    load File.join( skui_path, 'embed_skui.rb' )
    ::SKUI.embed_in( self )
    # SKUI module is now available under EA_Steel_Tools::SKUI

    class HssDialog
      include HSSLibrary
      BASETYPES = ["SQ","OC","IL","IC","EX","DR","DL","DI"]

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
        end

        @img_path = File.join( SKUI::PATH, '..', 'icons' )
        @img_file1 = File.join( @img_path, 'hss_section.png' )
        @img_file2 = File.join( @img_path, 'hss_rec_section.png' )

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

        @rec_image = set_image2(@group2, @img_file2, ss_x, ss_y)
        @sq_image = set_image1(@group2, @img_file1, ss_x, ss_y)

        # @sq_image.visible = @@width_class == @height_class
        # @rec_image.visible = @@width_class < @@height_class

        hc_list_label = SKUI::Label.new('Size')
        hc_list_label.position(10,25)

        label1 = SKUI::Label.new('X')
        label1.position(110,30)
        @group1.add_control( label1 )

        label2 = SKUI::Label.new('X')
        label2.position(190,30)
        @group1.add_control( label2 )
        @group1.add_control( hc_list_label )

        list = all_height_classes
        height_class_dropdown = SKUI::Listbox.new( list )
        @@height_class.empty? ? @@height_class = (height_class_dropdown.value = height_class_dropdown.items.sample) : height_class_dropdown.value = height_class_dropdown.items.grep(@@height_class).first.to_s
        height_class_dropdown.position( 50, 25 )
        height_class_dropdown.width = 50


        list2 = all_tubes_in(@@height_class)
        width_size_dropdown = SKUI::Listbox.new( list2 )
        @@width_class.empty? ? @@width_class = (width_size_dropdown.value = width_size_dropdown.items.first) : @@width_class = (width_size_dropdown.value = width_size_dropdown.items.grep(@@width_class).first.to_s)
        width_size_dropdown.position( 130, 25 )
        width_size_dropdown.width = 50

        @group1.add_control( width_size_dropdown )

        # list3 = cuurent_selection_wall_thickness(@@width_class)
        list3 = all_guage_options_in(@@height_class, @@width_class)
        # p list3
        wall_thickness_dropdown = SKUI::Listbox.new( list3 )
        @@wall_thickness.empty? ? @@wall_thickness = (@@wall_thickness = wall_thickness_dropdown.items[1]) : (@@wall_thickness)
        wall_thickness_dropdown.value = @@wall_thickness
        wall_thickness_dropdown.position( 210, 25 )
        wall_thickness_dropdown.width = 75
        wall_thickness_dropdown.on(:change) { |control, value|
          @@wall_thickness = control.value
        }

        height_class_dropdown.on( :change ) { |control, value|
          @@height_class = control.value
          list2 = all_tubes_in(control.value)
          width_size_dropdown = SKUI::Listbox.new( list2 )
          @@width_class = width_size_dropdown.value = width_size_dropdown.items.first
          width_size_dropdown.position( 130, 25 )
          width_size_dropdown.width = 50
          @group1.add_control( width_size_dropdown )
          @sq_image.visible = (control.value.to_i == @@width_class.to_i)
          @rec_image.visible = (control.value.to_i > @@width_class.to_i)

          list3 = all_guage_options_in(@@height_class, @@width_class)
          p list3
          wall_thickness_dropdown = SKUI::Listbox.new( list3 )
          # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.first)
          wall_thickness_dropdown.position( 210, 25 )
          wall_thickness_dropdown.width = 75
          wall_thickness_dropdown.on(:change) { |control, value|
            @@wall_thickness = control.value
          }
          @group1.add_control( wall_thickness_dropdown )

          width_size_dropdown.on( :change ) { |control, value|
            @@width_class = control.value
            @sq_image.visible = (control.value.to_i == @@height_class.to_i)
            @rec_image.visible = (control.value.to_i < @@height_class.to_i)
            list3 = all_guage_options_in(@@height_class, @@width_class)
            wall_thickness_dropdown = SKUI::Listbox.new( list3 )
            # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.sample)
            wall_thickness_dropdown.position( 210, 25 )
            wall_thickness_dropdown.width = 75
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
          p control.value
          @sq_image.visible = (control.value.to_i == @@height_class.to_i)
          @rec_image.visible = (control.value.to_i < @@height_class.to_i)
        }


        # path = File.join( SKUI::PATH, '..', 'icons' )
        # file = File.join( path, 'profile2.png' )

        label_font = SKUI::Font.new( 'Comic Sans MS', 8, true )

        baseselect = SKUI::Listbox.new(BASETYPES)
        baseselect.position(30,30)
        baseselect.width = 75
        @@basetype.empty? ? @@basetype = (baseselect.value = BASETYPES.first) : baseselect.value = @@basetype
        baseselect.on(:change) { |control, value|
          @@basetype = control.value
        }

        @group2.add_control(baseselect)

        basethckselect = SKUI::Textbox.new(@@basethick)
        basethckselect.name = :base_thickness
        basethckselect.position(150,30)
        basethckselect.width = 75
        basethckselect.value = @@basethick
        basethckselect.on(:textchange) {|control, value|
          @@basethick = control.value
        }
        
        stud_toggle = SKUI::Checkbox.new("Toggle Studs")
        stud_toggle.font = label_font
        stud_toggle.position(320,20)
        stud_toggle.checked = @@stud_toggle

        @group2.add_control stud_toggle

        north_stud_selct = SKUI::Checkbox.new('N')
        north_stud_selct.font = label_font
        north_stud_selct.position(232+ss_x,20+ss_y)
        north_stud_selct.checked = @@north_stud_selct
        north_stud_selct.on (:change ) { |control|
          @@north_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(north_stud_selct)

        south_stud_selct = SKUI::Checkbox.new('S')
        south_stud_selct.font = label_font
        south_stud_selct.position(232+ss_x,175+ss_y)
        south_stud_selct.checked = @@south_stud_selct
        south_stud_selct.on (:change ) { |control|
          @@south_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(south_stud_selct)

        east_stud_selct = SKUI::Checkbox.new('E')
        east_stud_selct.font = label_font
        east_stud_selct.position(310+ss_x,97+ss_y)
        east_stud_selct.checked = @@east_stud_selct
        east_stud_selct.on (:change ) { |control|
          @@east_stud_selct = control.checked?
          stud_toggle.checked = false if not control.checked?
        }

        @group2.add_control(east_stud_selct)

        west_stud_selct = SKUI::Checkbox.new('W')
        west_stud_selct.font = label_font
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

        ssp_x = 10
        ssp_y = 165

        ssp_label = SKUI::Label.new('Stud Spacing')
        ssp_label.position(0+ssp_x, 0+ssp_y)
        @group2.add_control(ssp_label
          )
        # create 2 radio buttins for 16" and 24"
        sel_16 = SKUI::RadioButton.new("16\"")
        sel_16.position(100+ssp_x,0+ssp_y)
        sel_16.checked = true if @@studspacing == 16
        sel_16.on(:change) {|control|
          @@studspacing = 16 if control.checked?
        }
        @group2.add_control(sel_16)

        sel_24 = SKUI::RadioButton.new("24\"")
        sel_24.position(145+ssp_x,0+ssp_y)
        sel_24.checked = true if @@studspacing == 24
        sel_24.on(:change) {|control|
          @@studspacing = 24 if control.checked?
        }
        @group2.add_control(sel_24)



        ########################################################################
        ########################################################################

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
            west_stud_selct:   @@west_stud_selct
          }
          control.window.close
          Sketchup.active_model.select_tool EASteelTools::TubeTool.new(data)
        }

        btn_ok.position( 5, -5 )
        btn_ok.font = SKUI::Font.new( 'Comic Sans MS', 14, true )
        window.add_control( btn_ok )

        ####################
        # The close button #
        ####################
        btn_close = SKUI::Button.new( 'Close' ) { |control|
          control.window.close
          Sketchup.send_action "selectSelectionTool:"
        }
        btn_close.position( -5, -5 )
        window.add_control( btn_close )

        window.default_button = btn_ok
        window.cancel_button = btn_close

        window.show

        window
      end

      def set_image1(group, image, x, y)
        img_profile = SKUI::Image.new( image )
        img_profile.position( 175+x, 40+y )
        img_profile.width = 130
        img_profile.height = 130


        group.add_control( img_profile )
        img_profile.visible = (@@width_class.to_i == @@height_class.to_i)

        return img_profile
      end

      def set_image2(group, image, x, y)
        img_profile = SKUI::Image.new( image )
        img_profile.position( 175+x, 40+y )
        img_profile.width = 130
        img_profile.height = 130


        group.add_control( img_profile )

        img_profile.visible = (@@width_class.to_i < @@height_class.to_i)

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