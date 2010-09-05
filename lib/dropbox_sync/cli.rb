require 'yaml'
require 'thor'

class DropboxSync::CLI < Thor

  class_option "dropbox-dir", :type => :string, :banner => "The location of the Dropbox folder.", :default => '~/Dropbox'
  
  def initialize(*)
    super
    setup_infrastructure!
  end
  
  
  desc 'list', "Lists the paths that are currently being synced by Dropbox"
  def list
    DropboxSync::Entry.each do |entry|
      shell.say entry.to_s
    end
  end
  
  desc 'sync PATH [NAME]', "Creates a symbolic link in the dropbox folder to a file or directory."
  def sync(path, name = nil)
    DropboxSync::Entry.create(name || File.basename(path), path)
  end
  
  desc 'unsync NAME', "Removes symlink, but keep all files around, locally and on Dropbox."
  def unsync(name)
    entry = DropboxSync::Entry[name]
    if entry.applied?
      entry.unapply!
      shell.say "#{entry.name} is now no longer syncing with Dropbox."
    else
      raise "Can only unsync entries that are set up correctly!"
    end
  end
  
  desc 'destroy NAME', "Removes symlink if it exists, and removes files from Dropbox. Keeps local files around."
  def destroy(name) 
    entry = DropboxSync::Entry[name]
    entry.destroy!
    shell.say "#{entry.name} is now deleted from Dropbox."
  end
  
  desc 'setup', "Sets up the synced files and folders on this machine."
  def setup
    DropboxSync::Entry.each do |entry|
      shell.say "#{entry.name}"

      if entry.applied?
        shell.say " - Syncing is already set up."
        
      elsif entry.applyable?
        
        if entry.target_exist?
          entry.backup_target!
          shell.say " - Backed up current version of #{entry.path} as #{entry.backup_path}."
        end

        entry.apply!
        shell.say " - Dropbox version moved to #{entry.target_path}."
        shell.say " - Created link #{entry.sync_path} to enable dropbox syncing."

      else
        shell.say " - Something is off with this entry!"
      end
    end
  end
  
  def help(*)
    shell.say "Dropbox Sync command line tool - by Willem van Bergen."
    shell.say
    shell.say "This tool will create symlinks for files and directories you provide in your Dropbox folder. "
    shell.say "This will synchronize it with Dropbox. You can then easily recreate the setup on a different "
    shell.say "machine by running 'dropbox-sync setup'."
    shell.say
    shell.say "Wait until all files are synced, and then quit Dropbox before using this tool."
    shell.say
    super
  end
  
  protected
  
  def setup_infrastructure!
    if File.directory?(File.expand_path(options['dropbox-dir']))
      DropboxSync::Entry.sync_folder = File.join(File.expand_path(options['dropbox-dir']), 'Sync')
    else
      raise "The dropbox folder was not found on #{options['dropbox-dir']}."
    end
  end
end
