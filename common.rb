#!/usr/bin/env ruby

require 'fileutils'

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
end

module GameSave
  def run
    if ARGV == ['load']
      self.load
    elsif ARGV == ['save']
      self.save
    else
      STDERR.puts "Usage: #{$0} (load|save)"
      exit 1
    end
  end

  def mapping
    {self.active => self.stored}
  end

  def load
    mapping.each_pair { |game, git| self.copySave(git, game) }
  end

  def save
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
end
