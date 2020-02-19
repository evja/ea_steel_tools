# page1 = {name: "Perspective", use_camera?: true, style: "Standard.style",  }

module EA_Extensions623
  module EASteelTools
    require 'sketchup'

    module BreakoutSetup

      def self.set_styles(model)
        style1_file = Sketchup.find_support_file('Standard.style', "Plugins/#{FNAME}/Models/Styles/")
        model.styles.add_style style1_file, false
        model.styles.add_style style1_file, true
        model.styles.purge_unused
        model.options["PageOptions"]["ShowTransition"]=true
        style1 = model.styles.first
        style2 = model.styles[-1]
        style1.description = 'Standard'
        return model.styles
      end

      def self.set_scenes(model)
        Sketchup.active_model.start_operation("Scene Set", true, true, true)
        scenes = ["Part", "Plates", "DXF"]
        @pages = model.pages
        scenes.each {|scene| @pages.add scene}
        view = model.active_view
        Sketchup.active_model.rendering_options["ModelTransparency"] = true

        pg = @pages[0]
        @pages.selected_page = pg
        eye1 = [102, -139, 50]
        target1 = [0,0,0]
        std_cam = Sketchup::Camera.new eye1, target1, Z_AXIS
        view.camera = std_cam

        @pages.each {|page| page.transition_time = 0.0; page.update(1)} #CHANGE FOR THE SCENE TRANSITION TIME
        view.zoom_extents
        pg.update(1)

        #Page2 is the Plates View
        pg2 = @pages[1]
        @pages.selected_page = pg2
        eye2 = [10,-10,10]
        target2 = [0,0,0]
        plt_cam = Sketchup::Camera.new eye2, target2, Z_AXIS
        plt_cam.perspective = false
        view.camera = plt_cam
        pg2.use_camera = true
        view.zoom_extents
        pg2.update(1)
        Sketchup.active_model.commit_operation
        return @pages
      end

      def self.set_layers(model)
        layers = model.layers
        bolt_layers = layers.collect{|l| l.name}.grep(/Bolt/)
        if bolt_layers.any?
          bolt_layers.each {|lr| layers[lr].visible = false}
          @pages[0].update(32)
          @pages[1].update(32)
        end

        # layers.each do |lyr|
        #   case lyr
        #   when

        #   end
        # end


        @plate_layer = layers.add(BREAKOUT_LAYERS.grep(/Plates/)[0])
        @part_layer = layers.add(BREAKOUT_LAYERS.grep(/Part/)[0])
        @dxf_layer = layers.add(BREAKOUT_LAYERS.grep(/DXF/)[0])
      end

      def self.set_materials(model)
        material_files = Sketchup.find_support_files('skm', 'Plugins/ea_steel_tools/Colors')
        material_files.each do |m_file|
          model.materials.load(m_file)
        end
      end

    end #BreakoutScenes

  end #EASteelTools
end #EA_Extensions623