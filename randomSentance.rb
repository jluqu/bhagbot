require './multigram'
require './util'

model = MultigramModel.new

worpusDir = "samples"
Dir.chdir(worpusDir)
files = Dir.glob("*.txt")
files.each do |file|
    model.addFile(file)
end
Dir.chdir("..")
puts ""
puts "Random sentance:"
puts model.buildRandSentance
puts ""

