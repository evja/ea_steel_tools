# This is the tool that takes a steel part and breaks it out

module EA_Extensions623
  module EASteelTools
		require 'sketchup.rb'
		SKETCHUP_CONSOLE.show
		BEAM_NAME = 'Beam'

		module BreakoutMod
			def self.qualify_selection(sel)
  			p sel[0].class
  			p sel[0].name
  			if sel[0].class == Sketchup::Group && sel[0].name == BEAM_NAME
  				p 'passed Check 1'
  				return true
  			else
  				p 'not validated'
  				return false
  			end
  		end
		end

  	class Breakout

  		def initialize
	  		@model = Sketchup.active_model
	  		@entities = @model.entities
	  		@selection = @model.selection
	  		@plates = []
	  		@steel_members = {}
	  		@labels = []
	  		@beam_regex = "/(([W,w])\d{1,2}([X,x])\d{1,3})\w+"
	  		@multiple = ''
	  		@path = @model.path
	  		p @path
	  		@path = @path.split('/')[0...-1].join('/')
	  		p @path
	  		activise

	  		p 'all variables initialized'
			end

  		def sanitize_selection(sel)
  			if sel.count > 1
  				sel.each_with_index {|member, i| @steel_members[i] = validate_selection(member)}
  			else
  				@steel_members[0] = validate_selection(sel)
  			end
  		end

  		def validate_selection(sel)
  			if sel[0].class == Sketchup::Group && sel[0].name == BEAM_NAME
  				return sel
  			end
  		end

  		def activise
  			sanitize_selection(@selection)
  			@steel_members.each do |k, v|
  				scrape(k)
  			end

  		end

  		def scrape(part)
  			data = {}
  			part.entities.each do |e|
  				p e.name
  				p e.class
  			end
  		end

  		def find_breakout_location

  		end


  	end
  end
end