#!/usr/bin/env ruby

################################################################################
require('json')

################################################################################
class Build

  ##############################################################################
  def initialize(colors_file, dir)
    @colors = JSON.parse(File.read(colors_file))
    @dir = dir
  end

  ##############################################################################
  def run
    gen_css
  end

  ##############################################################################
  private

  ##############################################################################
  def gen_css
    File.open(File.join(@dir, "colors.css"), "w") do |file|
      @colors.each do |name, hex|
        file.puts("@define-color #{name} #{hex};")
      end
    end
  end
end

Build.new(*ARGV).run
