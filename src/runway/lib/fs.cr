# Note: the File class in Crystal is a low-level class that interacts directly with the file system, and it's not designed to be mocked or subclassed
# Due to this, I created a wrapper class to encapsulate the File class, so I can mock it in the tests

# nocov-start
class FS
  def self.exists?(path)
    File.exists?(path)
  end

  def self.delete(path)
    File.delete(path)
  end

  # all the commented out methods aren't used at this time, but I'm keeping them here for future reference

  # def self.touch(path)
  #   File.touch(path)
  # end

  # def self.dirname(path)
  #   File.dirname(path)
  # end

  # def self.read_lines(path)
  #   File.read_lines(path)
  # end

  # def self.join(*args)
  #   File.join(*args)
  # end

  # def self.open(path, mode, &block)
  #   File.open(path, mode, &block)
  # end
end
# nocov-end
