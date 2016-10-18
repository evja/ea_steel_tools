module EA_Extensions623
  module EASteelTools
    extension_path = File.dirname( __FILE__ )
    skui_path = File.join( extension_path, 'SKUI' )
    load File.join( skui_path, 'embed_skui.rb' )
    ::SKUI.embed_in( self )
    # SKUI module is now available under EA_Steel_Tools::SKUI

    class RolledDialog
      include BeamLibrary
      @@state = 0

      def validate_selection(selection)
        if not selection.class == Sketchup::Edge && selection.curve.class == Sketchup::ArcCurve
          UI.messagebox("please select 1 arc as a path for the rolled steel")
          Sketchup.send_action "selectSelectionTool:"
          return false
        end
        return true # Pass the test
      end

      def activate
        @model = Sketchup.active_model
        @entities = @model.active_entities
        @model.start_operation("Rolled Steel", true)
        @path = @model.selection
        sel = @path[0]
        @selection_count = 0


        if @@state == 0
          @@beam_data         = {}             #Hash   {:d=>4.16, :bf=>4.06, :tf=>0.345, :tw=>0.28, :r=>0.2519685039370079, :width_class=>4}"
          @@beam_name         = ''             #String 'W(height_class)X(weight_per_foot)'
          @@height_class      = ''             #String 'W(number)'
          @@placement         = 'BO'           #String 'TOP' or 'BOTTOM'
          @@has_holes         = true           #Boolean
          @@web_holes         = true
          @@flange_holes      = true
          # @@hole_spacing      = 16             #Integer 16 or 24 # See problem on segment length
          @@cuts_holes        = false          #Boolean
          @@has_stiffeners    = true           #Boolean
          @@has_shearplates   = true           #Boolean
          @@stiff_thickness   = '1/4'          #String '1/4' or '3/8' or '1/2'
          @@shearpl_thickness = '1/2'          #String '3/8' or '1/2' or '3/4'
          @@roll_type         = 'EASY'         #String 'EASY' or 'HARD'
          @@radius_offset     = -0.5           # float or integer. This is the distance of offset the new arc will be drawn at
          # @@segment_length    = 8.0          # This is not a good idea as it could throw off the alignment of the web holes and the stagger
          @@state = 1
        end

        @options = {
          :title           => 'Wide Flange Steel v1.0', #change the version number with ever y cahnge
          :preferences_key => 'WFS',
          :width           => 400,
          :height          => 480,
          :resizable       => false
        }
        if @path.any?
          unless validate_selection sel
            return
          end
          run_dialog
          @pre_selected_arc = true
        else
          #prompt User to select an arc and validate it.
          @status_text = "Please select an arc to use as the rolled steel path"
          Sketchup.status_text = @status_text
          make_cursor
        end

      end

      def make_cursor
        cursor = Sketchup.find_support_file("icons/wfs_icon_rolled_select.png", "Plugins/ea_steel_tools")
        @select_path_cursor = UI.create_cursor(cursor, 0, 0)
      end

      def onSetCursor
        UI.set_cursor(@select_path_cursor.to_i)
        Sketchup.active_model.active_view.invalidate
      end

      def onLButtonUp(flags, x, y, view)
        if @ready_to_select == true
          run_dialog
          @selection_count = 2
        end
      end

      # This is used to dynamically highlight/select the line or curve when you move the mouse over it.
      def onMouseMove(flags, x, y, view)
        unless @pre_selected_arc
          if @selection_count < 2
            ph = view.pick_helper
            num = ph.do_pick(x,y)
            @best = ph.best_picked
            if (@best)
              if @best.class == Sketchup::Edge && @best.curve.class == Sketchup::ArcCurve
                all_best = @best.all_connected
                if @selection_count == 0
                  Sketchup.active_model.selection.clear
                  Sketchup.active_model.selection.add( @best.curve.edges )
                  @ready_to_select = true
                end
              else
                Sketchup.active_model.selection.clear
                @ready_to_select = false
              end
            else
              Sketchup.active_model.selection.clear
            end
            view.invalidate
          end
        end
      end

      def run_dialog
        add_parent_window(@options)
        add_beam_selections
        add_rolltypes
        add_path_selection_group
        add_options_group
        initiate_dialog
      end

      def add_parent_window(options)
        @window = SKUI::Window.new( options )

        # These events doesn't trigger correctly when Firebug Lite
        # is active because it introduces frames that interfere with
        # the focus notifications.
        @window.on( :focus )  { puts 'Window Focus' }
        @window.on( :blur )   { puts 'Window Blur' }
        @window.on( :resize ) { |window, width, height|
          puts "Window Resize(#{width}, #{height})"
        }
      end

      def add_beam_selections
        #Creates the top group box that holds the dropdown lists of the
        @group = SKUI::Groupbox.new( 'Select Beam' )
        @group.position( 5, 5 )
        @group.right = 5
        @group.height = 100
        @window.add_control( @group )

        hc_list_label = SKUI::Label.new('Height Class')
        hc_list_label.position(10,25)

        beam_size_label = SKUI::Label.new('Beam Size')
        beam_size_label.position(10,55)
        @group.add_control( hc_list_label )
        @group.add_control( beam_size_label )

        list = all_height_classes
        height_class_dropdown = SKUI::Listbox.new( list )
        @@height_class.empty? ? @@height_class = (height_class_dropdown.value = height_class_dropdown.items.sample) : height_class_dropdown.value = height_class_dropdown.items.grep(@@height_class).first.to_s
        height_class_dropdown.position( 85, 25 )
        height_class_dropdown.width = 170

        list = all_beams_in(@@height_class)
        beam_size_dropdown = SKUI::Listbox.new( list )
        @@beam_name.empty? ? @@beam_name = (beam_size_dropdown.value = beam_size_dropdown.items.first) : @@beam_name = (beam_size_dropdown.value = beam_size_dropdown.items.grep(@@beam_name).first.to_s)
        beam_size_dropdown.position( 85, 55 )
        beam_size_dropdown.width = 170

        @group.add_control( beam_size_dropdown )

        height_class_dropdown.on( :change ) { |control, value|
          @@height_class = control.value
          list = all_beams_in(control.value)
          beam_size_dropdown = SKUI::Listbox.new( list )
          @@beam_name = beam_size_dropdown.value = beam_size_dropdown.items.first
          beam_size_dropdown.position( 85, 55 )
          beam_size_dropdown.width = 170
          @group.add_control( beam_size_dropdown )
          beam_size_dropdown.on( :change ) { |control, value|
            @@beam_name = control.value
          }
        }
        @group.add_control( height_class_dropdown )

        beam_size_dropdown.on( :change ) { |control, value|
          @@beam_name = control.value
        }
      end


      def add_rolltypes

        roll_type = SKUI::Label.new( 'Roll Type' )
        roll_type.position(290, 15)
        @group.add_control( roll_type )

        path = File.join( SKUI::PATH, '..', 'icons' )
        file = File.join( path, 'wfs_icon_rolled_hard.png' )

        img_hardroll = SKUI::Image.new( file )
        img_hardroll.position( 280, 40 )
        img_hardroll.width = 24
        @group.add_control( img_hardroll )

        path = File.join( SKUI::PATH, '..', 'icons' )
        file = File.join( path, 'wfs_icon_rolled.png' )

        img_easyroll = SKUI::Image.new( file )
        img_easyroll.position( 320, 40 )
        img_easyroll.width = 24
        @group.add_control( img_easyroll )


        sel_roll_hard = SKUI::RadioButton.new('')
        sel_roll_hard.position(285,70)
        sel_roll_hard.checked = true if @@roll_type == 'HARD'
        sel_roll_hard.on ( :change ) { |control|
          @@roll_type = 'HARD' if control.checked?
        }
        @group.add_control( sel_roll_hard )

        sel_roll_easy = SKUI::RadioButton.new('')
        sel_roll_easy.position(325,70)
        sel_roll_easy.checked = true if @@roll_type == 'EASY'
        sel_roll_easy.on ( :change ) { |control|
          @@roll_type = 'EASY' if control.checked?
        }
        @group.add_control( sel_roll_easy )
      end

      def add_path_selection_group
        group2 = SKUI::Groupbox.new( 'Path Position' )
        group2.position( 58, 103 )
        group2.right = 20
        group2.width = 300
        group2.height = 200
        @window.add_control( group2 )

        path = File.join( SKUI::PATH, '..', 'icons' )
        file = File.join( path, 'profile2.png' )

        label_font = SKUI::Font.new( 'Comic Sans MS', 8, true )

        img_profile = SKUI::Image.new( file )
        img_profile.position( 28, 32 )
        img_profile.width = 200
        img_profile.height = 130
        group2.add_control( img_profile )

        t_center_select = SKUI::RadioButton.new ('Center')
        t_center_select.font = label_font
        t_center_select.position(120, 20)
        t_center_select.checked = true if @@placement == 'TC'
        t_center_select.on (:change ) { |control|
          @@placement = 'TC' if control.checked?
        }
        group2.add_control( t_center_select )

        t_out_select = SKUI::RadioButton.new ('Outside')
        t_out_select.font = label_font
        t_out_select.position(50, 20)
        t_out_select.checked = true if @@placement == 'TO'
        t_out_select.on (:change ) { |control|
          @@placement = 'TO' if control.checked?
        }
        group2.add_control( t_out_select )

        t_in_select = SKUI::RadioButton.new ('Inside')
        t_in_select.font = label_font
        t_in_select.position(195, 20)
        t_in_select.checked = true if @@placement == 'TI'
        t_in_select.on (:change ) { |control|
          @@placement = 'TI' if control.checked?
        }
        group2.add_control( t_in_select )

        b_center_select = SKUI::RadioButton.new ('Center')
        b_center_select.font = label_font
        b_center_select.position(120, 160)
        b_center_select.checked = true if @@placement == 'BC'
        b_center_select.on ( :change ) { |control|
          @@placement = 'BC' if control.checked?
        }
        group2.add_control ( b_center_select )

        b_out_select = SKUI::RadioButton.new ('Outside')
        b_out_select.font = label_font
        b_out_select.position(50, 160)
        b_out_select.checked = true if @@placement == 'BO'
        b_out_select.on (:change ) { |control|
          @@placement = 'BO' if control.checked?
        }
        group2.add_control( b_out_select )

        b_in_select = SKUI::RadioButton.new ('Inside')
        b_in_select.font = label_font
        b_in_select.position(195, 160)
        b_in_select.checked = true if @@placement == 'BI'
        b_in_select.on (:change ) { |control|
          @@placement = 'BI' if control.checked?
        }
        group2.add_control( b_in_select )
      end

      def add_options_group
        color = Sketchup::Color.new "White"

        group3 = SKUI::Groupbox.new( 'Options' )
        group3.position( 5, 295)
        group3.right = 5
        group3.height = 130
        @window.add_control( group3 )

        container_stiff = SKUI::Container.new
        container_stiff.foreground_color = color
        container_stiff.stretch( 0, 0, 0, 0 )
        group3.add_control( container_stiff )

        container_shear = SKUI::Container.new
        container_shear.foreground_color = color
        container_shear.stretch( 0, 0, 0, 0 )
        container_stiff.add_control( container_shear )

        # create 2 radio buttins for choosing if it has web holes and or flange holes
        sel_flange = SKUI::Checkbox.new("Flange Holes")
        sel_flange.position(110,20)
        sel_flange.checked = @@flange_holes
        sel_flange.on(:change) {|control|
          @@flange_holes = control.checked?
        }
        sel_flange.visible = @@has_holes
        group3.add_control(sel_flange)

        sel_web = SKUI::Checkbox.new("Web Holes")
        sel_web.position(205,20)
        sel_web.checked = @@web_holes
        sel_web.on(:change) {|control|
          @@web_holes = control.checked?
        }
        sel_web.visible = @@has_holes
        group3.add_control(sel_web)

        chk_cut_holes = SKUI::Checkbox.new( 'Cut Holes?' )
        chk_cut_holes.position( 290, 20 )
        group3.add_control( chk_cut_holes )
        chk_cut_holes.visible = @@has_holes
        chk_cut_holes.checked = @@cuts_holes
        chk_cut_holes.on (:change ) { |control|
          @@cuts_holes = control.checked?
        }

        chk_holes = SKUI::Checkbox.new( 'Holes' )
        chk_holes.position( 10, 20 )
        chk_holes.checked = @@has_holes
        chk_holes.on( :change ) { |control|
          @@has_holes                = control.checked?
          chk_cut_holes.visible      = @@has_holes
          sel_flange.visible         = @@has_holes
          sel_web.visible            = @@has_holes
          # options_list_label.visible = @@has_holes
          # options_list_label.visible = @@has_holes
        }
        group3.add_control( chk_holes )

        # create 3 radio buttons for the stiffener thickness
        sel_stiff_thck_1 = SKUI::RadioButton.new("1/4\"")
        sel_stiff_thck_1.position(110, 45)
        sel_stiff_thck_1.checked = true if @@stiff_thickness == '1/4'
        sel_stiff_thck_1.on(:change) {|control|
          @@stiff_thickness = '1/4' if control.checked?
        }
        sel_stiff_thck_1.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_1)

        sel_stiff_thck_4 = SKUI::RadioButton.new("5/16\"")
        sel_stiff_thck_4.position(170, 45)
        sel_stiff_thck_4.checked = true if @@stiff_thickness == '5/16'
        sel_stiff_thck_4.on(:change) {|control|
          @@stiff_thickness = '5/16' if control.checked?
        }
        sel_stiff_thck_4.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_4)

        sel_stiff_thck_2 = SKUI::RadioButton.new("3/8\"")
        sel_stiff_thck_2.position(230, 45)
        sel_stiff_thck_2.checked = true if @@stiff_thickness == '3/8'
        sel_stiff_thck_2.on(:change) {|control|
          @@stiff_thickness = '3/8' if control.checked?
        }
        sel_stiff_thck_2.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_2)

        sel_stiff_thck_3 = SKUI::RadioButton.new("1/2\"")
        sel_stiff_thck_3.position(290, 45)
        sel_stiff_thck_3.checked = true if @@stiff_thickness == '1/2'
        sel_stiff_thck_3.on(:change) {|control|
          @@stiff_thickness = '1/2' if control.checked?
        }
        sel_stiff_thck_3.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_3)

        chk_stiffeners = SKUI::Checkbox.new( 'Stiffeners' )
        chk_stiffeners.position( 10, 45 )
        chk_stiffeners.checked = @@has_stiffeners
        chk_stiffeners.on( :change ) { |control|
          @@has_stiffeners = chk_stiffeners.checked?
          sel_stiff_thck_4.visible = @@has_stiffeners
          sel_stiff_thck_3.visible = @@has_stiffeners
          sel_stiff_thck_2.visible = @@has_stiffeners
          sel_stiff_thck_1.visible = @@has_stiffeners
        }
        container_stiff.add_control( chk_stiffeners )

        # create 3 radio buttons for the shearplate thickness
        sel_shear_thck_1 = SKUI::RadioButton.new("3/8\"")
        sel_shear_thck_1.position(110, 70)
        sel_shear_thck_1.checked = true if @@shearpl_thickness == '3/8'
        sel_shear_thck_1.on(:change) {|control|
          @@shearpl_thickness = '3/8' if control.checked?
        }
        sel_shear_thck_1.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_1)

        sel_shear_thck_2 = SKUI::RadioButton.new("1/2\"")
        sel_shear_thck_2.position(170, 70)
        sel_shear_thck_2.checked = true if @@shearpl_thickness == '1/2'
        sel_shear_thck_2.on(:change) {|control|
          @@shearpl_thickness = '1/2' if control.checked?
        }
        sel_shear_thck_2.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_2)

        sel_shear_thck_3 = SKUI::RadioButton.new("5/8\"")
        sel_shear_thck_3.position(230, 70)
        sel_shear_thck_3.checked = true if @@shearpl_thickness == '5/8'
        sel_shear_thck_3.on(:change) {|control|
          @@shearpl_thickness = '5/8' if control.checked?
        }
        sel_shear_thck_3.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_3)

        sel_shear_thck_4 = SKUI::RadioButton.new("3/4\"")
        sel_shear_thck_4.position(290, 70)
        sel_shear_thck_4.checked = true if @@shearpl_thickness == '3/4'
        sel_shear_thck_4.on(:change) {|control|
          @@shearpl_thickness = '3/4' if control.checked?
        }
        sel_shear_thck_4.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_4)

        chk_shearplates = SKUI::Checkbox.new( 'Shear Plates' )
        chk_shearplates.position( 10, 70 )
        chk_shearplates.checked = @@has_shearplates
        chk_shearplates.on( :change ) { |control|
          @@has_shearplates = chk_shearplates.checked?
          sel_shear_thck_4.visible = @@has_shearplates
          sel_shear_thck_3.visible = @@has_shearplates
          sel_shear_thck_2.visible = @@has_shearplates
          sel_shear_thck_1.visible = @@has_shearplates
        }
        container_shear.add_control( chk_shearplates )

        offset = SKUI::Textbox.new( @@radius_offset.to_f )
        offset.name = :radius_offset
        offset.position(90, 90)
        offset.width = 50
        offset.height = 20
        offset.on( :textchange ) {|control|
          @@radius_offset = control.value.to_f
        }
        group3.add_control(offset)

        lbl_input = SKUI::Label.new('Radius Offset:', offset )
        lbl_input.position(10, 92)
        group3.add_control( lbl_input )
      end

