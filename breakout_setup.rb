# page1 = {name: "Perspective", use_camera?: true, style: "Standard.style",  }

module EA_Extensions623
  module EASteelTools
    require 'sketchup'

    module BreakoutSetup

      def self.set_styles(model)
        style1_file = Sketchup.find_support_file('Standard.style', "Plugins/#{FNAME}/Models/Styles/")
        style2_file = Sketchup.find_support_file('X-Ray.style', "Plugins/#{FNAME}/Models/Styles/")
        model.styles.add_style style1_file, false
        model.styles.add_style style1_file, true
        model.styles.purge_unused
        style1 = model.styles.first
        style2 = model.styles[-1]
        style1.description = 'Standard'
        style2.description = 'X-Ray'
        return model.styles
      end

      def self.set_scenes(model)
        scenes = ["Perspective", "Front", "Plates", "X-Ray"]
        pages = model.pages
        scenes.each {|scene| pages.add scene}
        view = model.active_view
        pages.selected_page = pages[0]
        pages[-1].use_style = model.styles['X-Ray']
        pages.selected_page = pages[-1]
        Sketchup.active_model.rendering_options["ModelTransparency"] = true

        pg = pages[0]
        pages.selected_page = pg
        cam = pg.camera
        eye = [182, -138, 45]
        target = [0,0,0]
        std_cam = Sketchup::Camera.new eye, target, Z_AXIS
        view.camera = std_cam
        pg.update(1)

        Sketchup.active_model.active_view.zoom_extents
        return pages
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