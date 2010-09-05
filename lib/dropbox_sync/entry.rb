class DropboxSync::Entry
  
  class << self
    
    include Enumerable
    
    attr_accessor :sync_folder
    
    def sync_foler=(folder)
      @sync_folder = folder
      @entries = nil
    end
    
    def settings_file
      File.join(sync_folder, 'sync-settings.yml')
    end
    
    def each(&block)
      entries.each(&block)
    end
    
    def add_entry(entry)
      entries << entry
      save_entries!
    end

    def remove_entry(entry)
      entries.delete(self[entry])
      save_entries!
    end

    def entries
      @entries ||= begin
        hash = YAML.load(File.read(settings_file)) || {}
        hash.map { |name, options| DropboxSync::Entry.from_hash(name, options) }
      end
    end
    
    def [](name_or_path)
      return name_or_path if name_or_path.kind_of?(DropboxSync::Entry)
      entries.detect { |entry| entry.name == name_or_path || File.expand_path(name_or_path) == entry.target_path }
    end

    def save_entries!
      hash = {}
      each { |entry| hash[entry.name] = entry.to_hash }
      File.open(settings_file, 'w') { |io| io.write(YAML.dump(hash)) }
    end
    
    def from_hash(name, options)
      self.new(name, options['path'])
    end

    def create(name, path)

      raise "#{path.inspect} not found!" unless File.exist?(path)
      raise "#{path.inspect} is already being synced!" if entries.any? { |e| e.target_path == File.expand_path(path) }
      raise "Entry #{name.inspect} already exists, choose another name!" if entries.any? { |e| e.name == name }

      entry = self.new(name, path)
      entry.create!
    end
  end
  
  attr_reader :name, :path
  
  def initialize(name, path)
    @name, @path = name, self.class.normalized_path(path)
  end
  
  def self.normalized_path(path)
    File.expand_path(path).sub(Regexp.new('^' + Regexp.quote(File.expand_path('~'))), '~')
  end

  def to_hash
    { 'path' => @path }
  end  
  
  def sync_path
    File.join(self.class.sync_folder, name)
  end
  
  def create!
    FileUtils.ln_s(target_path, sync_path)
    self.class.add_entry(self)
  end
  
  def applied?
    File.symlink?(sync_path) && File.readlink(sync_path) == target_path && File.exist?(target_path)
  end
  
  def applyable? 
    File.exist?(sync_path) && !File.symlink?(sync_path) && File.exist?(target_path)
  end
  
  def target_path
    File.expand_path(path)
  end
  
  def backup_path
    target_path + '.local_backup'
  end
  
  def target_exist?
    File.exist?(target_path)
  end
  
  def backup_target!
    FileUtils.mv(target_path, backup_path)
  end
  
  def apply!
    raise "Traget already exists" if target_exist?
    FileUtils.mv(sync_path, target_path)
    FileUtils.ln_s(target_path, sync_path)
  end
  
  def unapply!
    raise "Cannot unapply entries that have not been applied!" unless applied?
    FileUtils.rm(sync_path)
    FileUtils.cp_r(target_path, sync_path)
    self.class.remove_entry(self)
  end
  
  def destroy!
    FileUtils.rm(sync_path) if File.exist?(sync_path)
    self.class.remove_entry(self)
  end
  
  def status
    if applied?
      :applied
    elsif applyable?
      :applyable
    else
      :invalid
    end
  end
  
  def to_s
    "#{name} -> #{path} [#{status}]"
  end
end