###############################################################################
        # seg_length_input = SKUI::Textbox.new( @@segment_length )
        # seg_length_input.name = :segment_length
        # seg_length_input.position(255, 90)
        # seg_length_input.width = 50
        # seg_length_input.height = 20
        # seg_length_input.on( :textchange ) {|control|
        #   @@segment_length = control.value
        # }
        # group3.add_control(seg_length_input)

        # lbl_seg_input = SKUI::Label.new('Segment Length:', seg_length_input )
        # lbl_seg_input.position(160, 92)
        # group3.add_control( lbl_seg_input )

        ########################################################################
        ########################################################################
      def initiate_dialog
        btn_ok = SKUI::Button.new( 'OK' ) { |control|
          @@beam_data = find_beam(@@height_class, @@beam_name)
          data = {
            name:              @@beam_name,
            height_class:      @@height_class,
            data:              @@beam_data,
            placement:         @@placement,
            has_holes:         @@has_holes,
            # stagger:           @@hole_spacing,
            flange_holes:      @@flange_holes,
            web_holes:         @@web_holes,
            cuts_holes:        @@cuts_holes,
            stiffeners:        @@has_stiffeners,
            shearplates:       @@has_shearplates,
            stiff_thickness:   @@stiff_thickness,
            shearpl_thickness: @@shearpl_thickness,
            roll_type:         @@roll_type,
            radius_offset:     @@radius_offset,
            # segment_length:    @@segment_length
          }
          Sketchup.active_model.select_tool EASteelTools::RolledSteel.new(data)
          Sketchup.active_model.commit_operation
          control.window.close
        }

        btn_ok.position( 5, -5 )
        btn_ok.font = SKUI::Font.new( 'Comic Sans MS', 14, true )
        @window.add_control( btn_ok )

        ####################
        # The close button #
        ####################
        btn_close = SKUI::Button.new( 'Close' ) { |control|
          control.window.close
          @dialog = control.window
          Sketchup.send_action "selectSelectionTool:"
        }
        btn_close.position( -5, -5 )
        @window.add_control( btn_close )

        @window.default_button = btn_ok
        @window.cancel_button = btn_close

        @window.show

        @window
      end

      def self.close
        @window.release
      end

    end #class

  end #module
end #module