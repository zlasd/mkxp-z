# ruby_classic_wrap.rb
# Author: WaywardHeart (2023)

# Creative Commons CC0: To the extent possible under law, WaywardHeart has
# dedicated all copyright and related and neighboring rights to this script
# to the public domain worldwide.
# https://creativecommons.org/publicdomain/zero/1.0/

# This preload script provides functions that existed in RPG Maker's versions of Ruby,
# but were renamed or changed in the current Ruby version used in mkxp-z, so that games
# (or other preload scripts) that expect the older Ruby behavior can function.

class Hash
	alias_method :index, :key unless method_defined?(:index)
end

# RGSS Ruby accepted a method/begin "else" without rescue as an unconditional
# continuation (with a warning). Ruby 3 rejects it during compilation. Only
# remove an else explicitly identified by the compiler, retaining line numbers
# and leaving normal if/case/rescue branches, strings and comments untouched.
module MaouClassicSyntax
	def self.normalize(source)
		return source unless defined?(RubyVM::InstructionSequence)
		return source unless source.match?(/^[\t ]*else\b/)
		candidate = source
		verbose = $VERBOSE
		begin
			$VERBOSE = nil
			loop do
				begin
					RubyVM::InstructionSequence.compile(candidate, 'maou-classic-syntax')
					return candidate
				rescue SyntaxError => error
					match = error.message.match(/maou-classic-syntax:(\d+): else without rescue is useless/)
					return source unless match
					lines = candidate.lines
					index = match[1].to_i - 1
					line = lines[index]
					return source unless line && line.match?(/\A[\t ]*else\b/)
					lines[index] = line.sub(/\A([\t ]*)else\b/, '\1    ')
					candidate = lines.join
				end
			end
		ensure
			$VERBOSE = verbose
		end
	end
end

if defined?($RGSS_SCRIPTS) && $RGSS_SCRIPTS.respond_to?(:each)
	$RGSS_SCRIPTS.each do |entry|
		next unless entry.is_a?(Array) && entry[3].is_a?(String)
		entry[3] = MaouClassicSyntax.normalize(entry[3])
	end
end

class Object
	TRUE = true unless const_defined?("TRUE")
	FALSE = false unless const_defined?("FALSE")
	NIL = nil unless const_defined?("NIL")
	
	alias_method :id, :object_id unless method_defined?(:id)
	alias_method :type, :class unless method_defined?(:type)
end

class NilClass
	def id
		4 # Starting with Ruby2, 64-bit builds of ruby make this 8
	end
end

class TrueClass
	def id
		2 # Starting with Ruby2, 64-bit builds of ruby make this 20
	end
end

if defined?(BasicObject) && BasicObject.instance_method(:initialize).arity == 0
	# In ruby 1.9.2, and only ruby 1.9.2, BasicObject.initialize accepted any number of arguments
	class BasicObject
		def initialize(*args)
		end
	end
end
