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
          @@stud_spacing          = 16  #Integer 16 or 24
          @@state                 = 1   #Integer()
        end

        options = {
          :title           => "Tube Steel #{VERSION_NUM}",
          :preferences_key => 'TS',
          :width           => 416,
          :height          => 475,
          :resizable       => false
        }

        window = SKUI::Window.new( options )
        @window1 = window

        # These events doesn't trigger correctly when Firebug Lite
        # is active because it introduces frames that interfere with
        # the focus notifications.
        window.on( :focus )  { puts 'Window Focus' }
        window.on( :blur )   { puts 'Window Blur' }
        window.on( :resize ) { |window, width, height|
          # puts "Window Resize(#{width}, #{height})"
        }

        #Creates the top group box that holds the dropdown lists of the
        group = SKUI::Groupbox.new( 'Select HSS' )
        group.position( 5, 5 )
        group.right = 5
        group.height = 75
        window.add_control( group )

        hc_list_label = SKUI::Label.new('Size')
        hc_list_label.position(10,25)

        label1 = SKUI::Label.new('X')
        label1.position(110,30)
        group.add_control( label1 )

        label2 = SKUI::Label.new('X')
        label2.position(190,30)
        group.add_control( label2 )
        group.add_control( hc_list_label )

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

        group.add_control( width_size_dropdown )

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
          group.add_control( width_size_dropdown )

          list3 = all_guage_options_in(@@height_class, @@width_class)
          p list3
          wall_thickness_dropdown = SKUI::Listbox.new( list3 )
          # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.first)
          wall_thickness_dropdown.position( 210, 25 )
          wall_thickness_dropdown.width = 75
          wall_thickness_dropdown.on(:change) { |control, value|
            @@wall_thickness = control.value
          }
          group.add_control( wall_thickness_dropdown )

          width_size_dropdown.on( :change ) { |control, value|
            @@width_class = control.value
            list3 = all_guage_options_in(@@height_class, @@width_class)
            p list3
            wall_thickness_dropdown = SKUI::Listbox.new( list3 )
            # @@wall_thickness = (wall_thickness_dropdown.value = wall_thickness_dropdown.items.sample)
            wall_thickness_dropdown.position( 210, 25 )
            wall_thickness_dropdown.width = 75
            group.add_control( wall_thickness_dropdown )
            wall_thickness_dropdown.on(:change) { |control, value|
              @@wall_thickness = control.value
            }
          }
        }
        group.add_control( height_class_dropdown )

        group.add_control( wall_thickness_dropdown )

        width_size_dropdown.on( :change ) { |control, value|
          @@width_class = control.value
        }

        # chk_force_studs = SKUI::Checkbox.new( 'Force Studs' )
        # chk_force_studs.position( 300, 20 )
        # chk_force_studs.checked = @@force_studs
        # chk_force_studs.on( :change ) { |control|
        #   @@force_studs                = control.checked?
        # }
        # group.add_control( chk_force_studs )
        ##################################################################################
        ##################################################################################

        group2 = SKUI::Groupbox.new( 'Baseplate Selection' )
        group2.position( 20, 95 )
        group2.right = 20
        group2.width = 360
        group2.height = 200
        window.add_control( group2 )

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

        group2.add_control(baseselect)

        basethckselect = SKUI::Textbox.new(@@basethick)
        basethckselect.name = :base_thickness
        basethckselect.position(150,30)
        basethckselect.width = 75
        basethckselect.value = @@basethick
        basethckselect.on(:textchange) {|control, value|
          @@basethick = control.value
        }

        group2.add_control(basethckselect)


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
            base_thick:        @@basethick
            # placement:         @@placement,
            # has_holes:         @@has_holes,
            # stagger:           @@hole_spacing,
            # cuts_holes:        @@cuts_holes,
            # stiffeners:        @@has_stiffeners,
            # shearplates:       @@has_shearplates,
            # stiff_thickness:   @@stiff_thickness,
            # shearpl_thickness: @@shearpl_thickness,
            # force_studs:       @@force_studs
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