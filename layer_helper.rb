module EA_Extensions623
  module EASteelTools

    class LayerHelper
      include Control
      def initialize
        model = Sketchup.active_model
        sel = model.selection
        layers = model.layers.sort

        if sel.count > 5
          UI.messagebox('CAUTION: Running this cleanup on a large number of parts risks re-layering parts you may not intend to set to a new layer. Use on a manageable amount of parts at a time.')
        end

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

        if layer_list.include? STEEL_LAYER
          default_layer = STEEL_LAYER
        else
          default_layer = layers.first.name
        end
        # p layer_list2
        prompts = ['Layer Assign']
        default = [default_layer]
        list = [layer_list2]
        title = "Layer Helper"

        choice = UI.inputbox(prompts, default, list, title)

        model.start_operation("Layer Helper", true)
        if choice
          parts_to_layer = 0
          locked_items = 0


          sel.each_with_index do |part, i|
            if part.locked?
              a = part.make_unique
              locked_items += 1
              next
            elsif part.typename != 'Group' && part.typename != 'ComponentInstance'
              next
            else
              part.make_unique if part.typename == 'Group'
              part.entities.each do |ent|
                if ent.typename != 'Group' && ent.typename != 'ComponentInstance'
                  next
                elsif !ent.locked?
                  set_layer(ent, choice[0])
                  parts_to_layer += 1
                elsif ent.locked?
                  locked_items += 1
                  next
                end
              end
            end
          end

          sel.clear
          UI.messagebox "#{parts_to_layer} parts were added to layer #{choice[0]}\n#{locked_items} parts were locked and ignored"
        end

        model.commit_operation
        Sketchup.send_action "selectSelectionTool:"

      end
    end



  end
end