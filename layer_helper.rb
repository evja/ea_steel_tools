module EA_Extensions623
  module EASteelTools

    class LayerHelper
      def initialize
        model = Sketchup.active_model
        sel = model.selection
        layers = model.layers.sort

        layer_list = layers.map {|l| l.name}
        # p layer_list
        layer_list2 = ""

        layer_list.each_with_index do |l,i|
          if l == layer_list[-1]
            layer_list2 << l
          else
            layer_list2 << (l + '|')
          end
        end

        if layer_list.include? " Steel"
          default_layer = " Steel"
        else
          default_layer = layers.first.name
        end
        # p layer_list2
        prompts = ['Layer Assign']
        default = [default_layer]
        list = [layer_list2]
        title = "Layer Helper"

        choice = UI.inputbox(prompts, default, list, title)


        if choice
          parts_to_layer = []

          sel.each do |part|
            if part.typename != 'Group' && part.typename != 'ComponentInstance'
              sel.remove part
              next
            else
              part.definition.entities.each do |ent|
                if ent.typename != 'Group' && ent.typename != 'ComponentInstance'
                  next
                else
                  parts_to_layer.push ent
                end
              end
            end
          end

          sel.clear

          # parts_to_layer.each {|p| sel.add p }
          parts_to_layer.each {|p| p.layer = choice[0]}
        end
        Sketchup.send_action "selectSelectionTool:"

      end
    end



  end
end