 ['bigdecimal','bigdecimal/math',
  'bigdecimal/util','yaml','pathname'].each { |f| require f }

module File_cptf
  def self.get_pathname(filename)
    pn=Pathname.new(filename)
    pn=pn.expand_path
    pn=pn.dirname.to_s
  end #returns the directory pathname of the file
end