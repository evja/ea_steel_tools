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
        style1 = model.styles.first
        style2 = model.styles[-1]
        style1.description = 'Standard'
        return model.styles
      end

      def self.set_scenes(model)
        scenes = ["Part", "Plates"]
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

        view.zoom_extents
        pg.update(1)

        pg2 = @pages[1]
        @pages.selected_page = pg2
        eye2 = [0,-1,0]
        target2 = [0,0,0]
        plt_cam = Sketchup::Camera.new eye2, target2, Z_AXIS
        plt_cam.perspective = false
        view.camera = plt_cam
        pg2.use_camera = true
        pg2.update(1)

        @pages.selected_page = pg
        view.camera = std_cam

        return @pages
      end

      def self.set_layers(model)
        layers = model.layers
        if layers[' Bolts'] != nil
          bolt_layer = layers[' Bolts']
          bolt_layer.visible = false
          @pages[0].update(32)
          @pages[1].update(32)
        end
        @plate_layer = layers.add 'Breakout_Plates'
        @part_layer = layers.add 'Breakout_Part'
      end

      def set_up_scene(page)
      end

      def self.set_cameras(model)

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