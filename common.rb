#!/usr/bin/env ruby

require 'fileutils'

STEAM_ID_NUMBER = "39061178"

# from http://stackoverflow.com/a/171011
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

module Windows
  def Windows.documents
    require 'win32/registry'
    key = 'Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders'
    Win32::Registry::HKEY_CURRENT_USER.open(key) { |reg| reg['Personal'] }
  end

  def Windows.programFilesX86
    ENV['ProgramFiles(x86)']
  end

  def Windows.steamapps
    Windows.programFilesX86 + '/Steam/steamapps'
  end
end

module Mac
  def Mac.home
    ENV['HOME']
  end

  def Mac.appSupport
    Mac.home + '/Library/Application Support'
  end

  def Mac.steamUserData
    Mac.appSupport + "/Steam/userdata/#{STEAM_ID_NUMBER}"
  end
end

module GameSave
  def run
    if ARGV == ['load']
      self.load
    elsif ARGV == ['save']
      self.save
    elsif ARGV == ['load', '-f']
      self.load(true)
    elsif ARGV == ['save', '-f']
      self.save(true)
    else
      STDERR.puts "Usage: #{$0} (load|save) [-f]"
      exit 1
    end
  end

  def mapping
    {self.active => self.stored}
  end

  def load(force = false)
    if newer == :game and not force
      STDERR.puts "Error: game data is newer than git data."
      STDERR.puts "To force a load: #{$0} load -f"
    end
    mapping.each_pair { |game, git| self.copySave(git, game) }
  end

  def save(force = false)
    if newer == :git and not force
      STDERR.puts "Error: git data is newer than game data."
      STDERR.puts "To force a save: #{$0} save -f"
    end
    mapping.each_pair { |game, git| self.copySave(game, git) }
  end

  def copySave(from, to)
    if File.file? from
      FileUtils.cp from, to
    elsif File.directory? from
      FileUtils.rm_rf to
      FileUtils.mkdir to
      FileUtils.cp_r "#{from}/.", to
    else
      raise "Couldn't find file/dir #{from}"
    end
  end

  def newer
    tally = []
    mapping.each_pair do |game, git|
      if File.mtime(game) < File.mtime(git)
        tally << :git
      elsif File.mtime(game) > File.mtime(git)
        tally << :game
      end
    end
    if tally.uniq.length == 1
      tally[0]
    else
      nil
    end
  end
end
