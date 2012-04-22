require './multigram'
require './util'

model = MultigramModel.new

sampleDir = "samples"
Dir.chdir(sampleDir)
files = Dir.glob("*.txt")
files.each do |file|
    model.addFile(file)
end
Dir.chdir("..")
puts ""
puts "Random sentance:"
puts model.buildRandSentance
puts ""
